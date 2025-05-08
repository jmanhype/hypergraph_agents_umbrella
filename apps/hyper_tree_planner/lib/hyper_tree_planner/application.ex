# apps/hyper_tree_planner/lib/hyper_tree_planner/application.ex
defmodule HyperTreePlanner.Application do
  @moduledoc """
  The HyperTreePlanner application. This module is the entry point for the application
  when it is started as part of the OTP supervision tree.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting HyperTreePlanner.Application")
    children = [
      # Define supervised processes for the HyperTreePlanner application here.
      # For example, the HyperTreePlannerAgent GenServer if it needs to be always running.
      # If the agent is started on demand (e.g., per request), it might not be listed here.
      # For now, we can start it to ensure it compiles and is part of the app.
      {HyperTreePlanner.Agents.HyperTreePlannerAgent, name: HyperTreePlanner.Agents.HyperTreePlannerAgent}
    ]

    opts = [strategy: :one_for_one, name: HyperTreePlanner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

