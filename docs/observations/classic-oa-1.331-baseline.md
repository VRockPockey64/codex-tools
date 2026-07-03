# Classic Dynatrace Layer + OneAgent 1.331.3 Baseline

Scenario:

```text
Lambdas:
- applyguardrail-test-lambda
- inline-guardrail-test-lambda

Dynatrace layer generation: classic
OneAgent: 1.331.3.20260109-072644
Layer ARN: arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_331_3_20260109-072644_python:1
Traceloop: not installed
Manual span attributes: none
Lambda code changes for observability: none
```

Important configuration detail:

```text
Classic layer requires DT_CLUSTER_ID.
Latest-generation layer used DT_CLUSTER.
```

After switching from `DT_CLUSTER` to `DT_CLUSTER_ID`, traces appeared in Dynatrace.

Source exports:

```text
test-outputs\1.331_classic_applyguardrail.csv
test-outputs\1.331_classic_inlineguardrail.csv
```

## Observed Spans

Explicit ApplyGuardrail export:

```text
Rows: 10
Traces: 3
Span names:
- applyguardrail-test-lambda
- POST
```

Inline guardrail export:

```text
Rows: 6
Traces: 3
Span names:
- inline-guardrail-test-lambda
- POST
```

## gen_ai Attribute Findings

The DQL query selected the same `gen_ai.*` fields used in latest-layer tests, but none were populated.

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

## Baseline Conclusion

With classic Dynatrace Lambda layer and OneAgent `1.331.3`, without Traceloop and without manual instrumentation:

- Traces are produced after using `DT_CLUSTER_ID`.
- Span names are generic.
- Bedrock calls are represented as `POST`, not `aws_bedrock.text_completion` or `bedrock-runtime/applyguardrail`.
- No `gen_ai.*` attributes are populated.
- No prompt/completion content is captured.
- Classic layer behavior is materially less useful for this GenAI/Bedrock guardrail experiment than the latest-generation layer.
