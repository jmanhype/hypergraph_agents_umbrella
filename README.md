# ⚡️ Hypergraph Agents: Build Viral AI Workflows

[![CI](https://img.shields.io/github/actions/workflow/status/jmanhype/hypergraph_agents_umbrella/ci.yml?style=flat-square)](https://github.com/jmanhype/hypergraph_agents_umbrella/actions)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen?style=flat-square)](#)
[![Docs](https://img.shields.io/badge/docs-hexdocs.io-blue?style=flat-square)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> **Multi-language, high-performance agentic AI framework for viral, distributed workflows.**

---

## 🚀 Why Hypergraph Agents?

- **Plug & Play AI:** Instantly connect Elixir & Python agents.
- **Workflow DSL:** Write, run, remix—YAML or Elixir, your call.
- **A2A Protocol:** Agents talk, negotiate, and collaborate.
- **Event Streaming:** Real-time, distributed, and fast (NATS, PubSub).
- **Observability:** Metrics, logs, dashboards—built in.
- **Zero-BS Onboarding:** Clone, run, remix. Done.

---

## 🏁 60-Second Quick Start

```sh
git clone https://github.com/jmanhype/hypergraph_agents_umbrella.git
cd hypergraph_agents_umbrella
make up   # Or: docker compose up --build
```

- Elixir API: http://localhost:4000
- Python Agent: http://localhost:5001
- Metrics: http://localhost:4000/metrics

---

## 🧩 Remixable Workflows

- **YAML or Elixir:**
  - `workflows/summarize_and_analyze.yaml`
  - `workflows/summarize_and_analyze.exs`
- **Generate your own:**
  - `mix a2a.gen.workflow my_workflow`
- **Run it:**
  - `mix workflow.run workflows/summarize_and_analyze.yaml`

---

## ⚙️ Operators: Add Your Own AI

- **Generate a new operator:**
  ```sh
  mix a2a.gen.operator ViralOperator
  ```
- **Drop in your logic:**
  - `lib/a2a_agent_web_web/operators/viral_operator.ex`
- **Test it:**
  - `mix test`

---

## 🌐 Agents Talk (A2A Protocol)

```json
{
  "type": "task_request",
  "sender": "agent1",
  "recipient": "agent2",
  "payload": { "graph": { "nodes": [], "edges": [] } }
}
```
- `POST /api/a2a` — Send messages, trigger workflows, negotiate.
- Works across Elixir, Python, and beyond.

---

## 🛠️ Dev Experience

- **Makefile Shortcuts:** `make up`, `make test`, `make lint`
- **Live reload:** Phoenix & FastAPI
- **OpenAPI docs:** [openapi.yaml](apps/a2a_agent_web/openapi.yaml)
- **All code is type-annotated & documented**

---

## 🧪 Example: Run a Workflow (Python)

```python
import httpx
msg = {
    "type": "task_request",
    "sender": "pyagent1",
    "recipient": "agent1",
    "payload": {"task_id": "t1", "stream": True}
}
r = httpx.post("http://localhost:4000/api/a2a", json=msg)
print(r.json())
```

---

## 🤝 Contribute & Remix

- Fork, branch, PR—let’s build viral AI together
- All tests must pass (`make test`, `mix test`, `pytest`)
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) and `.ai/rules/python-dev.md`

---

## 📚 Learn More

- [A2A Protocol](apps/a2a_agent_web/README.md#a2a-protocol-message-schema)
- [Operator Library](apps/operator/README.md)
- [Minimal Python Agent](agents/python_agents/minimal_a2a_agent/README.md)
- [Engine & Workflow DSL](apps/engine/README.md)

---

## 🦾 Viral AI Starts Here

Unleash distributed, agentic intelligence. Remix, extend, and connect your own operators, workflows, and agents—across any language.

---

MIT License | Built with Elixir, Python, and love.
