from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Callable

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import pandas as pd
import snowflake.connector


ROOT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_DIR = ROOT_DIR / "eda_output"


def load_env_file(env_path: Path) -> None:
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key and key not in os.environ:
            os.environ[key] = value


def get_env(name: str, default: str | None = None, required: bool = False) -> str:
    value = os.getenv(name, default)
    if required and not value:
        raise RuntimeError(f"Falta la variable de entorno requerida: {name}")
    return value or ""


def currency_formatter(value: float) -> str:
    return f"BOB {value:,.0f}"


def number_formatter(value: float) -> str:
    return f"{value:,.0f}"


def percent_formatter(value: float) -> str:
    return f"{value:,.1f}%"


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


def plot_fact_counts(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.bar(df["TABLA"], df["FILAS"], color="#1f77b4")
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: number_formatter(x)))
    ax.tick_params(axis="x", rotation=25)
    style_axes(ax, "Volumen de Filas por Hecho", "Hecho", "Filas")
    save_plot(fig, output_path)


def plot_monthly_revenue(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.plot(df["MES"], df["INGRESO_BOB"], marker="o", linewidth=2.2, color="#2ca02c")
    ax.fill_between(df["MES"], df["INGRESO_BOB"], color="#2ca02c", alpha=0.15)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: currency_formatter(x)))
    style_axes(ax, "Ingreso Facturado por Mes", "Mes", "Ingreso BOB")
    save_plot(fig, output_path)


def plot_service_flow(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.plot(df["MES"], df["CANTIDAD_ORDENES"], marker="o", linewidth=2, label="Ordenes", color="#1f77b4")
    ax.plot(df["MES"], df["CANTIDAD_ENVIOS"], marker="o", linewidth=2, label="Envios", color="#ff7f0e")
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: number_formatter(x)))
    style_axes(ax, "Flujo Mensual de Ordenes y Envios", "Mes", "Cantidad")
    ax.legend()
    save_plot(fig, output_path)


def plot_sla_cycle(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax1 = plt.subplots(figsize=(11, 5))
    ax2 = ax1.twinx()

    ax1.plot(df["MES"], df["SLA_CUMPLIDO_PCT"], marker="o", linewidth=2, color="#2ca02c", label="SLA %")
    ax2.plot(df["MES"], df["TIEMPO_CICLO_PROM_HORAS"], marker="s", linewidth=2, color="#d62728", label="Ciclo horas")

    ax1.set_ylabel("SLA Cumplido %")
    ax2.set_ylabel("Horas")
    ax1.yaxis.set_major_formatter(FuncFormatter(lambda x, _: percent_formatter(x)))
    ax2.yaxis.set_major_formatter(FuncFormatter(lambda x, _: number_formatter(x)))
    style_axes(ax1, "SLA y Tiempo de Ciclo por Mes", "Mes")

    lines = ax1.get_lines() + ax2.get_lines()
    labels = [line.get_label() for line in lines]
    ax1.legend(lines, labels, loc="upper left")

    save_plot(fig, output_path)


def plot_top_routes(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(11, 6))
    ordered = df.sort_values("INGRESO_BOB", ascending=True)
    ax.barh(ordered["RUTA"], ordered["INGRESO_BOB"], color="#9467bd")
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: currency_formatter(x)))
    style_axes(ax, "Top 10 Rutas por Ingreso Facturado", "Ingreso BOB", "Ruta")
    save_plot(fig, output_path)


def plot_payment_methods(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    ordered = df.sort_values("MONTO_BOB", ascending=False)
    ax.bar(ordered["METODO_PAGO"], ordered["MONTO_BOB"], color="#17becf")
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: currency_formatter(x)))
    ax.tick_params(axis="x", rotation=25)
    style_axes(ax, "Cobranza por Metodo de Pago", "Metodo", "Monto BOB")
    save_plot(fig, output_path)


