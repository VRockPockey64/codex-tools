# Classic Dynatrace Layer + OneAgent 1.329.2 Baseline

Scenario:

```text
Lambdas:
- applyguardrail-test-lambda
- inline-guardrail-test-lambda

Dynatrace layer generation: classic
OneAgent: 1.329.2.20251114-045249
Layer ARN: arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_329_2_20251114-045249_python:1
Traceloop: not installed
Manual span attributes: none
Lambda code changes for observability: none
```

Important configuration detail:

```text
Classic layer requires DT_CLUSTER_ID.
Latest-generation layer used DT_CLUSTER.
```

Source exports:

```text
test-outputs\1.329_classic_applyguardrail.csv
test-outputs\1.329_classic_inlineguardrail.csv
```

Repo-local raw copies:

```text
test-outputs\1.329_classic_applyguardrail.csv
test-outputs\1.329_classic_inlineguardrail.csv
```

## Observed Spans

Explicit ApplyGuardrail export:

```text
Rows: 10
Traces: 3
Span names:
- applyguardrail-test-lambda
- POST
Telemetry SDK version:
- 1.329.2.20251114-045249
```

Inline guardrail export:

```text
Rows: 6
Traces: 3
Span names:
- inline-guardrail-test-lambda
- POST
Telemetry SDK version:
- 1.329.2.20251114-045249
```

## gen_ai Attribute Findings

The DQL query selected the same `gen_ai.*` fields used in the latest-layer tests, but none were populated.

No populated values were found for:

```text
gen_ai.operation.name
gen_ai.provider.name
gen_ai.request.max_tokens
gen_ai.request.model
gen_ai.response.finish_reasons
gen_ai.response.model
gen_ai.usage.input_tokens
gen_ai.usage.output_tokens
gen_ai.guardrail.id
gen_ai.guardrail.input.latency
gen_ai.guardrail.input.sensitive_information.piis
gen_ai.guardrail.output.latency
gen_ai.guardrail.output.sensitive_information.piis
gen_ai.prompt.0.content
gen_ai.completion.0.content
```

## Comparison To Classic 1.331.3

Classic `1.329.2` did not improve the span names or GenAI attributes compared with classic `1.331.3`.

Both classic versions showed the same high-level shape:

```text
ApplyGuardrail Lambda:
- root span named applyguardrail-test-lambda
- child Bedrock Runtime calls named POST
- no populated gen_ai.* fields

Inline guardrail Lambda:
- root span named inline-guardrail-test-lambda
- child Bedrock Runtime call named POST
- no populated gen_ai.* fields
```

## Baseline Conclusion

With classic Dynatrace Lambda layer and OneAgent `1.329.2`, without Traceloop and without manual instrumentation:

- Traces are produced when using `DT_CLUSTER_ID`.
- Span names are generic.
- Bedrock calls are represented as `POST`, not `aws_bedrock.text_completion` or `bedrock-runtime/applyguardrail`.
- No `gen_ai.*` attributes are populated.
- No prompt/completion content is captured.
- Classic `1.329.2` is not materially better than classic `1.331.3` for native Bedrock GenAI visibility.
