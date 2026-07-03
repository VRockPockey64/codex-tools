# Dynatrace OneAgent + Bedrock Guardrails GenAI Observability Experiment

## Purpose

This page summarizes a controlled experiment comparing Dynatrace OneAgent behavior for two AWS Lambda chatbot implementations that use Amazon Bedrock Guardrails.

The goal was to determine which Dynatrace layer / OneAgent / OpenLLMetry combination exposes useful GenAI, guardrail, prompt, and Traceloop attributes in spans without manually setting span attributes in Lambda code.

## Lambda Implementations Tested

| Lambda | Guardrail pattern | Behavior |
| --- | --- | --- |
| `applyguardrail-test-lambda` | Explicit `ApplyGuardrail` | Calls Bedrock `ApplyGuardrail` before model invocation, calls Bedrock model, then calls `ApplyGuardrail` after the model response. Blocked input short-circuits before the model call. |
| `inline-guardrail-test-lambda` | Inline guardrail | Calls Bedrock `InvokeModel` with guardrail configuration passed inline. Guardrail result is returned as part of the Bedrock model response/trace. |

## Common AWS Test Setup

| Item | Value |
| --- | --- |
| AWS region | `us-east-1` |
| Lambda runtime | `python3.13` |
| Lambda architecture | `x86_64` |
| Bedrock model invocation profile | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| Bedrock guardrail ID | `e3uve6f999od` |
| Bedrock guardrail version | `1` |
| Guardrail name | `guardrail-test-chatbot` |
| Guardrail policies used | Content filters, plus PII filters for `EMAIL` and `PHONE` |
| Manual span attributes | None |
| Custom spans/decorators | None |

## Prompt Set

Baseline/native tests used three prompt paths:

| Prompt path | Purpose |
| --- | --- |
| Safe prompt | Confirm normal model invocation. |
| Email input block | Trigger input-side sensitive information guardrail. |
| Output email anonymization | Trigger output-side sensitive information guardrail. |

OpenLLMetry/Traceloop tests used two prompt paths:

| Prompt path | Purpose |
| --- | --- |
| Safe prompt | Confirm normal model invocation. |
| Combined EMAIL + HATE prompt | Trigger sensitive information and content policy in one trace. |

## Important Export Caveat

Dynatrace notebook CSV exports truncate long string fields at about `1000` characters. CSVs are useful for checking whether attributes are present, but they are not reliable for validating full long JSON payloads.

Separately, latest-generation OneAgent `1.329.73` showed a UI/copy truncation behavior for long `traceloop.entity.output` around `4096` characters. Classic OneAgent did not show that same UI truncation in the copied sample reviewed during this experiment.

## Layer And Instrumentation Conditions

