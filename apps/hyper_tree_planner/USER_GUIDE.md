"""
# HyperTree Planner User Guide

This guide provides instructions on how to use the HyperTree Planner application, which implements the Top-down HyperTree Construction algorithm within the Hypergraph Agents Umbrella framework.

## Overview

The HyperTree Planner agent is designed to take a set of rules (`R`) and a query (`q`) as input, and produce a planning outline (`O`) by constructing and evaluating a hypertree. It leverages Large Language Models (LLMs) for various reasoning steps within the planning process.

## Prerequisites

Before using the HyperTree Planner, ensure that:

1.  The Hypergraph Agents Umbrella framework is correctly set up and running.
2.  The `hyper_tree_planner` application is correctly installed within the `apps/` directory of the umbrella project.
3.  An LLM service is configured and accessible by the `LLMOperator` in the umbrella framework. The `HyperTreePlannerAgent` relies on this operator for its core logic.
4.  The necessary Elixir and Erlang versions are installed (Elixir ~> 1.17, Erlang/OTP ~> 26).

## Input Format

The HyperTree Planner agent is typically invoked via an Asynchronous Agent-to-Agent (A2A) task request. The `params` for this task request should be a JSON object containing the following keys:

*   `rules` (string or list of strings): The set of rules `R` that guide the planning process. The exact format of these rules will depend on how your `RuleConverterOperator` and LLM prompts are designed to interpret them.
*   `query` (string): The initial query `q` or problem statement that the planner needs to address.
*   `depth` (integer): The maximum reasoning depth `K` for the hypertree construction.
*   `width` (integer): The expansion width `W`, limiting the number of hyperchains explored at each depth.
*   `llm_config` (object, optional): Specific configurations for the LLM calls, if needed (e.g., model name, temperature). This might be handled by the global `LLMOperator` configuration as well.

**Example Task Request Parameters (JSON):**

```json
{
  "rules": [
    "Rule 1: If X is a goal, and Y is a prerequisite for X, then consider Y.",
    "Rule 2: If Y is a task, break it down into sub-tasks Z1, Z2."
  ],
  "query": "Achieve goal X",
  "depth": 3,
  "width": 5,
  "llm_config": {
    "model": "gpt-4"
  }
}
```

## How to Run

1.  **Start the Hypergraph Agents Umbrella application:** This usually involves running `mix phx.server` or a similar command from the root of the umbrella project, depending on its setup.
2.  **Send an A2A Task Request:** Another agent or an external system needs to send an A2A `task_request` to the `HyperTreePlannerAgent`. The `agent_id` for the planner agent would typically be defined in its configuration or discoverable through the framework's service discovery mechanism.
    *   The `task_type` in the A2A request should correspond to the task the `HyperTreePlannerAgent` is registered to handle (e.g., `"hyper_tree_plan"`).
    *   The `params` should be the JSON object described in the "Input Format" section.

## Expected Output

Upon successful completion, the `HyperTreePlannerAgent` will respond with an A2A `result` message. The payload of this result will contain the Planning Outline `O`.

The Planning Outline `O` is derived from the optimal hyperchain `C*` selected by the LLM at the end of the planning process. The exact structure of `O` will depend on how it's formulated from `C*`, but it generally represents a sequence of steps or a structured plan to address the initial query `q` based on the rules `R`.

**Example Result Payload (JSON):**

```json
{
  "planning_outline": {
    "summary": "Optimal plan to achieve goal X",
    "steps": [
      "Address prerequisite Y.",
      "Perform sub-task Z1.",
      "Perform sub-task Z2."
    ],
    "confidence_score": 0.85, // Example field
    "reasoning_trace": ["...details of C*..."] // Example field
  }
}
```

(Note: The actual fields in `planning_outline` will be determined by the implementation of the `PlanningOutline` data structure and how the `LLMOperator` is prompted to generate it from `C*`.)

## Troubleshooting

*   **Compilation Errors:** Ensure Elixir and Erlang versions are compatible and all dependencies are fetched (`mix deps.get`) and compiled (`mix compile`) from the root of the umbrella project.
*   **LLM Errors:** Check the logs of the `LLMOperator` and the `HyperTreePlannerAgent` for any errors related to LLM API calls. Ensure API keys are correct and the LLM service is reachable.
*   **Incorrect Output:**
    *   Review the input `rules` and `query` for clarity and correctness.
    *   Examine the prompt templates used by the `HyperTreePlannerAgent` for each LLM interaction. They might need refinement.
    *   Check the agent's logs for details on the intermediate steps of the hypertree construction.

## Customization

*   **Rules (`R`):** The effectiveness of the planner heavily depends on the quality and expressiveness of the rules provided.
*   **Prompts:** The LLM prompts within `HyperTreePlannerAgent.ex` can be customized to tailor the reasoning process and the format of the output.
*   **Operators:** The behavior of `RuleConverterOperator`, `InitializeHypertreeOperator`, `HyperchainExtractorOperator`, and `NodeAttacherOperator` can be modified if different internal logic for these steps is required.

This user guide provides a basic understanding of how to use the HyperTree Planner. For more detailed information on the internal workings, please refer to the source code and the `README.md` in the `apps/hyper_tree_planner/` directory.
"""
