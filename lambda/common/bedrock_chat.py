import json
import os
from typing import Any, Dict, Optional

import boto3


DEFAULT_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
DEFAULT_GUARDRAIL_ID = "e3uve6f999od"
DEFAULT_GUARDRAIL_VERSION = "1"
DEFAULT_MAX_TOKENS = 512


bedrock_runtime = boto3.client("bedrock-runtime")


def env(name: str, default: str) -> str:
    value = os.environ.get(name)
    return value if value else default


def parse_event(event: Dict[str, Any]) -> Dict[str, Any]:
    body = event.get("body", event)
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            body = {"message": body}

    if not isinstance(body, dict):
        body = {"message": str(body)}

    message = body.get("message") or body.get("prompt") or body.get("input")
    if not message:
        message = "Hello. Reply with a short greeting."

    return {
        "message": str(message),
        "max_tokens": int(body.get("max_tokens", env("MAX_TOKENS", str(DEFAULT_MAX_TOKENS)))),
    }


def response(status_code: int, payload: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json",
        },
        "body": json.dumps(payload),
    }


def anthropic_body(message: str, max_tokens: int) -> str:
    return json.dumps(
        {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": message,
                        }
                    ],
                }
            ],
        }
    )


def extract_text(model_response: Dict[str, Any]) -> str:
    content = model_response.get("content", [])
    text_parts = []

    for item in content:
        if item.get("type") == "text":
            text_parts.append(item.get("text", ""))

    return "\n".join(part for part in text_parts if part)


def invoke_claude(
    message: str,
    max_tokens: int,
    *,
    guardrail_id: Optional[str] = None,
    guardrail_version: Optional[str] = None,
) -> Dict[str, Any]:
    params: Dict[str, Any] = {
        "modelId": env("MODEL_ID", DEFAULT_MODEL_ID),
        "contentType": "application/json",
        "accept": "application/json",
        "body": anthropic_body(message, max_tokens),
    }

    if guardrail_id and guardrail_version:
        params["guardrailIdentifier"] = guardrail_id
        params["guardrailVersion"] = guardrail_version
        params["trace"] = "ENABLED_FULL"

    raw_response = bedrock_runtime.invoke_model(**params)
    response_body = raw_response["body"].read().decode("utf-8")
    parsed = json.loads(response_body)

    return {
        "text": extract_text(parsed),
        "raw": parsed,
        "response_metadata": raw_response.get("ResponseMetadata", {}),
    }


def apply_guardrail(source: str, text: str) -> Dict[str, Any]:
    return bedrock_runtime.apply_guardrail(
        guardrailIdentifier=env("GUARDRAIL_ID", DEFAULT_GUARDRAIL_ID),
        guardrailVersion=env("GUARDRAIL_VERSION", DEFAULT_GUARDRAIL_VERSION),
        source=source,
        content=[
            {
                "text": {
                    "text": text,
                }
            }
        ],
    )


def guardrail_output_text(result: Dict[str, Any], fallback: str) -> str:
    outputs = result.get("outputs", [])
    if outputs and "text" in outputs[0]:
        return outputs[0]["text"]
    return fallback


def compact_guardrail_result(result: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "action": result.get("action"),
        "actionReason": result.get("actionReason"),
        "outputs": result.get("outputs", []),
        "assessments": result.get("assessments", []),
        "usage": result.get("usage", {}),
    }
