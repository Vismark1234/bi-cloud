from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import pandas as pd
import snowflake.connector


ROOT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_DIR = ROOT_DIR / "eda_output_ejecutivo"


def load_env_file(env_path: Path) -> None:
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key and key not in os.environ:
            os.environ[key.strip()] = value.strip()


def get_env(name: str, default: str | None = None) -> str:
    value = os.getenv(name, default)
    return value or ""


def build_connection(args: argparse.Namespace):
    return snowflake.connector.connect(
        account=args.account,
        user=args.user,
        password=args.password,
        role=args.role,
        warehouse=args.warehouse,
        database=args.database,
        schema=args.schema,
        client_session_keep_alive=False,
        login_timeout=30,
        network_timeout=300,
    )


def fetch_dataframe(conn, sql: str) -> pd.DataFrame:
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        return pd.DataFrame(rows, columns=columns)
    finally:
        cursor.close()


def currency(value: float) -> str:
    return f"BOB {value:,.0f}"


def number(value: float) -> str:
    return f"{value:,.0f}"


def percent(value: float) -> str:
    return f"{value:,.1f}%"


def style_axes(ax: plt.Axes, title: str, xlabel: str = "", ylabel: str = "") -> None:
    ax.set_title(title, fontsize=13, pad=14)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(axis="y", linestyle="--", alpha=0.25)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def save_plot(fig: plt.Figure, output_path: Path) -> None:
    fig.tight_layout()
    fig.savefig(output_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def empty_plot(title: str, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(10, 4))
    ax.text(0.5, 0.5, "Sin datos disponibles", ha="center", va="center", fontsize=14)
    ax.set_axis_off()
    fig.suptitle(title, fontsize=13)
    save_plot(fig, output_path)


def plot_monthly_finance(df: pd.DataFrame, output_path: Path) -> None:
    if df.empty:
        empty_plot("Resultado mensual estimado", output_path)
        return
    df = df.copy()
    df["MES"] = pd.to_datetime(df["MES"]).dt.strftime("%Y-%m")
    x = range(len(df))
    colors = ["#15803d" if v >= 0 else "#b91c1c" for v in df["RESULTADO_OPERATIVO_ESTIMADO_BOB"]]
    fig, ax = plt.subplots(figsize=(12, 5.4))
    ax.bar(x, df["RESULTADO_OPERATIVO_ESTIMADO_BOB"], color=colors, alpha=0.35, label="Resultado operativo est.")
    ax.plot(x, df["INGRESO_FACTURADO_BOB"], marker="o", color="#1d4ed8", linewidth=2.3, label="Facturado")
    ax.plot(x, df["COBRANZA_BOB"], marker="o", color="#0f766e", linewidth=2.1, label="Cobranza")
    ax.plot(x, df["FLUJO_NETO_ESTIMADO_BOB"], marker="s", color="#f59e0b", linewidth=1.8, label="Flujo neto est.")
    ax.axhline(0, color="#475569", linewidth=1)
    ax.set_xticks(list(x))
    ax.set_xticklabels(df["MES"], rotation=25)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    style_axes(ax, "Resultado mensual estimado", "Mes", "BOB")
    ax.legend()
    save_plot(fig, output_path)


def plot_bar(df: pd.DataFrame, category: str, value: str, title: str, output_path: Path, horizontal: bool = False) -> None:
    if df.empty:
        empty_plot(title, output_path)
        return
    fig, ax = plt.subplots(figsize=(11, 5.5))
    if horizontal:
        ordered = df.sort_values(value, ascending=True)
        colors = ["#15803d" if v >= 0 else "#b91c1c" for v in ordered[value]]
        ax.barh(ordered[category], ordered[value], color=colors, alpha=0.85)
        ax.xaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    else:
        ax.bar(df[category], df[value], color="#2563eb", alpha=0.85)
        ax.tick_params(axis="x", rotation=25)
        ax.yaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    style_axes(ax, title, category, "BOB")
    save_plot(fig, output_path)


def plot_client_mix(df: pd.DataFrame, output_path: Path) -> None:
    if df.empty:
        empty_plot("Top clientes", output_path)
        return
    ordered = df.head(10).sort_values("INGRESO_FACTURADO_BOB", ascending=True)
    fig, ax = plt.subplots(figsize=(12, 6.5))
    ax.barh(ordered["CLIENTE"], ordered["INGRESO_FACTURADO_BOB"], color="#1d4ed8", alpha=0.75, label="Facturado")
    ax.barh(ordered["CLIENTE"], ordered["COBRANZA_BOB"], color="#0f766e", alpha=0.85, label="Cobrado")
    ax.xaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    style_axes(ax, "Top clientes por facturacion y cobranza", "Monto BOB", "Cliente")
    ax.legend()
    save_plot(fig, output_path)


def plot_branch_mix(df: pd.DataFrame, output_path: Path) -> None:
    if df.empty:
        empty_plot("Desempeno por sucursal", output_path)
        return
    ordered = df.head(10).copy()
    x = range(len(ordered))
    fig, ax1 = plt.subplots(figsize=(12, 5.4))
    ax2 = ax1.twinx()
    ax1.bar(x, ordered["INGRESO_FACTURADO_BOB"], color="#7c3aed", alpha=0.8, label="Ingreso")
    ax2.plot(x, ordered["SLA_CUMPLIDO_PCT"], color="#16a34a", marker="o", linewidth=2, label="SLA %")
    ax2.plot(x, ordered["DEVOLUCION_PCT"], color="#dc2626", marker="s", linewidth=2, label="Devolucion %")
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(ordered["SUCURSAL"], rotation=25)
    ax1.yaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    ax2.yaxis.set_major_formatter(FuncFormatter(lambda val, _: percent(val)))
    ax1.set_ylabel("Ingreso BOB")
    ax2.set_ylabel("Porcentaje")
    style_axes(ax1, "Sucursal origen: ingreso, SLA y devolucion", "Sucursal")
    handles = [ax1.patches[0], *ax2.get_lines()] if ax1.patches else ax2.get_lines()
    ax1.legend(handles, ["Ingreso", "SLA %", "Devolucion %"], loc="upper left")
    save_plot(fig, output_path)


def plot_rrhh(df: pd.DataFrame, output_path: Path) -> None:
    if df.empty:
        empty_plot("Costo laboral por area", output_path)
        return
    fig, ax1 = plt.subplots(figsize=(12, 5.4))
    ax2 = ax1.twinx()
    ax1.bar(df["AREA"], df["COSTO_LABORAL_BOB"], color="#334155", alpha=0.85, label="Costo laboral")
    ax2.plot(df["AREA"], df["AUSENTISMO_PCT"], color="#dc2626", marker="o", linewidth=2, label="Ausentismo %")
    ax1.tick_params(axis="x", rotation=25)
    ax1.yaxis.set_major_formatter(FuncFormatter(lambda val, _: currency(val)))
    ax2.yaxis.set_major_formatter(FuncFormatter(lambda val, _: percent(val)))
    ax1.set_ylabel("Costo laboral BOB")
    ax2.set_ylabel("Ausentismo %")
    style_axes(ax1, "Costo laboral y ausentismo por area", "Area")
    handles = [ax1.patches[0], ax2.get_lines()[0]] if ax1.patches else ax2.get_lines()
    ax1.legend(handles, ["Costo laboral", "Ausentismo %"], loc="upper left")
    save_plot(fig, output_path)


def plot_tracking(df: pd.DataFrame, output_path: Path) -> None:
    if df.empty:
        empty_plot("Tracking y riesgo", output_path)
        return
    fig, ax = plt.subplots(figsize=(10, 5.2))
    x = range(len(df))
    ax.bar(x, df["EVENTOS"], color="#8b5cf6", alpha=0.8, label="Eventos")
    ax.bar(x, df["ALERTAS_CRITICAS"], color="#ef4444", alpha=0.9, label="Alertas criticas")
    ax.set_xticks(list(x))
    ax.set_xticklabels(df["CATEGORIA_TRACKING"], rotation=20)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda val, _: number(val)))
    style_axes(ax, "Volumen y criticidad de tracking", "Categoria", "Eventos")
    ax.legend()
    save_plot(fig, output_path)


