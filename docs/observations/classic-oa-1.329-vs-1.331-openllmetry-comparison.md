# Classic OneAgent 1.329.2 vs 1.331.3 With OpenLLMetry 0.45.4

Scenario:

```text
Layer generation: classic
Compared OneAgent versions:
- 1.329.2.20251114-045249
- 1.331.3.20260109-072644

Lambdas:
- applyguardrail-test-lambda
- inline-guardrail-test-lambda

LangGraph: enabled
OpenLLMetry/Traceloop instrumentors: 0.45.4
Traceloop exporter: not used
Dynatrace OneAgent OTel bridge: DT_OPEN_TELEMETRY_ENABLE_INTEGRATION=true
Manual span attributes: none
Custom spans/decorators: none
```

Source exports:

```text
test-outputs\1.329_classic_applyguardrail_traceloop.csv
test-outputs\1.329_classic_inlineguardrail_traceloop.csv
test-outputs\1.331_classic_applyguardrail_traceloop.csv
test-outputs\1.331_classic_inlineguardrail_traceloop.csv
```

## ApplyGuardrail Lambda

Both `1.329.2` and `1.331.3` produced the same export shape:

```text
Rows: 15
Traces: 2
Span names:
- applyguardrail-test-lambda
- LangGraph.workflow
- applyguardrail_input.task
- should_call_model.task
- bedrock_model.task
- bedrock.completion
- applyguardrail_output.task
- POST
```

Both versions had the same populated attribute counts:

```text
traceloop.entity.input: 8
traceloop.entity.output: 8
traceloop.entity.name: 8
traceloop.span.kind: 8
gen_ai.prompt.0.role: 1
gen_ai.prompt.0.content: 1
gen_ai.request.model: 1
gen_ai.request.max_tokens: 1
gen_ai.completion.0.content: 1
gen_ai.response.model: 1
gen_ai.response.id: 1
gen_ai.usage.prompt_tokens: 1
gen_ai.usage.completion_tokens: 1
llm.usage.total_tokens: 1
```

The blocked input trace stopped after `applyguardrail_input.task` and `should_call_model.task` in both versions. This means the blocked prompt did not produce a `bedrock.completion` GenAI span in either version.

## Inline Guardrail Lambda

Both `1.329.2` and `1.331.3` produced the same export shape:

```text
Rows: 10
Traces: 2
Span names:
- inline-guardrail-test-lambda
- LangGraph.workflow
- bedrock_inline_guardrail.task
- bedrock.completion
- POST
```

Both versions had the same populated attribute counts:

```text
traceloop.entity.input: 4
traceloop.entity.output: 4
traceloop.entity.name: 4
traceloop.span.kind: 4
gen_ai.prompt.0.role: 2
gen_ai.prompt.0.content: 2
gen_ai.request.model: 2
gen_ai.request.max_tokens: 2
gen_ai.completion.0.content: 2
gen_ai.response.model: 1
gen_ai.response.id: 1
gen_ai.usage.prompt_tokens: 1
gen_ai.usage.completion_tokens: 1
llm.usage.total_tokens: 1
```

Both versions produced `bedrock.completion` spans for the safe and blocked inline traces. The blocked inline trace included prompt/completion content and guardrail details through OpenLLMetry/LangGraph task output in both versions.

## Conclusion

No material difference was observed between classic OneAgent `1.329.2` and classic OneAgent `1.331.3` when OpenLLMetry `0.45.4` and the Dynatrace OTel bridge were enabled.

The useful attributes appear to be coming from the OpenLLMetry instrumentation plus Dynatrace's OTel bridge, not from a meaningful instrumentation behavior difference between these two classic OneAgent versions.
