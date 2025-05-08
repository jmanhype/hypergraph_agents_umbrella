# HyperTreePlanner Application

## Purpose

The `HyperTreePlanner` is an Elixir application designed to implement the "Top-down HyperTree Construction" algorithm (Algorithm 1 from the conceptual documentation). Its primary purpose is to generate a structured planning outline by iteratively building and refining a hypertree based on a set of input rules, an initial query, and interactions with a Large Language Model (LLM).

This application is a component of the broader Hypergraph Agents Umbrella project and leverages its core functionalities where applicable.

## Core Components

The `HyperTreePlanner` application consists of several key components:

1.  **Data Structures (`lib/hyper_tree_planner/data_structures/`)**:
    *   `Hypertree.ex`: Defines the structure for the hypertree `H`, which includes nodes and hyperedges. It represents the evolving plan.
    *   `Hyperchain.ex`: Defines the structure for a hyperchain `C`, representing a path or sequence within the hypertree.
    *   `DivisibleSet.ex`: Defines the structure for the divisible set `D`, derived from the input rules `R`.
    *   `PlanningOutline.ex`: Defines the structure for the final output `O`, which is a plan derived from the optimal hyperchain `C*`.

2.  **Operators (`lib/hyper_tree_planner/operators/`)**:
    These are Elixir modules that implement specific, self-contained operations of Algorithm 1. They are designed to be called by the main agent.
    *   `RuleConverterOperator.ex`: Converts the input rules `R` into the divisible set `D`.
    *   `InitializeHypertreeOperator.ex`: Creates the initial hypertree `H` from the input query `q`.
    *   `HyperchainExtractorOperator.ex`: Extracts hyperchains `{C1,...,Cm}` from the current hypertree `H`.
    *   `NodeAttacherOperator.ex`: Attaches newly expanded nodes `{si_p}` to the hypertree `H` under a parent node `gi*`.

3.  **Agent (`lib/hyper_tree_planner/agents/`)**:
    *   `HyperTreePlannerAgent.ex`: This is the central orchestrator of the algorithm. It is implemented as an Elixir GenServer and manages the overall planning process. It:
        *   Initializes and maintains the state of the planning (current hypertree, rules, query, depth, width, LLM cache).
        *   Executes the main planning loop as defined in Algorithm 1.
        *   Calls the various operators to perform specific tasks.
        *   Interacts with a (currently mocked) `LLMService` for steps requiring AI inference (e.g., filtering chains, selecting nodes, retrieving rules, expanding nodes).
        *   Implements caching for LLM requests and parallelizes certain LLM calls for performance.

4.  **Mock LLM Service (`lib/hyper_tree_planner/agents/hyper_tree_planner_agent.ex#LLMService`)**:
    *   A nested module within `HyperTreePlannerAgent.ex` that simulates responses from an LLM. This is used for development and testing without requiring actual LLM API calls. In a production setup, this would be replaced by integration with the Hypergraph Agents Umbrella framework's actual `LLMOperator` or a similar service.

## Algorithm Flow and Interactions

The `HyperTreePlannerAgent` executes Algorithm 1 as follows:

1.  **Initialization**:
    *   Receives input parameters: rules `R`, query `q`, reasoning depth `K`, and expansion width `W`.
    *   Uses `RuleConverterOperator` to transform `R` into the divisible set `D`.
    *   Uses `InitializeHypertreeOperator` to create the initial hypertree `H` based on `q`.

2.  **Iterative Planning Loop (K iterations)**:
    For each depth level `d` from 1 to `K`:
    a.  **Extract Hyperchains**: Calls `HyperchainExtractorOperator` to get all hyperchains `{C1,...,Cm}` from the current `H`.
    b.  **Filter Hyperchains**: If the number of chains `m` exceeds `W`, it calls the `LLMService` to filter them down to the `W` most promising ones.
    c.  **Process Selected Hyperchains**: For each selected hyperchain `Ci` (up to `W` chains):
        i.  **Extract Divisible Nodes**: Calls `LLMService` to identify divisible nodes `{g1,...,gni}` from `D` relevant to `Ci`.
        ii. **Select Promising Node**: Calls `LLMService` to select the most promising node `gi*` from these divisible nodes.
        iii. **Retrieve Relevant Rules**: Calls `LLMService` to get relevant rules `{r1,...,rP}` from the original `R` based on `gi*`.
        iv. **Expand Node with Rules**: For each rule `rp`:
            *   Calls `LLMService` to generate expanded nodes `{si_p}` based on `q`, `Ci`, `gi*`, and `rp`. (These LLM calls are parallelized using `Task.async_stream`).
            *   Calls `NodeAttacherOperator` to attach these new nodes `{si_p}` to `H` under `gi*`.

3.  **Select Optimal Hyperchain**:
    *   After `K` iterations, calls `LLMService` to select the optimal hyperchain `C*` from the final, expanded `H`.

4.  **Generate Planning Outline**:
    *   Constructs a `PlanningOutline` struct from `C*` and returns it as the result.

## Integration with Hypergraph Agents Umbrella Framework

The `HyperTreePlanner` is designed as an application within the Hypergraph Agents Umbrella project. This means:

*   It resides in the `apps/hyper_tree_planner/` directory of the umbrella project.
*   It has its own `mix.exs` file defining its dependencies and application configuration.
*   The `HyperTreePlannerAgent` would typically be started and supervised as part of the umbrella application's supervision tree.
*   Interactions with other agents or services within the umbrella (like a real `LLMOperator`) would occur via the framework's A2A (Agent-to-Agent) communication mechanisms, though this is currently simplified with a direct mock `LLMService` call within the agent for development purposes.

## Basic Usage

1.  **Start the Agent**:
    The `HyperTreePlannerAgent` is a GenServer and needs to be started. You can start it and give it a name:
    ```elixir
    {:ok, pid} = HyperTreePlanner.Agents.HyperTreePlannerAgent.start_link(name: MyPlanner)
    ```

2.  **Initiate Planning**:
    Call the `plan_hyper_tree/2` function with the agent's PID (or registered name) and the required parameters:
    ```elixir
    params = %{
      "rules" => [%{id: "rule1", content: "If condition X, then action Y"}, ...],
      "query" => "Achieve high-level goal Z",
      "k_depth" => 3,  # Reasoning depth
      "w_width" => 2   # Expansion width
    }

    case HyperTreePlanner.Agents.HyperTreePlannerAgent.plan_hyper_tree(MyPlanner, params) do
      {:ok, planning_outline} ->
        IO.inspect(planning_outline, label: "Generated Planning Outline")
      {:error, reason} ->
        IO.puts "Planning failed: #{reason}"
    end
    ```

This will trigger the algorithm, and upon completion, return either `{:ok, planning_outline_struct}` or `{:error, reason}`.

---
*This README provides a high-level overview. For detailed information on specific functions, parameters, and data structures, please refer to the `@moduledoc` and `@doc` annotations within the Elixir source code files.*