def preview(df: pd.DataFrame, rows: int = 12) -> str:
    if df.empty:
        return "<p>Sin datos.</p>"
    return df.head(rows).to_html(index=False, classes="preview-table", border=0)


def build_html_report(output_path: Path, generated_at: str, args: argparse.Namespace, kpis: list[dict[str, str]], sections: list[dict[str, str]], errors: list[str]) -> None:
    cards_html = "\n".join(
        f"<div class='card'><div class='card-label'>{item['label']}</div><div class='card-value'>{item['value']}</div></div>"
        for item in kpis
    )
    sections_html = "\n".join(
        f"""
        <section class="section">
          <h2>{section['title']}</h2>
          <p>{section['description']}</p>
          <img src="{section['image_rel']}" alt="{section['title']}">
          <div class="table-wrap">{section['table_html']}</div>
        </section>
        """
        for section in sections
    )
    errors_html = ""
    if errors:
        errors_html = "<section class='section error-box'><h2>Consultas con error</h2><ul>%s</ul></section>" % "".join(
            f"<li>{error}</li>" for error in errors
        )
    html = f"""<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>EDA Ejecutivo DWH</title>
  <style>
    body {{ font-family: Segoe UI, Arial, sans-serif; margin: 0; background: #f8fafc; color: #0f172a; }}
    .container {{ max-width: 1320px; margin: 0 auto; padding: 24px; }}
    .hero {{ background: linear-gradient(135deg, #0f172a, #1e3a8a 55%, #0f766e); color: white; padding: 28px; border-radius: 18px; margin-bottom: 24px; }}
    .meta {{ margin-top: 12px; color: #bfdbfe; }}
    .cards {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 20px 0 24px; }}
    .card, .section {{ background: white; border-radius: 16px; padding: 18px; box-shadow: 0 10px 26px rgba(15, 23, 42, 0.08); }}
    .card-label {{ font-size: 12px; text-transform: uppercase; color: #64748b; margin-bottom: 8px; }}
    .card-value {{ font-size: 24px; font-weight: 700; }}
    .section {{ margin-bottom: 20px; }}
    .section img {{ width: 100%; border-radius: 12px; margin: 12px 0 16px; }}
    .preview-table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
    .preview-table th, .preview-table td {{ border-bottom: 1px solid #e2e8f0; padding: 8px 10px; text-align: left; }}
    .preview-table th {{ background: #eff6ff; }}
    .note {{ background: #ecfeff; border: 1px solid #a5f3fc; color: #164e63; border-radius: 14px; padding: 14px 16px; margin-bottom: 20px; line-height: 1.5; }}
    .error-box {{ border-left: 6px solid #dc2626; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="hero">
      <h1>EDA Ejecutivo del DWH</h1>
      <p>Reporte orientado a lectura gerencial para {args.database}.{args.schema}.</p>
      <div class="meta">Generado: {generated_at}</div>
    </div>
    <div class="note">Resultado y flujo neto son estimados: facturacion/cobranza menos costo operativo de viajes y costo laboral RRHH. No incluyen gastos corporativos no modelados.</div>
    <div class="cards">{cards_html}</div>
    {errors_html}
    {sections_html}
  </div>
</body>
</html>"""
    output_path.write_text(html, encoding="utf-8")


