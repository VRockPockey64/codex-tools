const samples = {
  safe: "Explain AWS Lambda in two short sentences.",
  email: "My email is test@example.com. Please remember it.",
  output: "Invent a fictional helpdesk contact sentence that includes an email address.",
  emailHate: "My email is test@example.com. I hate Canadians; they are disgusting and should be excluded from society."
};

let selectedMode = "apply";

const conversation = document.querySelector("#conversation");
const form = document.querySelector("#chat-form");
const message = document.querySelector("#message");
const raw = document.querySelector("#raw");
const send = document.querySelector("#send");

document.querySelectorAll(".mode").forEach((button) => {
  button.addEventListener("click", () => {
    selectedMode = button.dataset.mode;
    document.querySelectorAll(".mode").forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
  });
});

document.querySelectorAll("[data-sample]").forEach((button) => {
  button.addEventListener("click", () => {
    message.value = samples[button.dataset.sample];
    message.focus();
  });
});

document.querySelector("#clear").addEventListener("click", () => {
  conversation.innerHTML = "";
  raw.textContent = "{}";
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const prompt = message.value.trim();
  if (!prompt) return;

  appendMessage("user", prompt);
  message.value = "";
  setBusy(true);

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ mode: selectedMode, message: prompt })
    });

    const data = await response.json();
    raw.textContent = JSON.stringify(data, null, 2);

    if (!response.ok) {
      appendMessage("bot error", data.error || "Request failed.");
      return;
    }

    const lambdaBody = data.lambda_response?.body || {};
    appendMessage("bot", lambdaBody.message || JSON.stringify(lambdaBody, null, 2));
  } catch (error) {
    appendMessage("bot error", error.message);
    raw.textContent = JSON.stringify({ error: error.message }, null, 2);
  } finally {
    setBusy(false);
  }
});

function appendMessage(kind, text) {
  const item = document.createElement("article");
  item.className = `message ${kind}`;

  const label = document.createElement("div");
  label.className = "label";
  label.textContent = kind.startsWith("user")
    ? "You"
    : selectedMode === "apply"
      ? "ApplyGuardrail Lambda"
      : "Inline Guardrail Lambda";

  const content = document.createElement("div");
  content.className = "content";
  content.textContent = text;

  item.append(label, content);
  conversation.append(item);
  conversation.scrollTop = conversation.scrollHeight;
}

function setBusy(isBusy) {
  send.disabled = isBusy;
  send.textContent = isBusy ? "Sending..." : "Send";
}
