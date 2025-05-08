defmodule HyperTreePlanner.Operators.RuleConverterOperator do
  @moduledoc """
  Operator responsible for converting a set of input rules (R) into a Divisible Set (D).

  This operator encapsulates the `Convert(R)` function as described in Algorithm 1
  of the Top-down HyperTree Construction process. The primary goal is to transform
  the raw input rules into a format that is more amenable for the LLM to identify
  and utilize relevant pieces of information (divisible nodes) during the planning
  and expansion phases of the hypertree.

  The exact nature of "divisibility" and the conversion logic can be tailored based
  on the specific characteristics of the input rules and the desired behavior of the
  planning agent. This implementation provides a functional placeholder that can be
  extended with more sophisticated rule processing techniques.
  """

  alias HyperTreePlanner.DataStructures.DivisibleSet

  @doc """
  Converts a list of rule objects into a `HyperTreePlanner.DataStructures.DivisibleSet`.

  The input `params` map is expected to contain a `"rules"` key, where the value
  is a list of maps. Each map in the list represents a single rule and must contain
  at least an `:id` and `:content` field. Other fields within the rule map are preserved
  and can be used in the conversion process.

  The conversion logic in this version involves iterating through each input rule and
  creating a corresponding "divisible item". This item includes the original rule's ID
  and content, along with placeholder `processed_content` (prefixed with "[DIVISIBLE]")
  and a random `divisibility_score`. In a more advanced implementation, `processed_content`
  could involve tokenization, embedding generation, or other forms of rule decomposition.

  The resulting `DivisibleSet` struct contains these processed items and metadata about
  the conversion process, such as a timestamp and the number of source rules.

  Returns `{:ok, %{"divisible_set" => divisible_set_struct}}` on success, or
  `{:error, reason_string}` if the input parameters are invalid (e.g., missing rules,
  incorrect rule format).

  ## Parameters

    - `params`: A map containing the input parameters. Expected to have a `"rules"` key
      with a list of rule maps as its value.

  ## Examples

      iex> rules_input = [
      ...>   %{id: "rule1", content: "If A then B", type: "implication"},
      ...>   %{id: "rule2", content: "C is a prerequisite for D"}
      ...> ]
      iex> params = %{"rules" => rules_input}
      iex> {:ok, result} = HyperTreePlanner.Operators.RuleConverterOperator.call(params)
      iex> divisible_set = result["divisible_set"]
      iex> is_struct(divisible_set, HyperTreePlanner.DataStructures.DivisibleSet)
      true
      iex> Enum.count(divisible_set.items)
      2
      iex> item1 = Enum.find(divisible_set.items, &(&1.original_rule_id == "rule1"))
      iex> item1.original_content
      "If A then B"
      iex> item1.processed_content
      "[DIVISIBLE] If A then B"
      iex> divisible_set.metadata.source_rule_count
      2

      iex> HyperTreePlanner.Operators.RuleConverterOperator.call(%{})
      {:error, "Input 'rules' are missing."}

      iex> HyperTreePlanner.Operators.RuleConverterOperator.call(%{"rules" => "not a list"})
      {:error, "Input 'rules' must be a list."}

      iex> HyperTreePlanner.Operators.RuleConverterOperator.call(%{"rules" => [%{content: "no id"}]})
      {:error, "Each rule in 'rules' must be a map with at least 'id' and 'content' keys."}
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
        processed_items = Enum.map(rules, fn rule ->
          %{
            original_rule_id: rule.id,
            original_content: rule.content,
            processed_content: "[DIVISIBLE] " <> to_string(rule.content),
            divisibility_score: :rand.uniform(), # Placeholder score
            type: :divisible_rule_fragment,
            # Preserve other original rule fields if needed
            original_rule_data: Map.drop(rule, [:id, :content])
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
  Returns the JSON schema specification for the input parameters of this operator.

  This schema defines the expected structure for the `params` map passed to the `call/1` function.
  It requires a `"rules"` property, which should be an array of objects.
  Each object in the `"rules"` array must have `"id"` (string) and `"content"` (string) properties.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "rules" => %{
          "type" => "array",
          "description" => "A list of rule objects to be converted.",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string", "description" => "Unique identifier for the rule."},
              "content" => %{"type" => "string", "description" => "The textual content or representation of the rule."}
              # Add other expected rule properties here as needed, e.g.:
              # "type" => %{"type" => "string", "description" => "Category or type of the rule."}
            },
            "required" => ["id", "content"]
          }
        }
      },
      "required" => ["rules"]
    }
  end

  @doc """
  Returns the JSON schema specification for the output produced by this operator.

  This schema defines the structure of the map returned within the `{:ok, result}` tuple
  from the `call/1` function. It expects a `"divisible_set"` property, which should be an object
  representing the `HyperTreePlanner.DataStructures.DivisibleSet` struct.
  The schema for `DivisibleSet` itself (including its `items` and `metadata`) would ideally be
  defined in more detail, potentially referencing a shared schema definition.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "divisible_set" => %{
          "type" => "object",
          "description" => "The DivisibleSet created from the input rules.",
          "properties" => %{
            "id" => %{"type" => "string", "description" => "UUID of the DivisibleSet."},
            "items" => %{
              "type" => "array",
              "description" => "List of processed divisible items.",
              "items" => %{ # Basic structure of a divisible item
                "type" => "object",
                "properties" => %{
                  "original_rule_id" => %{"type" => "string"},
                  "original_content" => %{"type" => "string"},
                  "processed_content" => %{"type" => "string"},
                  "divisibility_score" => %{"type" => "number"},
                  "type" => %{"type" => "string", "enum" => ["divisible_rule_fragment"]}
                }
              }
            },
            "metadata" => %{
              "type" => "object",
              "description" => "Metadata about the conversion process.",
              "properties" => %{
                "conversion_timestamp" => %{"type" => "string", "format" => "date-time"},
                "source_rule_count" => %{"type" => "integer"},
                "conversion_method" => %{"type" => "string"}
              }
            }
          },
          "required" => ["id", "items", "metadata"]
        }
      },
      "required" => ["divisible_set"]
    }
  end
end

