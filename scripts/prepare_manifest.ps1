param(
  [string]$Target = "dev"
)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "run_dbt.ps1") -Accion parse -Target $Target
