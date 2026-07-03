param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("applyguardrail-test-lambda", "inline-guardrail-test-lambda")]
    [string] $FunctionName,

    [Parameter(Mandatory = $true)]
    [string] $LayerArn,

    [string] $AuthToken,

    [string] $AuthTokenPath,

    [string] $Tenant = "mpc46642",
    [string] $Cluster = "-2079377986",
    [ValidateSet("DT_CLUSTER", "DT_CLUSTER_ID")]
    [string] $ClusterVariableName = "DT_CLUSTER_ID",
    [string] $ConnectionBaseUrl = "https://mpc46642.live.dynatrace.com",
    [string] $Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

if (-not $AuthToken) {
    if (-not $AuthTokenPath) {
        throw "Provide either -AuthToken or -AuthTokenPath."
    }

    $AuthToken = (Get-Content -LiteralPath $AuthTokenPath -Raw).Trim()
}

if (-not $AuthToken) {
    throw "Dynatrace auth token is empty."
}

$existing = aws lambda get-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --query "Environment.Variables" `
    --output json | ConvertFrom-Json

$vars = @{}
if ($existing) {
    $existing.PSObject.Properties | ForEach-Object {
        $vars[$_.Name] = [string]$_.Value
    }
}

$vars["AWS_LAMBDA_EXEC_WRAPPER"] = "/opt/dynatrace"
$vars["DT_TENANT"] = $Tenant
$vars.Remove("DT_CLUSTER")
$vars.Remove("DT_CLUSTER_ID")
$vars[$ClusterVariableName] = $Cluster
$vars["DT_CONNECTION_BASE_URL"] = $ConnectionBaseUrl
$vars["DT_CONNECTION_AUTH_TOKEN"] = $AuthToken

$envPairs = ($vars.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ","

aws lambda update-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --layers $LayerArn `
    --environment "Variables={$envPairs}" | Out-Null

aws lambda wait function-updated `
    --function-name $FunctionName `
    --region $Region

aws lambda get-function-configuration `
    --function-name $FunctionName `
    --region $Region `
    --query "{FunctionName:FunctionName,Runtime:Runtime,Architectures:Architectures,Layers:Layers[*].Arn,EnvironmentKeys:keys(Environment.Variables)}" `
    --output json