| Condition ID | Layer generation | OneAgent version | Layer ARN | Traceloop/OpenLLMetry | OTel API / SDK | OTel contrib / semantic versions | Lambda code shape |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C1 | Classic | `1.329.2.20251114-045249` | `arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_329_2_20251114-045249_python:1` | None | N/A | N/A | Native Lambda code, no LangGraph/OpenLLMetry |
| C2 | Classic | `1.331.3.20260109-072644` | `arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_331_3_20260109-072644_python:1` | None | N/A | N/A | Native Lambda code, no LangGraph/OpenLLMetry |
| L1 | Latest | `1.329.73.20260123-140641` | `arn:aws:lambda:us-east-1:585768157899:layer:Dynatrace_OneAgent_1_329_73_20260123-140641_python_x86:1` | None | N/A | N/A | Native Lambda code, no LangGraph/OpenLLMetry |
| L2 | Latest | `1.339.55.20260615-110349` | `arn:aws:lambda:us-east-1:585768157899:layer:Dynatrace_OneAgent_1_339_55_20260615-110349_python_x86:1` | None | N/A | N/A | Native Lambda code, no LangGraph/OpenLLMetry |
| C3 | Classic | `1.329.2.20251114-045249` | `arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_329_2_20251114-045249_python:1` | OpenLLMetry `0.45.4` instrumentors | `opentelemetry-api==1.38.0` | `opentelemetry-instrumentation==0.59b0`, `opentelemetry-semantic-conventions==0.59b0`, `opentelemetry-semantic-conventions-ai==0.4.13` | LangGraph wrapper plus direct `BedrockInstrumentor` and `LangchainInstrumentor`; no Traceloop exporter |
| C4 | Classic | `1.331.3.20260109-072644` | `arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_331_3_20260109-072644_python:1` | OpenLLMetry `0.45.4` instrumentors | `opentelemetry-api==1.38.0` | `opentelemetry-instrumentation==0.59b0`, `opentelemetry-semantic-conventions==0.59b0`, `opentelemetry-semantic-conventions-ai==0.4.13` | LangGraph wrapper plus direct `BedrockInstrumentor` and `LangchainInstrumentor`; no Traceloop exporter |
| L3 | Latest | `1.329.73.20260123-140641` | `arn:aws:lambda:us-east-1:585768157899:layer:Dynatrace_OneAgent_1_329_73_20260123-140641_python_x86:1` | OpenLLMetry `0.45.4` instrumentors | `opentelemetry-api==1.38.0` | `opentelemetry-instrumentation==0.59b0`, `opentelemetry-semantic-conventions==0.59b0`, `opentelemetry-semantic-conventions-ai==0.4.13` | LangGraph wrapper plus direct `BedrockInstrumentor` and `LangchainInstrumentor`; no Traceloop exporter |
| L4 | Latest | `1.339.55.20260615-110349` | `arn:aws:lambda:us-east-1:585768157899:layer:Dynatrace_OneAgent_1_339_55_20260615-110349_python_x86:1` | OpenLLMetry `0.45.4` instrumentors | `opentelemetry-api==1.38.0` | `opentelemetry-instrumentation==0.59b0`, `opentelemetry-semantic-conventions==0.59b0`, `opentelemetry-semantic-conventions-ai==0.4.13` | LangGraph wrapper plus direct `BedrockInstrumentor` and `LangchainInstrumentor`; no Traceloop exporter |

Notes:

- Classic layers required `DT_CLUSTER_ID`.
- Latest-generation layers used `DT_CLUSTER`.
- OpenLLMetry was used only as instrumentation. `Traceloop.init()` and a separate OTLP exporter were not used.
- The Dynatrace OneAgent OTel bridge was enabled for OpenLLMetry tests with `DT_OPEN_TELEMETRY_ENABLE_INTEGRATION=true`.

## Results Matrix

Legend:

- **Yes** means the attribute family was present in the reviewed traces/exports.
- **No** means the attribute family was not observed.
- **Partial** means only some traces or only model metadata were observed.
- **Truncated** means values were present but long payloads were clipped in UI/export.

