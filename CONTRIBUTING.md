# Contributing to Hypergraph Agents

Thank you for your interest in contributing to Hypergraph Agents! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

- **Elixir**: Version 1.16+ with OTP 26.2+
- **Python**: Version 3.11+
- **Docker**: For running services (NATS, etc.)
- **Git**: For version control

### Setting Up Your Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jmanhype/hypergraph_agents_umbrella.git
   cd hypergraph_agents_umbrella
   ```

2. **Install Elixir dependencies:**
   ```bash
   cd apps/a2a_agent_web
   mix deps.get
   ```

3. **Install Python dependencies:**
   ```bash
   cd agents/python_agents/minimal_a2a_agent
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

4. **Start services:**
   ```bash
   make up
   ```

## Development Workflow

1. **Create a new branch** for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the [Code Standards](#code-standards)

3. **Run tests** to ensure your changes don't break existing functionality:
   ```bash
   make test
   ```

4. **Run linting** to ensure code quality:
   ```bash
   make lint
   ```

5. **Commit your changes** with clear, descriptive commit messages:
   ```bash
   git add .
   git commit -m "Add feature: clear description of what changed"
   ```

6. **Push to your fork** and create a Pull Request

## Code Standards

### Elixir

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` to format your code before committing
- Add `@moduledoc` and `@doc` documentation for all public modules and functions
- Use `@spec` type specifications for all public functions
- Keep functions small and focused on a single responsibility

Example:
```elixir
defmodule MyModule do
  @moduledoc """
  Brief description of what this module does.
  """

  @doc """
  Description of what this function does.

  ## Examples

      iex> MyModule.my_function("input")
      "output"
  """
  @spec my_function(String.t()) :: String.t()
  def my_function(input) do
    # Implementation
  end
end
```

### Python

- Follow [PEP 8](https://pep8.org/) style guidelines
- Use type hints for all function parameters and return values
- Use docstrings for all modules, classes, and functions
- Use `ruff` for linting (configured in the project)
- Keep functions focused and modular

Example:
```python
from typing import Dict, Any

def my_function(param: str) -> Dict[str, Any]:
    """
    Brief description of what this function does.

    Args:
        param: Description of the parameter

    Returns:
        Description of the return value

    Raises:
        ValueError: When something goes wrong
    """
    # Implementation
    return {"result": param}
```

### General Guidelines

- **Write clear, self-documenting code** with meaningful variable and function names
- **Add comments** only when the code's intent isn't immediately clear
- **Handle errors gracefully** with appropriate error messages
- **Keep changes focused** - one feature or fix per PR
- **Avoid breaking changes** to public APIs without discussion
- **Add tests** for new features and bug fixes

## Testing

### Elixir Tests

```bash
cd apps/a2a_agent_web
mix test
```

Run with coverage:
```bash
mix test --cover
```

### Python Tests

```bash
cd agents/python_agents/minimal_a2a_agent
source .venv/bin/activate
pytest
```

Run with coverage:
```bash
pytest --cov=app --cov-report=html
```

### All Tests

```bash
make test
```

## Pull Request Process

1. **Ensure all tests pass** before submitting
2. **Update documentation** if you've changed functionality
3. **Add tests** for new features or bug fixes
4. **Follow the PR template** (if available)
5. **Reference related issues** in your PR description
6. **Request review** from maintainers

### PR Title Format

Use clear, descriptive titles:
- `feat: Add new feature X`
- `fix: Resolve bug in Y`
- `docs: Update README with Z`
- `refactor: Improve code structure in W`
- `test: Add tests for V`

### PR Description

Include:
- **Summary**: What does this PR do?
- **Motivation**: Why is this change needed?
- **Changes**: What specific changes were made?
- **Testing**: How was this tested?
- **Related Issues**: Link to related issues

## Project Structure

```
hypergraph_agents_umbrella/
├── agents/
│   └── python_agents/
│       └── minimal_a2a_agent/     # Python A2A agent
├── apps/
│   ├── a2a_agent_web/             # Elixir Phoenix API
│   ├── engine/                    # Workflow engine
│   ├── operator/                  # Operators
│   └── hypergraph_agent/          # Core agent logic
├── config/                        # Configuration files
├── docs/                          # Documentation
├── .github/workflows/             # CI/CD workflows
├── Makefile                       # Common development tasks
├── docker-compose.yml             # Docker services
└── README.md                      # Project overview
```

## Questions?

If you have questions or need help:
- Open an issue for bugs or feature requests
- Check existing issues and discussions
- Reach out to the maintainers

## License

By contributing to Hypergraph Agents, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Hypergraph Agents! 🚀
