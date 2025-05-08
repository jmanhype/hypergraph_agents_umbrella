# apps/hyper_tree_planner/mix.exs
defmodule HyperTreePlanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :hyper_tree_planner,
      version: "0.1.0",
      elixir: "~> 1.12", # Match Elixir version installed or a compatible one
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # For umbrella projects, this app is typically compiled within the umbrella context
      compilers: Mix.compilers(), # Ensure this is present for umbrella children
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ecto], # ecto for Ecto.UUID
      mod: {HyperTreePlanner.Application, []} # Points to the application callback module
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"} # For Ecto.UUID and potentially other utilities
      # Add other dependencies here if needed, e.g., for JSON parsing if LLM responses are JSON
      # {:jason, "~> 1.2"} # Example if JSON parsing is needed directly
    ]
  end
end