| Condition | Lambda | Span shape observed | `gen_ai.*` present? | Native guardrail fields? | Prompt/completion content? | `traceloop.entity.*` fields? | Key finding |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C1 Classic `1.329`, no Traceloop | ApplyGuardrail | Lambda root + generic `POST` | No | No | No | N/A | Classic native layer produced traces but no GenAI enrichment. |
| C1 Classic `1.329`, no Traceloop | Inline | Lambda root + generic `POST` | No | No | No | N/A | Same as ApplyGuardrail: generic AWS call spans only. |
| C2 Classic `1.331`, no Traceloop | ApplyGuardrail | Lambda root + generic `POST` | No | No | No | N/A | No improvement over classic `1.329`. |
| C2 Classic `1.331`, no Traceloop | Inline | Lambda root + generic `POST` | No | No | No | N/A | No improvement over classic `1.329`. |
| L1 Latest `1.329`, no Traceloop | ApplyGuardrail | `lambda_handler`, `bedrock-runtime/applyguardrail`, `aws_bedrock.text_completion` | Yes, model spans only | No for explicit `ApplyGuardrail` spans | No | N/A | Latest native layer recognized Bedrock model calls as GenAI, but explicit guardrail calls were not GenAI-enriched. |
| L1 Latest `1.329`, no Traceloop | Inline | `lambda_handler`, `aws_bedrock.text_completion` | Yes | Yes | No | N/A | Inline guardrail was represented on the GenAI model span with guardrail ID/latency/PII fields. |
| L2 Latest `1.339`, no Traceloop | ApplyGuardrail | `lambda_handler`, `bedrock-runtime/applyguardrail`, `aws_bedrock.text_completion` | Yes, model spans only | No populated values for explicit `ApplyGuardrail` | No | N/A | No meaningful improvement over latest `1.329` for explicit `ApplyGuardrail`. |
| L2 Latest `1.339`, no Traceloop | Inline | `lambda_handler`, `aws_bedrock.text_completion` | Yes | Yes | No | N/A | Similar to latest `1.329`; minor metadata improvement only. |
| C3 Classic `1.329` + OpenLLMetry `0.45.4` | ApplyGuardrail | Lambda root, `LangGraph.workflow`, guardrail/model tasks, `bedrock.completion`, `POST` | Yes, safe model call | Via `traceloop.entity.output`, not native `gen_ai.guardrail.*` | Yes for safe model call; blocked input represented through LangGraph/Traceloop payload | Yes | Best explicit ApplyGuardrail visibility. Guardrail workflow stages and payloads were visible in LangGraph/Traceloop attributes. |
| C3 Classic `1.329` + OpenLLMetry `0.45.4` | Inline | Lambda root, `LangGraph.workflow`, `bedrock_inline_guardrail.task`, `bedrock.completion`, `POST` | Yes | Via `traceloop.entity.output` | Yes, including blocked prompt/blocked response | Yes | Best inline visibility. Prompt/completion and guardrail details were visible. |
| C4 Classic `1.331` + OpenLLMetry `0.45.4` | ApplyGuardrail | Same as classic `1.329` + OpenLLMetry | Yes, safe model call | Via `traceloop.entity.output`, not native `gen_ai.guardrail.*` | Yes for safe model call; blocked input represented through LangGraph/Traceloop payload | Yes | No material difference from classic `1.329` + OpenLLMetry. |
| C4 Classic `1.331` + OpenLLMetry `0.45.4` | Inline | Same as classic `1.329` + OpenLLMetry | Yes | Via `traceloop.entity.output` | Yes, including blocked prompt/blocked response | Yes | No material difference from classic `1.329` + OpenLLMetry. |
| L3 Latest `1.329` + OpenLLMetry `0.45.4` | ApplyGuardrail | `lambda_handler`, `LangGraph.workflow`, tasks, `aws_bedrock.text_completion`, `bedrock-runtime/applyguardrail` | Partial: model metadata only | Guardrail details mainly via `traceloop.entity.output`; explicit `ApplyGuardrail` not natively GenAI-enriched | No `gen_ai.prompt.0.content` / `gen_ai.completion.0.content` in CSV | Yes, but truncated | Cleaner native span names than classic, but worse prompt/completion visibility. Long `traceloop.entity.output` appeared truncated around `4096` in UI. |
| L3 Latest `1.329` + OpenLLMetry `0.45.4` | Inline | `lambda_handler`, `LangGraph.workflow`, `bedrock_inline_guardrail.task`, `aws_bedrock.text_completion` | Partial: model metadata only | Via Traceloop payload and native model span behavior | No `gen_ai.prompt.0.content` / `gen_ai.completion.0.content` in CSV | Yes, but truncated | Traceloop entity fields existed, but latest layer truncated long payloads and did not expose prompt/completion content as GenAI fields. |
| L4 Latest `1.339` + OpenLLMetry `0.45.4` | ApplyGuardrail | Same native/latest span shape as L3 | Partial: model metadata only | No useful explicit ApplyGuardrail GenAI enrichment observed | No | No | LangGraph span structure remained, but Traceloop entity attributes disappeared. |
| L4 Latest `1.339` + OpenLLMetry `0.45.4` | Inline | Same native/latest span shape as L3 | Partial: model metadata only | Similar to native latest-layer behavior | No | No | Behavior resembled native OneAgent `1.339`; `traceloop.entity.*` fields were not preserved/exported. |

## Field-Level Summary

