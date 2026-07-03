param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("applyguardrail-test-lambda", "inline-guardrail-test-lambda")]
    [string] $FunctionName,

    [string] $EventPath = "events/safe.json",
    [string] $Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedEventPath = Resolve-Path (Join-Path $repoRoot $EventPath)
$responsePath = Join-Path $repoRoot "build/$FunctionName-response.json"

New-Item -ItemType Directory -Force -Path (Split-Path $responsePath) | Out-Null

aws lambda invoke `
    --function-name $FunctionName `
    --payload "fileb://$resolvedEventPath" `
    --region $Region `
    $responsePath | Write-Host

Get-Content -LiteralPath $responsePath
