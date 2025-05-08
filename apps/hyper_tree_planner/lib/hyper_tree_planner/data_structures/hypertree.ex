defmodule HyperTreePlanner.DataStructures.Hypertree do
  @moduledoc """
  Represents a hypertree structure for the planning process.

  A hypertree consists of nodes and hyperedges. Nodes can be of different types
  (e.g., goal, subgoal, action) and hyperedges connect a set of source nodes
  to a set of target nodes.

  This initial implementation focuses on a simple map-based representation for nodes
  and a list of hyperedges. Each hyperedge will also be a map specifying its
  source_nodes (list of IDs) and target_nodes (list of IDs).
  """

  defstruct nodes: %{}, hyperedges: [], metadata: %{}

  @doc """
  Creates a new, empty Hypertree.

  ## Examples

      iex> HyperTreePlanner.DataStructures.Hypertree.new()
      %HyperTreePlanner.DataStructures.Hypertree{nodes: %{}, hyperedges: [], metadata: %{}}
  """
  def new() do
    %__MODULE__{nodes: %{}, hyperedges: [], metadata: %{}}
  end

  @doc """
  Adds a node to the hypertree.

  If a node with the same ID already exists, it will be overwritten.

  ## Parameters

    - `hypertree`: The hypertree to add the node to.
    - `node_id`: The unique identifier for the node.
    - `node_data`: A map containing the node's attributes (e.g., content, type).

  ## Examples

      iex> h = HyperTreePlanner.DataStructures.Hypertree.new()
      iex> h = HyperTreePlanner.DataStructures.Hypertree.add_node(h, "goal1", %{content: "Achieve X", type: :goal})
      iex> h.nodes["goal1"]
      %{content: "Achieve X", type: :goal}
  """
  def add_node(%__MODULE__{nodes: nodes} = hypertree, node_id, node_data) when is_binary(node_id) and is_map(node_data) do
    %{hypertree | nodes: Map.put(nodes, node_id, node_data)}
  end

  @doc """
  Adds a hyperedge to the hypertree.

  A hyperedge connects a list of source node IDs to a list of target node IDs.

  ## Parameters

    - `hypertree`: The hypertree to add the hyperedge to.
    - `source_node_ids`: A list of IDs for the source nodes.
    - `target_node_ids`: A list of IDs for the target nodes.
    - `edge_data`: (Optional) A map containing metadata for the hyperedge. Defaults to an empty map.

  ## Examples

      iex> h = HyperTreePlanner.DataStructures.Hypertree.new()
      iex> h = HyperTreePlanner.DataStructures.Hypertree.add_node(h, "n1", %{})
      iex> h = HyperTreePlanner.DataStructures.Hypertree.add_node(h, "n2", %{})
      iex> h = HyperTreePlanner.DataStructures.Hypertree.add_node(h, "n3", %{})
      iex> h = HyperTreePlanner.DataStructures.Hypertree.add_hyperedge(h, ["n1"], ["n2", "n3"], %{type: :dependency})
      iex> hd(h.hyperedges)
      %{source_nodes: ["n1"], target_nodes: ["n2", "n3"], data: %{type: :dependency}}
  """
  def add_hyperedge(%__MODULE__{hyperedges: hyperedges} = hypertree, source_node_ids, target_node_ids, edge_data \\ %{}) 
    when is_list(source_node_ids) and is_list(target_node_ids) and is_map(edge_data) do
    new_edge = %{source_nodes: source_node_ids, target_nodes: target_node_ids, data: edge_data}
    %{hypertree | hyperedges: [new_edge | hyperedges]}
  end

  # Further functions can be added for querying, traversal, etc.
end