| Attribute family | Classic native | Latest native | Classic + OpenLLMetry `0.45.4` | Latest `1.329` + OpenLLMetry `0.45.4` | Latest `1.339` + OpenLLMetry `0.45.4` |
| --- | --- | --- | --- | --- | --- |
| Basic traces | Yes | Yes | Yes | Yes | Yes |
| GenAI model span | No | Yes for Bedrock model calls | Yes through OpenLLMetry `bedrock.completion` | Yes, native `aws_bedrock.text_completion` | Yes, native `aws_bedrock.text_completion` |
| `gen_ai.request.model` / max tokens | No | Yes | Yes | Yes | Yes |
| Token usage | No | Yes on successful model calls | Yes on successful model calls | Mostly absent/limited in reviewed CSV | Mostly absent/limited in reviewed CSV |
| Prompt content | No | No | Yes, especially inline | No | No |
| Completion content | No | No | Yes, especially inline | No | No |
| Explicit `ApplyGuardrail` as GenAI span | No | No | No native GenAI span; visible through LangGraph/Traceloop task output | No native GenAI span; visible through truncated Traceloop task output | No |
| Inline guardrail attributes | No | Yes | Visible through Traceloop task output | Visible through Traceloop task output, truncated | Native-like only; no Traceloop entity payload |
| `traceloop.entity.input/output` | N/A | N/A | Yes | Yes, but long output truncated in UI/export | No |
| LangGraph workflow/task spans | No | No | Yes | Yes | Yes, but without Traceloop entity attributes |

## Key Conclusions

1. Latest-generation OneAgent native instrumentation recognizes Bedrock model calls as GenAI spans. Classic native instrumentation does not.

2. Inline guardrail invocation gives better native guardrail visibility than explicit `ApplyGuardrail`. Explicit `ApplyGuardrail` spans are visible as Bedrock Runtime client calls but are not enriched as GenAI guardrail spans.

3. Classic OneAgent with OpenLLMetry `0.45.4` gave the richest prompt, completion, LangGraph, and guardrail payload visibility.

4. Classic `1.329.2` and classic `1.331.3` behaved the same with OpenLLMetry `0.45.4`.

5. Latest `1.329.73` with OpenLLMetry preserved `traceloop.entity.*` fields, but long `traceloop.entity.output` values were truncated in the Dynatrace UI around `4096` characters and in notebook CSV export around `1000` characters.

6. Latest `1.339.55` with OpenLLMetry preserved the span structure but did not preserve/export `traceloop.entity.*` fields.

7. No tested latest-layer condition exposed full prompt/completion content in the reviewed Distributed Tracing/CSV fields.

## Recommended Interpretation

For this Bedrock Claude + Guardrails Lambda use case:

- Use latest-generation OneAgent native instrumentation when cleaner native Bedrock span names and basic GenAI metadata are enough.
- Use classic OneAgent plus OpenLLMetry `0.45.4` when prompt/completion and full LangGraph/Traceloop payload visibility are required.
- Treat long `traceloop.entity.output` values cautiously in Dynatrace exports and latest-layer UI views because truncation can hide guardrail details.
- Do not assume explicit `ApplyGuardrail` API calls will produce native `gen_ai.guardrail.*` fields. Inline guardrail invocation currently gives better native guardrail metadata.

## Source Observation Files

Detailed supporting notes are available in the repository:

| Topic | File |
| --- | --- |
| Latest `1.329` ApplyGuardrail native baseline | `docs/observations/latest-oa-1.329-applyguardrail.md` |
| Latest `1.329` inline native baseline | `docs/observations/latest-oa-1.329-inlineguardrail.md` |
| Latest `1.329` vs `1.339` native baseline | `docs/observations/latest-oa-1.329-vs-1.339-comparison.md` |
| Classic `1.329` native baseline | `docs/observations/classic-oa-1.329-baseline.md` |
| Classic `1.331` native baseline | `docs/observations/classic-oa-1.331-baseline.md` |
| Classic `1.329` / `1.331` OpenLLMetry comparison | `docs/observations/classic-oa-1.329-vs-1.331-openllmetry-comparison.md` |
| Latest `1.329` OpenLLMetry comparison | `docs/observations/latest-oa-1.329-openllmetry-comparison.md` |
| Latest `1.329` vs `1.339` OpenLLMetry comparison | `docs/observations/latest-oa-1.329-vs-1.339-openllmetry-comparison.md` |
