param(
  [int]$Port = 3000,
  [string]$Target = "dev"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command dagster -ErrorAction SilentlyContinue)) {
  throw "No se encontro el comando 'dagster'. Instala las dependencias con: python -m pip install -r requirements.txt"
}

. (Join-Path $PSScriptRoot "load_env.ps1")

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$env:DAGSTER_HOME = Join-Path $repoRoot ".dagster_home"

New-Item -ItemType Directory -Path $env:DAGSTER_HOME -Force | Out-Null

& (Join-Path $PSScriptRoot "prepare_manifest.ps1") -Target $Target

Push-Location $repoRoot
try {
  & dagster dev -w ".\\dagster_project\\workspace.yaml" -p $Port
}
finally {
  Pop-Location
}
