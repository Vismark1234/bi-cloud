param(
  [ValidateSet("debug", "parse", "run", "build", "test", "snapshot")]
  [string]$Accion = "debug",
  [string]$Target = "dev"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "load_env.ps1")

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectDir = Join-Path $repoRoot "dbt_project"

@("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "GIT_HTTP_PROXY", "GIT_HTTPS_PROXY") | ForEach-Object {
  [System.Environment]::SetEnvironmentVariable($_, $null, "Process")
}

if ($Accion -ne "parse" -and [string]::IsNullOrWhiteSpace($env:DBT_SNOWFLAKE_PASSWORD)) {
  throw "Falta DBT_SNOWFLAKE_PASSWORD en .env."
}

if ($Accion -ne "parse" -and $env:DBT_SNOWFLAKE_PASSWORD -eq "CAMBIAR_POR_PASSWORD_REAL") {
  throw "Debes reemplazar DBT_SNOWFLAKE_PASSWORD en .env antes de ejecutar dbt."
}

Push-Location $projectDir
try {
  & dbt $Accion --profiles-dir . --target $Target
}
finally {
  Pop-Location
}
