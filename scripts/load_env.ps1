param(
  [string]$EnvFile = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) ".env")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $EnvFile)) {
  throw "No se encontro el archivo .env en la raiz del repositorio. Copia .env.example a .env y completa tus credenciales."
}

Get-Content -LiteralPath $EnvFile | ForEach-Object {
  $line = $_.Trim()

  if (-not $line) { return }
  if ($line.StartsWith("#")) { return }
  if ($line -notmatch "=") { return }

  $parts = $line.Split("=", 2)
  $name = $parts[0].Trim()
  $value = $parts[1].Trim()

  [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
}
