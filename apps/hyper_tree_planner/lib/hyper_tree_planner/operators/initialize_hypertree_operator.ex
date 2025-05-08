defmodule HyperTreePlanner.Operators.InitializeHypertreeOperator do
  @moduledoc """
  Operator responsible for initializing a new Hypertree (H) with the input query (q).

  This operator effectively performs the `H <- q` step from Algorithm 1 of the
  Top-down HyperTree Construction process. It creates an empty hypertree and then
  adds the provided query content as the initial, typically root, node of this hypertree.
  """

  alias HyperTreePlanner.DataStructures.Hypertree

  @doc """
  Initializes a new `HyperTreePlanner.DataStructures.Hypertree` with the given query content
  as its first node.

  The input `params` map is expected to contain a `"query"` key, where the value
  is a string representing the initial query or goal.

  The operator will:
  1. Create a new, empty `Hypertree`.
  2. Add the `query_content` as a node to this hypertree. A default node ID (e.g., "initial_query")
     and type (e.g., `:goal_query`) will be assigned to this initial node.

  Returns `{:ok, %{"hypertree" => initial_hypertree_struct}}` on success, or
  `{:error, reason_string}` if the input `"query"` is missing or not a string.

  ## Parameters

    - `params`: A map containing the input parameters. Expected to have a `"query"` key
      with a string value.

  ## Examples

      iex> params = %{"query" => "Plan a trip to Mars"}
      iex> {:ok, result} = HyperTreePlanner.Operators.InitializeHypertreeOperator.call(params)
      iex> initial_hypertree = result["hypertree"]
      iex> is_struct(initial_hypertree, HyperTreePlanner.DataStructures.Hypertree)
      true
      iex> initial_hypertree.nodes["initial_query"]
      %{content: "Plan a trip to Mars", type: :goal_query, id: "initial_query"}
      iex> Enum.empty?(initial_hypertree.hyperedges)
      true

      iex> HyperTreePlanner.Operators.InitializeHypertreeOperator.call(%{})
      {:error, "Input 'query' is missing or not a string."}

      iex> HyperTreePlanner.Operators.InitializeHypertreeOperator.call(%{"query" => 123})
      {:error, "Input 'query' is missing or not a string."}
  """
  def call(params) do
    query_content = Map.get(params, "query")

    if is_nil(query_content) or not is_binary(query_content) do
      {:error, "Input 'query' is missing or not a string."}
    else
      initial_node_id = "initial_query" # Or Ecto.UUID.generate()
      node_data = %{content: query_content, type: :goal_query, id: initial_node_id}
      
      empty_hypertree = Hypertree.new()
      initial_hypertree_struct = Hypertree.add_node(empty_hypertree, initial_node_id, node_data)
      
      {:ok, %{"hypertree" => initial_hypertree_struct}}
    end
  end

  @doc """
  Returns the JSON schema specification for the input parameters of this operator.

  This schema defines that the input must be an object with a required `"query"` property,
  which should be a string representing the initial query or goal.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "query" => %{
          "type" => "string", 
          "description" => "The initial query text to form the root/starting point of the hypertree."
        }
      },
      "required" => ["query"]
    }
  end

  @doc """
  Returns the JSON schema specification for the output produced by this operator.

  This schema defines that the output will be an object with a required `"hypertree"` property.
  The value of `"hypertree"` should be an object representing the initialized
  `HyperTreePlanner.DataStructures.Hypertree` struct.
  A more detailed schema for the Hypertree struct itself would ideally be referenced here.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "hypertree" => %{
          "type" => "object", 
          "description" => "The newly initialized Hypertree structure containing the query as its first node."
          # Ideally, this would reference a detailed schema for the Hypertree struct,
          # including its 'nodes' and 'hyperedges' properties.
        }
      },
      "required" => ["hypertree"]
    }
  end
end