def plot_tracking_categories(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(df["CATEGORIA_TRACKING"], df["EVENTOS"], color="#8c564b")
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: number_formatter(x)))
    style_axes(ax, "Eventos de Tracking por Categoria", "Categoria", "Eventos")
    save_plot(fig, output_path)


def plot_rrhh_area(df: pd.DataFrame, output_path: Path) -> None:
    fig, ax1 = plt.subplots(figsize=(11, 5))
    ax2 = ax1.twinx()

    ordered = df.sort_values("LIQUIDO_PAGABLE_BOB", ascending=False)
    ax1.bar(ordered["AREA"], ordered["LIQUIDO_PAGABLE_BOB"], color="#7f7f7f", alpha=0.85, label="Liquido pagable")
    ax2.plot(ordered["AREA"], ordered["AUSENTISMO_PCT"], color="#d62728", marker="o", linewidth=2, label="Ausentismo %")

    ax1.yaxis.set_major_formatter(FuncFormatter(lambda x, _: currency_formatter(x)))
    ax2.yaxis.set_major_formatter(FuncFormatter(lambda x, _: percent_formatter(x)))
    ax1.tick_params(axis="x", rotation=25)
    ax1.set_ylabel("Liquido pagable BOB")
    ax2.set_ylabel("Ausentismo %")
    style_axes(ax1, "Costo Laboral y Ausentismo por Area", "Area")

    lines = [ax1.patches[0], ax2.get_lines()[0]] if ax1.patches else ax2.get_lines()
    labels = ["Liquido pagable", "Ausentismo %"]
    ax1.legend(lines, labels, loc="upper left")

    save_plot(fig, output_path)


def dataframe_preview(df: pd.DataFrame, max_rows: int = 10) -> str:
    if df.empty:
        return "<p>Sin datos.</p>"
    preview = df.head(max_rows).copy()
    return preview.to_html(index=False, classes="preview-table", border=0)


def build_html_report(
    output_path: Path,
    generated_at: str,
    args: argparse.Namespace,
    kpis: list[dict[str, str]],
    sections: list[dict[str, str]],
    errors: list[str],
) -> None:
    cards_html = "\n".join(
        f"""
        <div class="card">
          <div class="card-label">{item['label']}</div>
          <div class="card-value">{item['value']}</div>
        </div>
        """
        for item in kpis
    )

    sections_html = "\n".join(
        f"""
        <section class="section">
          <h2>{section['title']}</h2>
          <p>{section['description']}</p>
          <img src="{section['image_rel']}" alt="{section['title']}">
          <div class="table-wrap">
            {section['table_html']}
          </div>
        </section>
        """
        for section in sections
    )

    errors_html = ""
    if errors:
        errors_html = """
        <section class="section error-box">
          <h2>Consultas con error</h2>
          <ul>
            %s
          </ul>
        </section>
        """ % "\n".join(f"<li>{error}</li>" for error in errors)

    html = f"""<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>EDA Snowflake DWH</title>
  <style>
    body {{
      font-family: Segoe UI, Arial, sans-serif;
      margin: 0;
      background: #f6f8fb;
      color: #1f2937;
    }}
    .container {{
      max-width: 1280px;
      margin: 0 auto;
      padding: 24px;
    }}
    .hero {{
      background: linear-gradient(135deg, #0f172a, #1d4ed8);
      color: white;
      padding: 24px;
      border-radius: 16px;
      margin-bottom: 24px;
    }}
    .cards {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
      margin: 20px 0 8px;
    }}
    .card {{
      background: white;
      border-radius: 14px;
      padding: 16px;
      box-shadow: 0 6px 18px rgba(15, 23, 42, 0.08);
    }}
    .card-label {{
      font-size: 12px;
      text-transform: uppercase;
      color: #64748b;
      margin-bottom: 8px;
    }}
    .card-value {{
      font-size: 24px;
      font-weight: 700;
    }}
    .section {{
      background: white;
      border-radius: 16px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 6px 18px rgba(15, 23, 42, 0.08);
    }}
    .section img {{
      width: 100%;
      border-radius: 12px;
      margin: 12px 0 16px;
    }}
    .preview-table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }}
    .preview-table th,
    .preview-table td {{
      border-bottom: 1px solid #e5e7eb;
      padding: 8px 10px;
      text-align: left;
    }}
    .preview-table th {{
      background: #eff6ff;
    }}
    .meta {{
      font-size: 14px;
      color: #dbeafe;
      margin-top: 8px;
    }}
    .error-box {{
      border-left: 6px solid #dc2626;
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="hero">
      <h1>EDA del DWH en Snowflake</h1>
      <p>Reporte generado desde Python contra {args.database}.{args.schema}</p>
      <div class="meta">Generado: {generated_at}</div>
    </div>
    <div class="cards">
      {cards_html}
    </div>
    {errors_html}
    {sections_html}
  </div>
</body>
</html>
"""

    output_path.write_text(html, encoding="utf-8")


