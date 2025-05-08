defmodule HyperTreePlanner.Operators.RuleConverterOperator do
  @moduledoc """
  Operator to convert input rules (R) into a Divisible Set (D).
  This operator implements the `Convert(R)` function from Algorithm 1.
  The specific conversion logic depends on the nature of the rules.
  """

  alias HyperTreePlanner.DataStructures.DivisibleSet

  @doc """
  Converts a set of rules into a divisible set.

  Input `params` must include `{"rules": R}` where R is expected to be a list of rule objects (maps).
  Each rule object should have at least an `id` and `content` field.

  Output will be `{:ok, %{"divisible_set" => D}}` where D is a DivisibleSet struct,
  or `{:error, reason}` if input is invalid.

  The conversion logic implemented here assumes each rule is made "divisible"
  by adding some metadata or transforming its content. This is a functional placeholder
  that can be expanded based on more specific requirements for rule divisibility.
  """
  def call(params) do
    rules = Map.get(params, "rules")

    cond do
      is_nil(rules) ->
        {:error, "Input 'rules' are missing."}
      not is_list(rules) ->
        {:error, "Input 'rules' must be a list."}
      Enum.any?(rules, fn rule -> not is_map(rule) or is_nil(Map.get(rule, :id)) or is_nil(Map.get(rule, :content)) end) ->
        {:error, "Each rule in 'rules' must be a map with at least 'id' and 'content' keys."}
      true ->
        # Functional conversion logic:
        # For each rule, create a "divisible item".
        # This might involve breaking down the rule, adding properties, or linking to knowledge.
        # Here, we'll add a 'divisibility_status' and a 'processed_content' field.
        processed_items = Enum.map(rules, fn rule ->
          %{ 
            original_rule_id: rule.id,
            original_content: rule.content,
            # Example of processing: could be tokenization, embedding generation, etc.
            processed_content: "[DIVISIBLE] " <> to_string(rule.content),
            divisibility_score: :rand.uniform(), # Placeholder score
            type: :divisible_rule_fragment
          }
        end)
        
        divisible_set_struct = DivisibleSet.new(processed_items, %{
          conversion_timestamp: DateTime.utc_now(),
          source_rule_count: Enum.count(rules),
          conversion_method: "Default RuleConverterOperator v1.0"
        })
        {:ok, %{"divisible_set" => divisible_set_struct}}
    end
  end

  @doc """
  Returns the JSON schema for input validation for this operator.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "rules" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string"},
              "content" => %{"type" => "string"} # Or a more complex object
              # Add other expected rule properties here
            },
            "required" => ["id", "content"]
          }
        }
      },
      "required" => ["rules"]
    }
  end

  @doc """
  Returns the JSON schema for output validation for this operator.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "divisible_set" => %{
          "type" => "object",
          # Ideally, this would reference a detailed schema for the DivisibleSet struct,
          # including its 'items' and 'metadata'.
          "properties" => %{
            "id" => %{"type" => "string"},
            "items" => %{"type" => "array"},
            "metadata" => %{"type" => "object"}
          },
          "required" => ["id", "items", "metadata"]
        }
      },
      "required" => ["divisible_set"]
    }
  end
end

