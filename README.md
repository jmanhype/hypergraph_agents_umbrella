# Hypergraph Agents Umbrella

Elixir umbrella project for distributed AI agent workflows. Includes a graph-based execution engine, A2A (Agent-to-Agent) protocol, operator system, and optional Python agent sidecars.

## What It Does

Provides an execution framework where agents communicate via a JSON-based A2A protocol, workflows are defined as directed graphs, and modular operators handle computation steps. Supports both Elixir and Python agents.

## Architecture

```
User -> Phoenix API -> XCS Engine -> Operators -> LLM
                                  -> EventBus -> Python Agents
```

## Umbrella Apps

| App | Description |
|-----|------------|
| `a2a_agent` | Core agent logic (registration, mailer) |
| `a2a_agent_web` | Phoenix API with OpenAPI spec and Swagger UI |
| `engine` | XCS workflow engine -- graph parsing, topological sort, codegen |
| `hypergraph_agent` | Orchestrator, models, sample agent implementations |
| `operator` | Operator definitions with specification/validation protocol |

## Key Concepts

| Concept | Implementation |
|---------|---------------|
| A2A Protocol | JSON messages over HTTP (`POST /api/a2a`) |
| Workflows | YAML or Elixir graph definitions, topologically sorted |
| Operators | MapOperator, SequenceOperator, LLMOperator, ParallelOperator + custom |
| Python agents | FastAPI sidecars communicating via A2A |
| Observability | Prometheus, Grafana dashboards, OTLP tracing |

## Stack

| Component | Technology |
|-----------|-----------|
| Language | Elixir 1.14+, Python 3.9+ |
| Web | Phoenix |
| Execution | Custom XCS engine |
| Communication | A2A protocol, NATS/PubSub |
| LLM | Configurable (via operators) |
| Build | Mix umbrella, Docker Compose |

## Project Structure

```
apps/
  a2a_agent/            # Core agent app
  a2a_agent_web/        # Phoenix API (OpenAPI, Swagger)
  engine/               # XCS workflow engine
  hypergraph_agent/     # Orchestrator and models
  operator/             # Operator specs
agents/
  python_agents/        # Python agent implementations
config/                 # Environment configs + Prometheus
mix.exs                 # Umbrella root
docker-compose.yml
```

## Setup

```bash
git clone https://github.com/jmanhype/hypergraph_agents_umbrella.git
cd hypergraph_agents_umbrella
mix deps.get
mix compile
mix phx.server
```

For Python agents:
```bash
cd agents/python_agents/minimal_a2a_agent
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

```bash
# Run a workflow
mix workflow.run workflows/summarize_and_analyze.yaml

# Generate an operator
mix a2a.gen.operator MyOperator

# Run tests
mix test
```

## Status

The umbrella structure is functional. CI and self-improve GitHub Actions are configured. The 100% coverage badge was a static shield, not linked to actual metrics. Multiple article draft files in the repo suggest this was also a writing/research project. Known issues include unhandled supervisor messages and OTLP exporter init failures (see FAQ.md and REPO_STATUS.md if present).

## License

MIT (see LICENSE).
