defmodule HyperTreePlanner.DataStructures.DivisibleSet do
  @moduledoc """
  Defines the structure for a Divisible Set (D).
  This set contains items derived from rules that can be used for expansion.
  """
  defstruct id: nil, items: [], metadata: %{}

  @type t :: %__MODULE__{
    id: String.t() | nil,
    items: list(map()), # Each item could be a map representing a divisible part of a rule
    metadata: map()
  }

  @doc """
  Creates a new DivisibleSet.
  """
  def new(items, metadata \\ %{}) do
    %__MODULE__{
      id: Ecto.UUID.generate(), # Generate a unique ID for the set
      items: items,
      metadata: Map.put(metadata, :created_at, DateTime.utc_now())
    }
  end
end

