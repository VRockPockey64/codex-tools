# Recommended Runtime State

Use this state when sharing or re-running the project after the experiment matrix.

## Lambda instrumentation

- Lambda layer mode: Classic Dynatrace Lambda layer
- OneAgent version: 1.329.2
- Python runtime: Python 3.13
- Lambda architecture: x86_64
- OpenLLMetry version: 0.45.4
- Recommended layer ARN:

```text
arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_329_2_20251114-045249_python:1
```

## Environment variable shape

Keep the Dynatrace Lambda wrapper enabled and use `DT_CLUSTER_ID`.

```text
AWS_LAMBDA_EXEC_WRAPPER=/opt/dynatrace
DT_TENANT=<tenant-id>
DT_CLUSTER_ID=<cluster-id>
DT_CONNECTION_BASE_URL=<tenant-url>
DT_CONNECTION_AUTH_TOKEN=<token>
DT_OPEN_TELEMETRY_ENABLE_INTEGRATION=true
```

## Why this is the recommended state

Classic OneAgent 1.329 with OpenLLMetry 0.45.4 produced the most complete and predictable trace shape during testing. It preserved LangGraph workflow/task spans and included `traceloop.entity.input` and `traceloop.entity.output` values without the 4096-character truncation seen with the latest layer.
