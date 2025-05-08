defmodule HyperTreePlanner.DataStructures.DivisibleSet do
  @moduledoc """
  Defines the structure for a Divisible Set (D).

  This set contains items derived from rules that can be used for expansion
  during the hyper_tree_planner planning process. Each item in the set typically represents
  a component or a condition that can be matched or utilized by the LLM
  to guide the expansion of the hypertree.

  The `RuleConverterOperator` is responsible for processing the initial set of rules
  and populating this DivisibleSet.
  """
  defstruct id: nil, items: [], metadata: %{}

  @typedoc """
  Represents the DivisibleSet structure.

  - `id`: A unique identifier for this DivisibleSet instance (typically a UUID).
  - `items`: A list of maps, where each map represents a divisible part of a rule
    or a condition. The exact structure of these maps can be flexible but should
    be consistently interpretable by the LLM prompts that use this set.
  - `metadata`: A map for storing additional information, such as creation timestamp
    or source of the rules.
  """
  @type t :: %__MODULE__{
    id: String.t() | nil,
    items: list(map()), 
    metadata: map()
  }

  @doc """
  Creates a new DivisibleSet.

  An ID is automatically generated for the set. The `items` list should contain
  the processed, divisible components derived from the input rules.

  ## Parameters

    - `items`: A list of maps, where each map is a divisible component.
    - `metadata`: (Optional) A map for additional information. Defaults to an empty map,
      with a `created_at` timestamp automatically added.

  ## Examples

      iex> items = [%{condition: "A > B", action: "C"}, %{premise: "X", conclusion: "Y"}]
      iex> ds = HyperTreePlanner.DataStructures.DivisibleSet.new(items, %{source: "ruleset_v1"})
      iex> ds.items
      [%{condition: "A > B", action: "C"}, %{premise: "X", conclusion: "Y"}]
      iex> ds.id != nil
      true
      iex> ds.metadata[:source]
      "ruleset_v1"
      iex> ds.metadata[:created_at] != nil
      true
  """
  def new(items, metadata \\ %{}) when is_list(items) and is_map(metadata) do
    %__MODULE__{
      id: Ecto.UUID.generate(), 
      items: items,
      metadata: Map.put(metadata, :created_at, DateTime.utc_now())
    }
  end

  @doc """
  Adds a new item to the DivisibleSet.

  ## Parameters

    - `divisible_set`: The `DivisibleSet` struct to modify.
    - `item`: The new item (a map) to add to the `items` list.

  ## Examples

      iex> ds = HyperTreePlanner.DataStructures.DivisibleSet.new([%{id: "item1"}])
      iex> ds = HyperTreePlanner.DataStructures.DivisibleSet.add_item(ds, %{id: "item2"})
      iex> Enum.count(ds.items)
      2
  """
  def add_item(%__MODULE__{items: current_items} = divisible_set, item) when is_map(item) do
    %{divisible_set | items: [item | current_items]}
  end

  @doc """
  Retrieves all items from the DivisibleSet.

  ## Parameters

    - `divisible_set`: The `DivisibleSet` struct.

  ## Examples

      iex> items_list = [%{id: "item1"}]
      iex> ds = HyperTreePlanner.DataStructures.DivisibleSet.new(items_list)
      iex> HyperTreePlanner.DataStructures.DivisibleSet.get_items(ds)
      [%{id: "item1"}]
  """
  def get_items(%__MODULE__{items: current_items}) do
    current_items
  end
end

