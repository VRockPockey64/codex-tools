param(
    [Parameter(Mandatory = $true)]
    [string] $RoleArn,

    [string] $Region = "us-east-1",
    [string] $Runtime = "python3.13",
    [string] $ModelId = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
    [string] $GuardrailId = "e3uve6f999od",
    [string] $GuardrailVersion = "1",
    [int] $Timeout = 30,
    [int] $MemorySize = 256
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $repoRoot "build"
$packageRoot = Join-Path $buildRoot "packages"

$functions = @(
    @{
        Name = "applyguardrail-test-lambda"
        Source = "lambda/applyguardrail_test_lambda"
    },
    @{
        Name = "inline-guardrail-test-lambda"
        Source = "lambda/inline_guardrail_test_lambda"
    }
)

New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

foreach ($fn in $functions) {
    $functionName = $fn.Name
    $staging = Join-Path $buildRoot $functionName
    $zipPath = Join-Path $packageRoot "$functionName.zip"
    $sourcePath = Join-Path $repoRoot $fn.Source
    $commonPath = Join-Path $repoRoot "lambda/common"

    if (Test-Path $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $staging | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourcePath "handler.py") -Destination (Join-Path $staging "handler.py")
    Copy-Item -LiteralPath $commonPath -Destination (Join-Path $staging "common") -Recurse

    if (Test-Path $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zipPath -Force

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    aws lambda get-function --function-name $functionName --region $Region *> $null
    $exists = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $previousErrorActionPreference

    if ($exists) {
        Write-Host "Updating $functionName"
        aws lambda update-function-code `
            --function-name $functionName `
            --zip-file "fileb://$zipPath" `
            --region $Region | Out-Null

        aws lambda wait function-updated `
            --function-name $functionName `
            --region $Region

        aws lambda update-function-configuration `
            --function-name $functionName `
            --runtime $Runtime `
            --handler "handler.lambda_handler" `
            --timeout $Timeout `
            --memory-size $MemorySize `
            --environment "Variables={MODEL_ID=$ModelId,GUARDRAIL_ID=$GuardrailId,GUARDRAIL_VERSION=$GuardrailVersion}" `
            --region $Region | Out-Null
    }
    else {
        Write-Host "Creating $functionName"
        aws lambda create-function `
            --function-name $functionName `
            --runtime $Runtime `
            --role $RoleArn `
            --handler "handler.lambda_handler" `
            --zip-file "fileb://$zipPath" `
            --timeout $Timeout `
            --memory-size $MemorySize `
            --environment "Variables={MODEL_ID=$ModelId,GUARDRAIL_ID=$GuardrailId,GUARDRAIL_VERSION=$GuardrailVersion}" `
            --region $Region | Out-Null
    }
}

Write-Host "Done. Deployed $($functions.Count) Lambda functions."
