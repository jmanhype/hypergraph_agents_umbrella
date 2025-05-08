defmodule HyperTreePlanner.DataStructures.PlanningOutline do
  @moduledoc """
  Defines the structure for a Planning Outline (O).
  This is the final output, derived from the optimal hyperchain.
  """
  alias HyperTreePlanner.DataStructures.Hyperchain

  defstruct id: nil, optimal_hyperchain: nil, details: %{}, generated_at: nil

  @type t :: %__MODULE__{
    id: String.t() | nil,
    optimal_hyperchain: Hyperchain.t() | nil,
    details: map(),
    generated_at: DateTime.t() | nil
  }

  @doc """
  Creates a new PlanningOutline.
  """
  def new(optimal_chain, details \\ %{}) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      optimal_hyperchain: optimal_chain,
      details: details,
      generated_at: DateTime.utc_now()
    }
  end
end

