defmodule HyperTreePlanner.DataStructures.Hyperchain do
  @moduledoc """
  Represents a hyperchain within a hypertree.

  A hyperchain is an ordered sequence of nodes and/or hyperedges that represents
  a specific path or reasoning trace through the hypertree. It is a key element
  for evaluating different planning possibilities.

  This structure will hold a list of elements (which can be node IDs or more complex
  structs representing steps in the chain) and associated metadata.
  """

  defstruct id: nil, elements: [], metadata: %{}

  @doc """
  Creates a new Hyperchain.

  An ID can be optionally provided; otherwise, a UUID will be generated.

  ## Parameters
    - `elements`: A list representing the ordered components of the hyperchain.
    - `metadata`: (Optional) A map for additional information about the hyperchain.
    - `id`: (Optional) A unique identifier for the hyperchain. If nil, a UUID is generated.

  ## Examples

      iex> hc1 = HyperTreePlanner.DataStructures.Hyperchain.new(["node1", "node2"], %{cost: 10})
      iex> hc1.elements
      ["node1", "node2"]
      iex> hc1.metadata
      %{cost: 10}
      iex> hc1.id != nil
      true

      iex> hc2 = HyperTreePlanner.DataStructures.Hyperchain.new([], %{}, "my-custom-id")
      iex> hc2.id
      "my-custom-id"
  """
  def new(elements, metadata \\ %{}, id \\ nil) when is_list(elements) and is_map(metadata) do
    chain_id = if is_nil(id), do: Ecto.UUID.generate(), else: id
    %__MODULE__{id: chain_id, elements: elements, metadata: metadata}
  end

  @doc """
  Appends an element to the hyperchain.

  ## Parameters
    - `hyperchain`: The hyperchain to append to.
    - `element`: The element to add to the end of the chain.

  ## Examples
      iex> hc = HyperTreePlanner.DataStructures.Hyperchain.new(["a"])
      iex> hc = HyperTreePlanner.DataStructures.Hyperchain.append_element(hc, "b")
      iex> hc.elements
      ["a", "b"]
  """
  def append_element(%__MODULE__{elements: elements} = hyperchain, element) do
    %{hyperchain | elements: elements ++ [element]}
  end

  # Further functions can be added for chain manipulation, comparison, etc.
end

