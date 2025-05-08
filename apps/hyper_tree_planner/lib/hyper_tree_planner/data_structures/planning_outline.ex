defmodule HyperTreePlanner.DataStructures.PlanningOutline do
  @moduledoc """
  Defines the structure for a Planning Outline (O).

  This is the final output of the HyperTreePlannerAgent, representing the
  culmination of the planning process. It encapsulates the selected optimal
  hyperchain and any relevant details about its generation.
  """
  alias HyperTreePlanner.DataStructures.Hyperchain

  defstruct id: nil, optimal_hyperchain: nil, details: %{}, generated_at: nil

  @typedoc """
  Represents the PlanningOutline structure.

  - `id`: A unique identifier for this PlanningOutline instance (typically a UUID).
  - `optimal_hyperchain`: The `HyperTreePlanner.DataStructures.Hyperchain.t()` struct
    that was selected as the best plan by the LLM from the final hypertree.
  - `details`: A map for storing additional information about the planning process
    or the outline itself (e.g., generation parameters, confidence scores).
  - `generated_at`: A `DateTime.t()` indicating when this planning outline was created.
  """
  @type t :: %__MODULE__{
    id: String.t() | nil,
    optimal_hyperchain: Hyperchain.t() | nil,
    details: map(),
    generated_at: DateTime.t() | nil
  }

  @doc """
  Creates a new PlanningOutline.

  An ID and `generated_at` timestamp are automatically assigned.

  ## Parameters

    - `optimal_chain`: The `HyperTreePlanner.DataStructures.Hyperchain.t()` struct representing
      the chosen plan.
    - `details`: (Optional) A map for additional information about the outline or its generation.
      Defaults to an empty map.

  ## Examples

      iex> chain = HyperTreePlanner.DataStructures.Hyperchain.new(["step1", "step2"], %{cost: 5})
      iex> outline = HyperTreePlanner.DataStructures.PlanningOutline.new(chain, %{source_query: "plan my day"})
      iex> outline.optimal_hyperchain == chain
      true
      iex> outline.details[:source_query]
      "plan my day"
      iex> outline.id != nil
      true
      iex> outline.generated_at != nil
      true
  """
  def new(optimal_chain, details \\ %{}) when is_struct(optimal_chain, HyperTreePlanner.DataStructures.Hyperchain) and is_map(details) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      optimal_hyperchain: optimal_chain,
      details: details,
      generated_at: DateTime.utc_now()
    }
  end

  @doc """
  Retrieves the optimal hyperchain from the PlanningOutline.

  ## Parameters

    - `planning_outline`: The `PlanningOutline` struct.

  ## Examples

      iex> chain = HyperTreePlanner.DataStructures.Hyperchain.new([], %{})
      iex> outline = HyperTreePlanner.DataStructures.PlanningOutline.new(chain)
      iex> HyperTreePlanner.DataStructures.PlanningOutline.get_optimal_chain(outline) == chain
      true
  """
  def get_optimal_chain(%__MODULE__{optimal_hyperchain: chain}) do
    chain
  end

  @doc """
  Retrieves the generation details from the PlanningOutline.

  ## Parameters

    - `planning_outline`: The `PlanningOutline` struct.

  ## Examples

      iex> details_map = %{user: "test"}
      iex> chain = HyperTreePlanner.DataStructures.Hyperchain.new([], %{})
      iex> outline = HyperTreePlanner.DataStructures.PlanningOutline.new(chain, details_map)
      iex> HyperTreePlanner.DataStructures.PlanningOutline.get_details(outline)
      %{user: "test"}
  """
  def get_details(%__MODULE__{details: details_map}) do
    details_map
  end
end

