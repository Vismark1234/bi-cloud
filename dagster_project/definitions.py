from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

from dagster import (
    AssetKey,
    AssetSelection,
    AssetSpec,
    AssetsDefinition,
    Definitions,
    DefaultScheduleStatus,
    MaterializeResult,
    ScheduleDefinition,
    define_asset_job,
    multi_asset,
)

REPO_ROOT = Path(__file__).resolve().parents[1]
DBT_PROJECT_DIR = REPO_ROOT / "dbt_project"
DBT_TARGET = os.getenv("DBT_TARGET") or "dev"
MANIFEST_PATH = DBT_PROJECT_DIR / "target" / "manifest.json"
AIRBYTE_API_BASE_URL = (os.getenv("AIRBYTE_API_BASE_URL") or "https://api.airbyte.com/v1").rstrip("/")
AIRBYTE_CLIENT_ID = os.getenv("AIRBYTE_CLIENT_ID")
AIRBYTE_CLIENT_SECRET = os.getenv("AIRBYTE_CLIENT_SECRET")
AIRBYTE_CONNECTION_IDS = [
    x.strip()
    for x in (os.getenv("AIRBYTE_CONNECTION_IDS") or "").split(",")
    if x.strip()
]
AIRBYTE_POLL_INTERVAL_SECONDS = int(os.getenv("AIRBYTE_POLL_INTERVAL_SECONDS") or "10")
AIRBYTE_TIMEOUT_SECONDS = int(os.getenv("AIRBYTE_TIMEOUT_SECONDS") or "3600")


def _run_dbt_command(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["dbt", *args],
        cwd=str(DBT_PROJECT_DIR),
        text=True,
        capture_output=True,
        check=False,
    )


def _ensure_manifest() -> None:
    if MANIFEST_PATH.exists():
        return

    if shutil.which("dbt") is None:
        raise FileNotFoundError(
            "No se encontro el ejecutable 'dbt'. Instala dependencias con "
            "'python -m pip install -r requirements.txt'."
        )

    result = _run_dbt_command(["parse", "--profiles-dir", ".", "--target", DBT_TARGET])
    if result.returncode != 0 or not MANIFEST_PATH.exists():
        stderr = (result.stderr or "").strip()
        stdout = (result.stdout or "").strip()
        detail = stderr or stdout or "Sin salida de error."
        raise RuntimeError(
            "No se pudo generar dbt_project/target/manifest.json con 'dbt parse'. "
            "Revisa tu archivo .env y dbt_project/profiles.yml. "
            f"Detalle: {detail}"
        )


def _sanitize(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9_]", "_", value)
    return value.strip("_") or "obj"


def _to_asset_key(node: dict) -> AssetKey:
    database = _sanitize(node.get("database") or "db")
    schema = _sanitize(node.get("schema") or "schema")
    name = _sanitize(node.get("alias") or node.get("name") or "obj")
    return AssetKey([database, schema, name])


