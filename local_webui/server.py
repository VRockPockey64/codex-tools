import argparse
import json
import subprocess
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


REPO_ROOT = Path(__file__).resolve().parents[1]
STATIC_DIR = Path(__file__).resolve().parent / "static"

FUNCTIONS = {
    "apply": "applyguardrail-test-lambda",
    "inline": "inline-guardrail-test-lambda",
}


class ChatHandler(BaseHTTPRequestHandler):
    server_version = "BedrockGuardrailLocalUI/0.1"

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            self.send_file(STATIC_DIR / "index.html", "text/html; charset=utf-8")
            return

        if parsed.path == "/app.js":
            self.send_file(STATIC_DIR / "app.js", "application/javascript; charset=utf-8")
            return

        if parsed.path == "/styles.css":
            self.send_file(STATIC_DIR / "styles.css", "text/css; charset=utf-8")
            return

        self.send_json(404, {"error": "Not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/api/chat":
            self.send_json(404, {"error": "Not found"})
            return

        try:
            content_length = int(self.headers.get("content-length", "0"))
            body = self.rfile.read(content_length).decode("utf-8")
            payload = json.loads(body) if body else {}
            mode = payload.get("mode", "apply")
            message = payload.get("message", "")

            if mode not in FUNCTIONS:
                self.send_json(400, {"error": f"Unknown mode: {mode}"})
                return

            if not message.strip():
                self.send_json(400, {"error": "Message is required."})
                return

            result = invoke_lambda(FUNCTIONS[mode], {"message": message})
            self.send_json(200, result)
        except Exception as exc:
            self.send_json(500, {"error": str(exc)})

    def log_message(self, format, *args):
        print("%s - %s" % (self.address_string(), format % args))

    def send_file(self, path: Path, content_type: str):
        if not path.exists():
            self.send_json(404, {"error": "File not found"})
            return

        content = path.read_bytes()
        self.send_response(200)
        self.send_header("content-type", content_type)
        self.send_header("content-length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def send_json(self, status: int, payload):
        content = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)


def invoke_lambda(function_name: str, event_payload):
    with tempfile.TemporaryDirectory(prefix="bedrock-ui-") as temp_dir:
        temp_path = Path(temp_dir)
        event_path = temp_path / "event.json"
        response_path = temp_path / "response.json"
        event_path.write_text(json.dumps(event_payload), encoding="utf-8")

        completed = subprocess.run(
            [
                "aws",
                "lambda",
                "invoke",
                "--function-name",
                function_name,
                "--payload",
                f"fileb://{event_path}",
                "--region",
                "us-east-1",
                str(response_path),
            ],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )

        if completed.returncode != 0:
            raise RuntimeError(completed.stderr.strip() or completed.stdout.strip())

        metadata = json.loads(completed.stdout) if completed.stdout.strip() else {}
        lambda_payload = json.loads(response_path.read_text(encoding="utf-8"))
        body = lambda_payload.get("body")

        if isinstance(body, str):
            try:
                lambda_payload["body"] = json.loads(body)
            except json.JSONDecodeError:
                pass

        return {
            "function": function_name,
            "invoke_metadata": metadata,
            "lambda_response": lambda_payload,
        }


def main():
    parser = argparse.ArgumentParser(description="Local web UI for Bedrock Guardrail Lambdas")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8787)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), ChatHandler)
    print(f"Local Bedrock Guardrail UI: http://{args.host}:{args.port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


if __name__ == "__main__":
    main()