def main() -> int:
    load_env_file(ROOT_DIR / ".env")
    parser = argparse.ArgumentParser(description="EDA ejecutivo del DWH en Snowflake.")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR))
    parser.add_argument("--account", default=get_env("DBT_SNOWFLAKE_ACCOUNT", "TU_ACCOUNT_SNOWFLAKE"))
    parser.add_argument("--user", default=get_env("DBT_SNOWFLAKE_USER", "TU_USUARIO_SNOWFLAKE"))
    parser.add_argument("--password", default=get_env("DBT_SNOWFLAKE_PASSWORD"))
    parser.add_argument("--role", default=get_env("DBT_SNOWFLAKE_ROLE", "TU_ROLE_SNOWFLAKE"))
    parser.add_argument("--database", default=get_env("DBT_SNOWFLAKE_DATABASE", "TU_DATABASE_SNOWFLAKE"))
    parser.add_argument("--warehouse", default=get_env("DBT_SNOWFLAKE_WAREHOUSE", "TU_WAREHOUSE_SNOWFLAKE"))
    parser.add_argument("--schema", default=get_env("DBT_SNOWFLAKE_SCHEMA", "DWH_DEV"))
    args = parser.parse_args()
    if not args.password or args.password == "CAMBIAR_POR_PASSWORD_REAL":
        raise RuntimeError("Configura DBT_SNOWFLAKE_PASSWORD en .env antes de ejecutar el script.")

    output_dir = Path(args.output_dir).resolve()
    data_dir = output_dir / "data"
    charts_dir = output_dir / "charts"
    output_dir.mkdir(parents=True, exist_ok=True)
    data_dir.mkdir(parents=True, exist_ok=True)
    charts_dir.mkdir(parents=True, exist_ok=True)

    queries = {
        "kpi_resumen": {
            "title": "KPIs ejecutivos",
            "description": "Resumen del estado financiero, operativo y comercial del DWH.",
            "sql": f"""
                with pagos_por_factura as (
                  select id_factura, sum(monto_bob) as cobrado_bob
                  from {args.database}.{args.schema}.fact_pago
                  group by 1
                ),
                cartera as (
                  select
                    count(*) as facturas,
                    coalesce(sum(f.total_bob), 0) as ingreso_facturado_bob,
                    coalesce(sum(coalesce(p.cobrado_bob, 0)), 0) as cobranza_bob,
                    coalesce(sum(greatest(f.total_bob - coalesce(p.cobrado_bob, 0), 0)), 0) as saldo_pendiente_bob,
                    coalesce(sum(case when current_date() > f.fecha_vencimiento then greatest(f.total_bob - coalesce(p.cobrado_bob, 0), 0) else 0 end), 0) as saldo_vencido_bob
                  from {args.database}.{args.schema}.dim_factura f
                  left join pagos_por_factura p on f.id_factura = p.id_factura
                ),
                operacion as (
                  select
                    count(*) as viajes,
                    coalesce(sum(costo_operativo_total_bob), 0) as costo_operativo_bob,
                    coalesce(avg(ocupacion_pct), 0) as ocupacion_promedio_pct
                  from {args.database}.{args.schema}.fact_viaje
                ),
                rrhh as (
                  select
                    coalesce(sum(liquido_pagable_bob), 0) as costo_rrhh_bob,
                    coalesce(avg(tasa_ausentismo_pct), 0) as ausentismo_promedio_pct
                  from {args.database}.{args.schema}.fact_rrhh_mensual
                ),
                envios as (
                  select
                    count(*) as envios,
                    coalesce(avg(cumple_sla_recojo_flag) * 100, 0) as sla_pct,
                    coalesce(avg(devuelto_flag) * 100, 0) as devolucion_pct
                  from {args.database}.{args.schema}.fact_envio
                )
                select
                  (select count(*) from {args.database}.{args.schema}.dim_cliente) as clientes,
                  envios.envios,
                  operacion.viajes,
                  cartera.ingreso_facturado_bob,
                  cartera.cobranza_bob,
                  cartera.saldo_pendiente_bob,
                  cartera.saldo_vencido_bob,
                  cartera.ingreso_facturado_bob - operacion.costo_operativo_bob - rrhh.costo_rrhh_bob as resultado_operativo_estimado_bob,
                  cartera.cobranza_bob - operacion.costo_operativo_bob - rrhh.costo_rrhh_bob as flujo_neto_estimado_bob,
                  envios.sla_pct,
                  envios.devolucion_pct,
                  operacion.ocupacion_promedio_pct,
                  rrhh.ausentismo_promedio_pct
                from cartera
                cross join operacion
                cross join rrhh
                cross join envios
            """,
        },
        "resultado_mensual": {
            "title": "Resultado mensual estimado",
            "description": "Cruce mensual entre facturacion, cobranza, costo operativo de viajes y costo laboral RRHH.",
            "sql": f"""
                with ingresos as (
                  select date_trunc('month', df.fecha)::date as mes, sum(ff.total_linea_bob) as ingreso_facturado_bob
                  from {args.database}.{args.schema}.fact_facturacion ff
                  join {args.database}.{args.schema}.dim_fecha df on ff.id_fecha_emision = df.id_fecha
                  group by 1
                ),
                cobranza as (
                  select date_trunc('month', df.fecha)::date as mes, sum(fp.monto_bob) as cobranza_bob
                  from {args.database}.{args.schema}.fact_pago fp
                  join {args.database}.{args.schema}.dim_fecha df on fp.id_fecha_pago = df.id_fecha
                  group by 1
                ),
                costo_viaje as (
                  select date_trunc('month', df.fecha)::date as mes, sum(fv.costo_operativo_total_bob) as costo_operativo_bob
                  from {args.database}.{args.schema}.fact_viaje fv
                  join {args.database}.{args.schema}.dim_fecha df on fv.id_fecha_salida = df.id_fecha
                  group by 1
                ),
                costo_rrhh as (
                  select date_trunc('month', df.fecha)::date as mes, sum(fr.liquido_pagable_bob) as costo_rrhh_bob
                  from {args.database}.{args.schema}.fact_rrhh_mensual fr
                  join {args.database}.{args.schema}.dim_fecha df on fr.id_fecha_periodo = df.id_fecha
                  group by 1
                ),
                meses as (
                  select mes from ingresos union select mes from cobranza union select mes from costo_viaje union select mes from costo_rrhh
                )
                select
                  m.mes,
                  coalesce(i.ingreso_facturado_bob, 0) as ingreso_facturado_bob,
                  coalesce(c.cobranza_bob, 0) as cobranza_bob,
                  coalesce(v.costo_operativo_bob, 0) as costo_operativo_bob,
                  coalesce(r.costo_rrhh_bob, 0) as costo_rrhh_bob,
                  coalesce(i.ingreso_facturado_bob, 0) - coalesce(v.costo_operativo_bob, 0) - coalesce(r.costo_rrhh_bob, 0) as resultado_operativo_estimado_bob,
                  coalesce(c.cobranza_bob, 0) - coalesce(v.costo_operativo_bob, 0) - coalesce(r.costo_rrhh_bob, 0) as flujo_neto_estimado_bob
                from meses m
                left join ingresos i on m.mes = i.mes
                left join cobranza c on m.mes = c.mes
                left join costo_viaje v on m.mes = v.mes
                left join costo_rrhh r on m.mes = r.mes
                order by 1
            """,
            "plotter": plot_monthly_finance,
        },
        "cartera_actual": {
            "title": "Cartera y vencimiento",
            "description": "Distribucion del saldo pendiente por tramos de vencimiento.",
            "sql": f"""
                with pagos_por_factura as (
                  select id_factura, sum(monto_bob) as cobrado_bob
                  from {args.database}.{args.schema}.fact_pago
                  group by 1
                )
                select
                  case
                    when greatest(f.total_bob - coalesce(p.cobrado_bob, 0), 0) = 0 then 'CANCELADA'
                    when current_date() <= f.fecha_vencimiento then 'POR_VENCER'
                    when datediff('day', f.fecha_vencimiento, current_date()) <= 30 then 'VENCIDA_0_30'
                    when datediff('day', f.fecha_vencimiento, current_date()) <= 60 then 'VENCIDA_31_60'
                    when datediff('day', f.fecha_vencimiento, current_date()) <= 90 then 'VENCIDA_61_90'
                    else 'VENCIDA_90_PLUS'
                  end as tramo_cartera,
                  count(*) as facturas,
                  sum(f.total_bob) as total_emitido_bob,
                  sum(coalesce(p.cobrado_bob, 0)) as cobrado_bob,
                  sum(greatest(f.total_bob - coalesce(p.cobrado_bob, 0), 0)) as saldo_pendiente_bob
                from {args.database}.{args.schema}.dim_factura f
                left join pagos_por_factura p on f.id_factura = p.id_factura
                group by 1
                order by saldo_pendiente_bob desc
            """,
            "plotter": lambda df, path: plot_bar(df, "TRAMO_CARTERA", "SALDO_PENDIENTE_BOB", "Cartera pendiente por tramo", path),
        },
        "clientes_valor": {
            "title": "Clientes de mayor valor",
            "description": "Clientes con mayor facturacion, cobranza y saldo pendiente.",
            "sql": f"""
                with facturacion as (
                  select id_cliente, sum(total_linea_bob) as ingreso_facturado_bob, count(distinct id_envio) as envios_facturados
                  from {args.database}.{args.schema}.fact_facturacion
                  group by 1
                ),
                pagos_cliente as (
                  select id_cliente, sum(monto_bob) as cobranza_bob, avg(dias_cobro_desde_emision) as dias_promedio_cobro
                  from {args.database}.{args.schema}.fact_pago
                  group by 1
                ),
                pagos_por_factura as (
                  select id_factura, sum(monto_bob) as cobrado_bob
                  from {args.database}.{args.schema}.fact_pago
                  group by 1
                ),
                cartera_cliente as (
                  select f.id_cliente, sum(greatest(f.total_bob - coalesce(p.cobrado_bob, 0), 0)) as saldo_pendiente_bob
                  from {args.database}.{args.schema}.dim_factura f
                  left join pagos_por_factura p on f.id_factura = p.id_factura
                  group by 1
                )
                select
                  c.nombre_razon_social as cliente,
                  c.segmento,
                  c.ciudad,
                  coalesce(f.ingreso_facturado_bob, 0) as ingreso_facturado_bob,
                  coalesce(p.cobranza_bob, 0) as cobranza_bob,
                  coalesce(cc.saldo_pendiente_bob, 0) as saldo_pendiente_bob,
                  coalesce(f.envios_facturados, 0) as envios_facturados,
                  coalesce(p.dias_promedio_cobro, 0) as dias_promedio_cobro
                from {args.database}.{args.schema}.dim_cliente c
                left join facturacion f on c.id_cliente = f.id_cliente
                left join pagos_cliente p on c.id_cliente = p.id_cliente
                left join cartera_cliente cc on c.id_cliente = cc.id_cliente
                where coalesce(f.ingreso_facturado_bob, 0) > 0
                order by ingreso_facturado_bob desc
                limit 15
            """,
            "plotter": plot_client_mix,
        },
        "rutas_rentabilidad": {
            "title": "Rentabilidad por ruta",
            "description": "Rutas con mayor ingreso y margen bruto estimado frente al costo operativo.",
            "sql": f"""
                with ingresos as (
                  select id_ruta, sum(monto_facturado_bob) as ingreso_facturado_bob, avg(cumple_sla_recojo_flag) * 100 as sla_cumplido_pct
                  from {args.database}.{args.schema}.fact_envio
                  group by 1
                ),
                viajes as (
                  select id_ruta, sum(costo_operativo_total_bob) as costo_operativo_bob, avg(ocupacion_pct) as ocupacion_pct
                  from {args.database}.{args.schema}.fact_viaje
                  group by 1
                )
                select
                  concat(coalesce(r.codigo_ruta, 'SIN_RUTA'), ' | ', coalesce(r.ciudad_origen, 'NA'), ' -> ', coalesce(r.ciudad_destino, 'NA')) as ruta,
                  coalesce(i.ingreso_facturado_bob, 0) as ingreso_facturado_bob,
                  coalesce(v.costo_operativo_bob, 0) as costo_operativo_bob,
                  coalesce(i.ingreso_facturado_bob, 0) - coalesce(v.costo_operativo_bob, 0) as margen_bruto_bob,
                  coalesce(i.sla_cumplido_pct, 0) as sla_cumplido_pct,
                  coalesce(v.ocupacion_pct, 0) as ocupacion_pct
                from {args.database}.{args.schema}.dim_ruta r
                left join ingresos i on r.id_ruta = i.id_ruta
                left join viajes v on r.id_ruta = v.id_ruta
                where coalesce(i.ingreso_facturado_bob, 0) > 0 or coalesce(v.costo_operativo_bob, 0) > 0
                order by ingreso_facturado_bob desc
                limit 12
            """,
            "plotter": lambda df, path: plot_bar(df, "RUTA", "MARGEN_BRUTO_BOB", "Margen bruto estimado por ruta", path, horizontal=True),
        },
        "sucursales_operacion": {
            "title": "Desempeno por sucursal origen",
            "description": "Ingreso, SLA y devoluciones para monitorear eficiencia comercial-operativa.",
            "sql": f"""
                select
                  concat(coalesce(ds.codigo_sucursal, 'SIN_SUC'), ' | ', coalesce(ds.ciudad, 'NA')) as sucursal,
                  count(*) as envios,
                  sum(fe.monto_facturado_bob) as ingreso_facturado_bob,
                  avg(fe.cumple_sla_recojo_flag) * 100 as sla_cumplido_pct,
                  avg(fe.devuelto_flag) * 100 as devolucion_pct,
                  avg(fe.tiempo_ciclo_horas) as tiempo_ciclo_prom_horas
                from {args.database}.{args.schema}.fact_envio fe
                left join {args.database}.{args.schema}.dim_sucursal ds on fe.id_sucursal_origen = ds.id_sucursal
                group by 1
                order by ingreso_facturado_bob desc
                limit 12
            """,
            "plotter": plot_branch_mix,
        },
        "rrhh_productividad": {
            "title": "Productividad y costo laboral",
            "description": "Costo laboral, horas trabajadas y ausentismo por area.",
            "sql": f"""
                select
                  coalesce(de.area, 'NO_DEFINIDA') as area,
                  count(distinct fr.id_empleado) as empleados,
                  sum(fr.liquido_pagable_bob) as costo_laboral_bob,
                  sum(fr.horas_trabajadas) as horas_trabajadas,
                  sum(fr.horas_extra) as horas_extra,
                  avg(fr.tasa_ausentismo_pct) as ausentismo_pct
                from {args.database}.{args.schema}.fact_rrhh_mensual fr
                left join {args.database}.{args.schema}.dim_empleado de on fr.id_empleado = de.id_empleado
                group by 1
                order by costo_laboral_bob desc
            """,
            "plotter": plot_rrhh,
        },
        "tracking_riesgo": {
            "title": "Riesgo y telemetria",
            "description": "Categorias de tracking con mayor volumen y mayor carga de alertas criticas.",
            "sql": f"""
                select
                  coalesce(dt.categoria_tracking, 'NO_DEFINIDA') as categoria_tracking,
                  count(*) as eventos,
                  sum(ft.alerta_critica_flag) as alertas_criticas,
                  avg(ft.gap_desde_evento_prev_min) as gap_promedio_min
                from {args.database}.{args.schema}.fact_tracking_evento ft
                left join {args.database}.{args.schema}.dim_tipo_tracking_evento dt on ft.id_tipo_tracking_evento = dt.id_tipo_tracking_evento
                group by 1
                order by eventos desc
            """,
            "plotter": plot_tracking,
        },
    }

    sections: list[dict[str, str]] = []
    errors: list[str] = []
    kpis: list[dict[str, str]] = []
    conn = None
    try:
        print(f"Conectando a Snowflake: {args.account} | {args.database}.{args.schema} | role={args.role}", flush=True)
        conn = build_connection(args)
        print("Conexion establecida.", flush=True)
        for key, config in queries.items():
            title = str(config["title"])
            description = str(config["description"])
            try:
                print(f"[RUN] {title}", flush=True)
                df = fetch_dataframe(conn, str(config["sql"]))
                df.columns = [col.upper() for col in df.columns]
                df.to_csv(data_dir / f"{key}.csv", index=False, encoding="utf-8")
                if key == "kpi_resumen":
                    row = df.iloc[0]
                    kpis = [
                        {"label": "Ingreso Facturado", "value": currency(row["INGRESO_FACTURADO_BOB"])},
                        {"label": "Cobranza", "value": currency(row["COBRANZA_BOB"])},
                        {"label": "Saldo Pendiente", "value": currency(row["SALDO_PENDIENTE_BOB"])},
                        {"label": "Saldo Vencido", "value": currency(row["SALDO_VENCIDO_BOB"])},
                        {"label": "Resultado Est.", "value": currency(row["RESULTADO_OPERATIVO_ESTIMADO_BOB"])},
                        {"label": "Flujo Neto Est.", "value": currency(row["FLUJO_NETO_ESTIMADO_BOB"])},
                        {"label": "SLA Cumplido", "value": percent(row["SLA_PCT"])},
                        {"label": "Ocupacion", "value": percent(row["OCUPACION_PROMEDIO_PCT"])},
                    ]
                    (output_dir / "kpi_resumen.json").write_text(json.dumps(row.to_dict(), default=str, indent=2), encoding="utf-8")
                else:
                    chart_path = charts_dir / f"{key}.png"
                    plotter = config.get("plotter")
                    if callable(plotter):
                        plotter(df, chart_path)
                        sections.append(
                            {
                                "title": title,
                                "description": description,
                                "image_rel": f"charts/{chart_path.name}",
                                "table_html": preview(df),
                            }
                        )
                print(f"[OK] {title}", flush=True)
            except Exception as exc:
                errors.append(f"{title}: {exc}")
                print(f"[ERROR] {title}: {exc}", flush=True)

        generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        build_html_report(output_dir / "eda_report.html", generated_at, args, kpis, sections, errors)
        print(f"Reporte generado en: {output_dir / 'eda_report.html'}")
        print(f"CSVs generados en: {data_dir}")
        print(f"Graficos generados en: {charts_dir}")
        if errors:
            print("\nAlgunas consultas fallaron:")
            for error in errors:
                print(f"- {error}")
            return 1
        return 0
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    sys.exit(main())