def _http_json(method: str, url: str, payload: dict | None = None, token: str | None = None) -> dict:
    data = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(url=url, method=method, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Airbyte API HTTP {exc.code} en {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"No se pudo conectar a Airbyte API en {url}: {exc}") from exc


def _airbyte_access_token() -> str:
    if not AIRBYTE_CLIENT_ID or not AIRBYTE_CLIENT_SECRET:
        raise RuntimeError(
            "Faltan AIRBYTE_CLIENT_ID/AIRBYTE_CLIENT_SECRET para controlar Airbyte Cloud."
        )

    response = _http_json(
        "POST",
        f"{AIRBYTE_API_BASE_URL}/applications/token",
        {"client_id": AIRBYTE_CLIENT_ID, "client_secret": AIRBYTE_CLIENT_SECRET},
    )
    token = response.get("access_token") or response.get("token") or response.get("jwt")
    if not token:
        raise RuntimeError("Airbyte API no devolvio access_token al solicitar token.")
    return str(token)


def _extract_job_id(job_response: dict) -> int:
    for key in ("jobId", "id"):
        if key in job_response and job_response[key] is not None:
            return int(job_response[key])
    job_obj = job_response.get("job")
    if isinstance(job_obj, dict):
        for key in ("jobId", "id"):
            if key in job_obj and job_obj[key] is not None:
                return int(job_obj[key])
    raise RuntimeError(f"No se pudo extraer jobId de respuesta Airbyte: {job_response}")


def _extract_job_status(job_payload: dict) -> str:
    status = job_payload.get("status")
    if status:
        return str(status).lower()
    job_obj = job_payload.get("job")
    if isinstance(job_obj, dict) and job_obj.get("status"):
        return str(job_obj["status"]).lower()
    raise RuntimeError(f"No se pudo extraer status de job Airbyte: {job_payload}")


def _trigger_airbyte_sync(connection_id: str, token: str) -> int:
    response = _http_json(
        "POST",
        f"{AIRBYTE_API_BASE_URL}/jobs",
        {"connectionId": connection_id, "jobType": "sync"},
        token=token,
    )
    return _extract_job_id(response)


def _wait_airbyte_job(job_id: int, token: str) -> str:
    started_at = time.time()
    final_success = {"succeeded", "success", "completed"}
    final_error = {"failed", "error", "cancelled", "canceled", "incomplete"}

    while True:
        payload = _http_json("GET", f"{AIRBYTE_API_BASE_URL}/jobs/{job_id}", token=token)
        status = _extract_job_status(payload)
        if status in final_success:
            return status
        if status in final_error:
            raise RuntimeError(f"Airbyte job {job_id} finalizo con estado no exitoso: {status}")

        elapsed = time.time() - started_at
        if elapsed > AIRBYTE_TIMEOUT_SECONDS:
            raise TimeoutError(
                f"Timeout esperando job {job_id} de Airbyte ({AIRBYTE_TIMEOUT_SECONDS}s)."
            )
        time.sleep(AIRBYTE_POLL_INTERVAL_SECONDS)


def _load_specs(manifest_path: Path) -> tuple[list[AssetSpec], list[AssetSpec]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    nodes = manifest.get("nodes", {})
    sources = manifest.get("sources", {})

    uid_to_key: dict[str, AssetKey] = {}

    for uid, node in sources.items():
        uid_to_key[uid] = _to_asset_key(node)

    for uid, node in nodes.items():
        if node.get("resource_type") in {"model", "seed", "snapshot"}:
            uid_to_key[uid] = _to_asset_key(node)

    source_specs: list[AssetSpec] = []
    for uid, node in sources.items():
        source_specs.append(
            AssetSpec(
                key=uid_to_key[uid],
                description=node.get("description"),
                group_name="raw_sources",
                metadata={"dbt_unique_id": uid, "resource_type": "source"},
                kinds={"dbt", "source"},
            )
        )

    model_specs: list[AssetSpec] = []
    for uid, node in nodes.items():
        resource_type = node.get("resource_type")
        if resource_type not in {"model", "seed", "snapshot"}:
            continue

        dep_keys = []
        for dep_uid in node.get("depends_on", {}).get("nodes", []):
            dep_key = uid_to_key.get(dep_uid)
            if dep_key is not None:
                dep_keys.append(dep_key)

        model_specs.append(
            AssetSpec(
                key=uid_to_key[uid],
                deps=dep_keys,
                description=node.get("description"),
                group_name=str(resource_type),
                metadata={"dbt_unique_id": uid, "resource_type": resource_type},
                kinds={"dbt"},
            )
        )

    return source_specs, model_specs


def _toposort_specs(specs: list[AssetSpec]) -> list[AssetSpec]:
    key_to_spec = {spec.key: spec for spec in specs}
    pending_deps: dict[AssetKey, set[AssetKey]] = {}
    dependents: dict[AssetKey, set[AssetKey]] = {spec.key: set() for spec in specs}

    for spec in specs:
        deps = set()
        for dep in spec.deps:
            dep_key = getattr(dep, "asset_key", dep)
            if dep_key in key_to_spec:
                deps.add(dep_key)
                dependents[dep_key].add(spec.key)
        pending_deps[spec.key] = deps

    ready = sorted((key for key, deps in pending_deps.items() if not deps), key=str)
    ordered: list[AssetSpec] = []

    while ready:
        key = ready.pop(0)
        ordered.append(key_to_spec[key])
        for child_key in sorted(dependents[key], key=str):
            child_pending = pending_deps[child_key]
            child_pending.discard(key)
            if not child_pending and key_to_spec[child_key] not in ordered:
                if child_key not in ready:
                    ready.append(child_key)
                    ready.sort(key=str)

    if len(ordered) != len(specs):
        return specs

    return ordered


_ensure_manifest()
SOURCE_SPECS, MODEL_SPECS = _load_specs(MANIFEST_PATH)
AIRBYTE_SPECS: list[AssetSpec] = []
AIRBYTE_KEYS: list[AssetKey] = []

if AIRBYTE_CONNECTION_IDS:
    for connection_id in AIRBYTE_CONNECTION_IDS:
        key = AssetKey(["airbyte", "connection", _sanitize(connection_id)])
        AIRBYTE_KEYS.append(key)
        AIRBYTE_SPECS.append(
            AssetSpec(
                key=key,
                group_name="airbyte",
                metadata={"airbyte_connection_id": connection_id},
                description=f"Sync Airbyte Cloud para connection_id={connection_id}",
                kinds={"airbyte"},
            )
        )


if AIRBYTE_SPECS:

    @multi_asset(
        specs=AIRBYTE_SPECS,
        can_subset=False,
        name="airbyte_sync_assets",
        description="Dispara sync en Airbyte Cloud y espera finalizacion por connection.",
    )
    def airbyte_sync_assets(context):
        token = _airbyte_access_token()
        for spec, connection_id in zip(AIRBYTE_SPECS, AIRBYTE_CONNECTION_IDS):
            context.log.info(f"Airbyte sync iniciado para connection_id={connection_id}")
            job_id = _trigger_airbyte_sync(connection_id, token)
            status = _wait_airbyte_job(job_id, token)
            context.log.info(
                f"Airbyte sync finalizado connection_id={connection_id}, job_id={job_id}, status={status}"
            )
            yield MaterializeResult(
                asset_key=spec.key,
                metadata={
                    "airbyte_connection_id": connection_id,
                    "airbyte_job_id": job_id,
                    "airbyte_status": status,
                },
            )


def _spec_with_extra_deps(spec: AssetSpec, extra_keys: list[AssetKey]) -> AssetSpec:
    base_dep_keys = []
    for dep in spec.deps:
        dep_key = getattr(dep, "asset_key", dep)
        base_dep_keys.append(dep_key)
    return spec.replace_attributes(deps=[*base_dep_keys, *extra_keys])


SOURCE_ASSET_SPECS = SOURCE_SPECS
if AIRBYTE_KEYS:
    # Para visualizar el flujo como: Airbyte -> raw_sources -> modelos dbt.
    SOURCE_ASSET_SPECS = [_spec_with_extra_deps(spec, AIRBYTE_KEYS) for spec in SOURCE_SPECS]

DBT_MODEL_SPECS = _toposort_specs(MODEL_SPECS)


@multi_asset(
    specs=DBT_MODEL_SPECS,
    can_subset=False,
    name="dbt_build_assets",
    description="Ejecuta dbt build del proyecto y publica materializaciones para el grafo.",
)
def dbt_build_assets(context):
    cmd = ["dbt", "build", "--profiles-dir", ".", "--target", DBT_TARGET]
    context.log.info(f"Ejecutando: {' '.join(cmd)}")

    result = _run_dbt_command(["build", "--profiles-dir", ".", "--target", DBT_TARGET])

    if result.stdout:
        context.log.info(result.stdout)
    if result.returncode != 0:
        if result.stderr:
            context.log.error(result.stderr)
        raise RuntimeError(f"dbt build fallo con codigo {result.returncode}")

    for spec in DBT_MODEL_SPECS:
        yield MaterializeResult(
            asset_key=spec.key,
            metadata={"dbt_target": DBT_TARGET, "status": "materialized_via_dbt_build"},
        )


assets = [dbt_build_assets]
if AIRBYTE_SPECS:
    assets.insert(0, airbyte_sync_assets)
if SOURCE_ASSET_SPECS:
    assets.insert(0, AssetsDefinition(specs=SOURCE_ASSET_SPECS))

orquestacion_selection = AssetSelection.groups("model", "snapshot")
if AIRBYTE_SPECS:
    orquestacion_selection = orquestacion_selection | AssetSelection.groups("airbyte")

orquestacion_diaria_0700_job = define_asset_job(
    name="orquestacion_diaria_0700_job",
    selection=orquestacion_selection,
)

orquestacion_diaria_0700_schedule = ScheduleDefinition(
    name="orquestacion_diaria_0700_schedule",
    job=orquestacion_diaria_0700_job,
    cron_schedule="0 7 * * *",
    execution_timezone="America/La_Paz",
    default_status=DefaultScheduleStatus.STOPPED,
)

defs = Definitions(
    assets=assets,
    jobs=[orquestacion_diaria_0700_job],
    schedules=[orquestacion_diaria_0700_schedule],
)