def main() -> int:
    load_env_file(ROOT_DIR / ".env")

    parser = argparse.ArgumentParser(
        description="EDA y KPIs del DWH en Snowflake."
    )
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR), help="Carpeta de salida para reporte, CSVs y graficos.")
    parser.add_argument("--account", default=get_env("DBT_SNOWFLAKE_ACCOUNT", "TU_ACCOUNT_SNOWFLAKE"))
    parser.add_argument("--user", default=get_env("DBT_SNOWFLAKE_USER", "TU_USUARIO_SNOWFLAKE"))
    parser.add_argument("--password", default=get_env("DBT_SNOWFLAKE_PASSWORD"), required=False)
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

    queries: dict[str, dict[str, object]] = {
        "kpi_resumen": {
            "title": "KPIs Resumen",
            "description": "Resumen ejecutivo del volumen y los indicadores principales del DWH.",
            "sql": f"""
                select
                  (select count(*) from {args.database}.{args.schema}.fact_orden_servicio) as ordenes,
                  (select count(*) from {args.database}.{args.schema}.fact_envio) as envios,
                  (select count(*) from {args.database}.{args.schema}.fact_viaje) as viajes,
                  (select count(*) from {args.database}.{args.schema}.fact_facturacion) as lineas_facturacion,
                  (select count(*) from {args.database}.{args.schema}.fact_pago) as pagos,
                  (select count(*) from {args.database}.{args.schema}.fact_tracking_evento) as eventos_tracking,
                  (select count(*) from {args.database}.{args.schema}.fact_rrhh_mensual) as registros_rrhh,
                  (select coalesce(sum(total_linea_bob), 0) from {args.database}.{args.schema}.fact_facturacion) as ingreso_facturado_bob,
                  (select coalesce(sum(monto_bob), 0) from {args.database}.{args.schema}.fact_pago) as cobranza_bob,
                  (select coalesce(avg(cumple_sla_recojo_flag) * 100, 0) from {args.database}.{args.schema}.fact_envio) as sla_cumplido_pct,
                  (select coalesce(avg(ocupacion_pct), 0) from {args.database}.{args.schema}.fact_viaje) as ocupacion_promedio_pct
            """,
        },
        "fact_counts": {
            "title": "Volumen de Hechos",
            "description": "Cantidad de filas por tabla de hechos para entender el tamano relativo de cada proceso.",
            "sql": f"""
                select 'fact_orden_servicio' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_orden_servicio
                union all
                select 'fact_envio' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_envio
                union all
                select 'fact_viaje' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_viaje
                union all
                select 'fact_facturacion' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_facturacion
                union all
                select 'fact_pago' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_pago
                union all
                select 'fact_tracking_evento' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_tracking_evento
                union all
                select 'fact_rrhh_mensual' as tabla, count(*) as filas from {args.database}.{args.schema}.fact_rrhh_mensual
            """,
            "plotter": plot_fact_counts,
        },
        "monthly_revenue": {
            "title": "Ingreso Facturado por Mes",
            "description": "Tendencia mensual del ingreso facturado usando la fecha de emision.",
            "sql": f"""
                select
                  date_trunc('month', df.fecha)::date as mes,
                  sum(ff.total_linea_bob) as ingreso_bob
                from {args.database}.{args.schema}.fact_facturacion ff
                inner join {args.database}.{args.schema}.dim_fecha df
                  on ff.id_fecha_emision = df.id_fecha
                group by 1
                order by 1
            """,
            "plotter": plot_monthly_revenue,
        },
        "service_flow": {
            "title": "Flujo Mensual de Ordenes y Envios",
            "description": "Comparacion entre la generacion de ordenes y el registro de envios por mes.",
            "sql": f"""
                with ordenes as (
                  select
                    date_trunc('month', df.fecha)::date as mes,
                    count(*) as cantidad_ordenes
                  from {args.database}.{args.schema}.fact_orden_servicio fo
                  inner join {args.database}.{args.schema}.dim_fecha df
                    on fo.id_fecha_creacion_orden = df.id_fecha
                  group by 1
                ),
                envios as (
                  select
                    date_trunc('month', df.fecha)::date as mes,
                    count(*) as cantidad_envios
                  from {args.database}.{args.schema}.fact_envio fe
                  inner join {args.database}.{args.schema}.dim_fecha df
                    on fe.id_fecha_registro_envio = df.id_fecha
                  group by 1
                )
                select
                  coalesce(o.mes, e.mes) as mes,
                  coalesce(o.cantidad_ordenes, 0) as cantidad_ordenes,
                  coalesce(e.cantidad_envios, 0) as cantidad_envios
                from ordenes o
                full outer join envios e
                  on o.mes = e.mes
                order by 1
            """,
            "plotter": plot_service_flow,
        },
        "sla_cycle": {
            "title": "SLA y Tiempo de Ciclo",
            "description": "Vista mensual del cumplimiento SLA de recojo y del tiempo promedio de ciclo.",
            "sql": f"""
                select
                  date_trunc('month', df.fecha)::date as mes,
                  avg(fe.cumple_sla_recojo_flag) * 100 as sla_cumplido_pct,
                  avg(fe.tiempo_ciclo_horas) as tiempo_ciclo_prom_horas
                from {args.database}.{args.schema}.fact_envio fe
                inner join {args.database}.{args.schema}.dim_fecha df
                  on fe.id_fecha_registro_envio = df.id_fecha
                group by 1
                order by 1
            """,
            "plotter": plot_sla_cycle,
        },
        "top_routes": {
            "title": "Top 10 Rutas por Ingreso",
            "description": "Rutas con mayor monto facturado acumulado.",
            "sql": f"""
                with base as (
                  select
                    coalesce(dr.codigo_ruta, 'SIN_RUTA') as ruta,
                    sum(ff.total_linea_bob) as ingreso_bob,
                    count(*) as lineas_facturadas
                  from {args.database}.{args.schema}.fact_facturacion ff
                  left join {args.database}.{args.schema}.dim_ruta dr
                    on ff.id_ruta = dr.id_ruta
                  group by 1
                )
                select *
                from base
                order by ingreso_bob desc
                limit 10
            """,
            "plotter": plot_top_routes,
        },
        "payment_methods": {
            "title": "Cobranza por Metodo de Pago",
            "description": "Distribucion de pagos por metodo usando el monto cobrado.",
            "sql": f"""
                select
                  coalesce(dm.metodo_pago, 'NO_DEFINIDO') as metodo_pago,
                  count(*) as cantidad_pagos,
                  sum(fp.monto_bob) as monto_bob
                from {args.database}.{args.schema}.fact_pago fp
                left join {args.database}.{args.schema}.dim_metodo_pago dm
                  on fp.id_metodo_pago = dm.id_metodo_pago
                group by 1
                order by monto_bob desc
            """,
            "plotter": plot_payment_methods,
        },
        "tracking_categories": {
            "title": "Eventos por Categoria de Tracking",
            "description": "Volumen de eventos por categoria analitica de tracking.",
            "sql": f"""
                select
                  coalesce(dt.categoria_tracking, 'NO_DEFINIDA') as categoria_tracking,
                  count(*) as eventos,
                  sum(ft.alerta_critica_flag) as alertas_criticas
                from {args.database}.{args.schema}.fact_tracking_evento ft
                left join {args.database}.{args.schema}.dim_tipo_tracking_evento dt
                  on ft.id_tipo_tracking_evento = dt.id_tipo_tracking_evento
                group by 1
                order by eventos desc
            """,
            "plotter": plot_tracking_categories,
        },
        "rrhh_area": {
            "title": "Costo Laboral y Ausentismo por Area",
            "description": "Cruce del costo laboral neto y el ausentismo promedio por area.",
            "sql": f"""
                select
                  coalesce(de.area, 'NO_DEFINIDA') as area,
                  sum(fr.liquido_pagable_bob) as liquido_pagable_bob,
                  avg(fr.tasa_ausentismo_pct) as ausentismo_pct,
                  sum(fr.horas_trabajadas) as horas_trabajadas
                from {args.database}.{args.schema}.fact_rrhh_mensual fr
                left join {args.database}.{args.schema}.dim_empleado de
                  on fr.id_empleado = de.id_empleado
                group by 1
                order by liquido_pagable_bob desc
            """,
            "plotter": plot_rrhh_area,
        },
    }

    sections: list[dict[str, str]] = []
    errors: list[str] = []
    kpis: list[dict[str, str]] = []

    conn = None
    try:
        print(
            f"Conectando a Snowflake: {args.account} | {args.database}.{args.schema} | role={args.role}",
            flush=True,
        )
        conn = build_connection(args)
        print("Conexion establecida.", flush=True)

        for key, config in queries.items():
            title = str(config["title"])
            description = str(config["description"])
            sql = str(config["sql"])

            try:
                print(f"[RUN] {title}", flush=True)
                df = fetch_dataframe(conn, sql)
                df.columns = [col.upper() for col in df.columns]
                df.to_csv(data_dir / f"{key}.csv", index=False, encoding="utf-8")

                if key == "kpi_resumen":
                    row = df.iloc[0]
                    kpis = [
                        {"label": "Ordenes", "value": number_formatter(row["ORDENES"])},
                        {"label": "Envios", "value": number_formatter(row["ENVIOS"])},
                        {"label": "Viajes", "value": number_formatter(row["VIAJES"])},
                        {"label": "Ingreso Facturado", "value": currency_formatter(row["INGRESO_FACTURADO_BOB"])},
                        {"label": "Cobranza", "value": currency_formatter(row["COBRANZA_BOB"])},
                        {"label": "SLA Cumplido", "value": percent_formatter(row["SLA_CUMPLIDO_PCT"])},
                        {"label": "Ocupacion Promedio", "value": percent_formatter(row["OCUPACION_PROMEDIO_PCT"])},
                        {"label": "Eventos Tracking", "value": number_formatter(row["EVENTOS_TRACKING"])},
                    ]
                    (output_dir / "kpi_resumen.json").write_text(
                        json.dumps(row.to_dict(), default=str, indent=2),
                        encoding="utf-8",
                    )
                    print(f"[OK] {title}", flush=True)
                    continue

                plotter = config.get("plotter")
                chart_path = charts_dir / f"{key}.png"
                if callable(plotter):
                    plotter(df, chart_path)
                    sections.append(
                        {
                            "title": title,
                            "description": description,
                            "image_rel": f"charts/{chart_path.name}",
                            "table_html": dataframe_preview(df),
                        }
                    )
                print(f"[OK] {title}", flush=True)
            except Exception as exc:
                errors.append(f"{title}: {exc}")
                print(f"[ERROR] {title}: {exc}", flush=True)

        generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        build_html_report(
            output_dir / "eda_report.html",
            generated_at,
            args,
            kpis,
            sections,
            errors,
        )

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
