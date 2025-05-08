# apps/hyper_tree_planner/lib/hyper_tree_planner/operators/initialize_hypertree_operator.ex
defmodule HyperTreePlanner.Operators.InitializeHypertreeOperator do
  @moduledoc """
  Operator to initialize the Hypertree (H) with the input query (q).
  This operator implements the `H <- q` part of Algorithm 1.
  """

  alias HyperTreePlanner.DataStructures.Hypertree

  @doc """
  Initializes a new Hypertree with the given query as the root.

  Input `params` should include `{"query": q_content}`.
  Output should be `{:ok, %{"hypertree": H_initial}}` or `{:error, reason}`.
  """
  def call(params) do
    query_content = Map.get(params, "query")

    if is_nil(query_content) or not is_binary(query_content) do
      {:error, "Input 'query' is missing or not a string."}
    else
      # Hypertree.new/1 will create a root node with the query content
      initial_hypertree = Hypertree.new(query_content)
      {:ok, %{"hypertree" => initial_hypertree}}
    end
  end

  @doc """
  Returns the JSON schema for input validation for this operator.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "query" => %{"type" => "string", "description" => "The initial query to form the root of the hypertree."}
      },
      "required" => ["query"]
    }
  end

  @doc """
  Returns the JSON schema for output validation for this operator.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "hypertree" => %{
          "type" => "object", 
          "description" => "The initialized Hypertree structure."
          # Ideally, this would reference a detailed schema for the Hypertree struct
        }
      },
      "required" => ["hypertree"]
    }
  end
end

