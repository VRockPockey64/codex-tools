param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("applyguardrail-test-lambda", "inline-guardrail-test-lambda")]
    [string] $FunctionName,

    [string] $Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

$existing = aws lambda get-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --query "Environment.Variables" `
    --output json | ConvertFrom-Json

$vars = @{}
if ($existing) {
    $existing.PSObject.Properties | ForEach-Object {
        if ($_.Name -notlike "DT_*" -and $_.Name -ne "AWS_LAMBDA_EXEC_WRAPPER") {
            $vars[$_.Name] = [string]$_.Value
        }
    }
}

$envPairs = ($vars.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ","

aws lambda update-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --layers "[]" `
    --environment "Variables={$envPairs}" | Out-Null

aws lambda wait function-updated `
    --function-name $FunctionName `
    --region $Region

aws lambda get-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --query "{FunctionName:FunctionName,Layers:Layers[*].Arn,EnvironmentKeys:keys(Environment.Variables)}" `
    --output json
