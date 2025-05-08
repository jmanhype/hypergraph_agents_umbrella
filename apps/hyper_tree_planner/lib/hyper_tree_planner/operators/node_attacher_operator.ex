# apps/hyper_tree_planner/lib/hyper_tree_planner/operators/node_attacher_operator.ex
defmodule HyperTreePlanner.Operators.NodeAttacherOperator do
  @moduledoc """
  Operator to attach newly expanded nodes to the Hypertree (H).
  This operator implements the `H <- AttachNodes({s_i_p}, H, g_i*)` part of Algorithm 1.
  """

  alias HyperTreePlanner.DataStructures.Hypertree

  @doc """
  Attaches a list of expanded nodes to the current Hypertree under a specified parent node.

  Input `params` should include:
  - `{"expanded_nodes": [{s_i_p}]}`: A list of new nodes to attach (maps with at least :id and :content).
  - `{"current_hypertree": H_struct}`: The current state of the Hypertree (a Hypertree struct).
  - `{"parent_node_id": g_i*_id}`: The ID of the node in H to which the new nodes should be attached.

  Output should be `{:ok, %{"updated_hypertree": H_new_struct}}` or `{:error, reason}`.

  The actual logic for `AttachNodes` involves adding nodes and creating hyperedges.
  """
  def call(params) do
    expanded_nodes = Map.get(params, "expanded_nodes")
    current_hypertree_struct = Map.get(params, "current_hypertree")
    parent_node_id = Map.get(params, "parent_node_id")

    # --- Input Validation ---
    cond do
      is_nil(expanded_nodes) or not is_list(expanded_nodes) ->
        {:error, "Input 'expanded_nodes' are missing or not a list."}
      is_nil(current_hypertree_struct) or not is_map(current_hypertree_struct) or not Map.has_key?(current_hypertree_struct, :nodes) ->
        {:error, "Input 'current_hypertree' is missing or invalid."}
      is_nil(parent_node_id) or not is_binary(parent_node_id) ->
        {:error, "Input 'parent_node_id' is missing or not a string."}
      # Ensure parent_node_id exists in the current_hypertree_struct
      not Enum.any?(current_hypertree_struct.nodes, fn node -> node.id == parent_node_id end) ->
        {:error, "Parent node with ID '#{parent_node_id}' not found in hypertree."}
      true ->
        # --- Functional Node Attachment Logic ---
        # 1. Add new nodes to the hypertree's node list.
        #    Ensure new nodes have unique IDs if not already provided, or handle potential clashes.
        #    For simplicity, we assume expanded_nodes are maps like %{id: "unique_id", content: "...", type: ...}
        updated_nodes_list = current_hypertree_struct.nodes ++ expanded_nodes

        # 2. Create new hyperedges connecting the parent_node_id to each of the expanded_nodes.
        #    A hyperedge can connect one parent to multiple children in this expansion step.
        #    The structure of a hyperedge needs to be defined (e.g., %{id: uuid, type: :expansion, head_nodes: [parent_id], tail_nodes: [child_ids]}) 
        new_hyperedges = Enum.map(expanded_nodes, fn new_node ->
          %{
            id: "he_" <> Ecto.UUID.generate(),
            type: :expansion_link, # Or a more descriptive type
            head_nodes: [parent_node_id],
            tail_nodes: [new_node.id], # Assuming new_node is a map with an :id key
            properties: %{created_at: DateTime.utc_now()}
          }
        end)

        updated_hyperedges_list = current_hypertree_struct.hyperedges ++ new_hyperedges

        # 3. Construct the updated Hypertree struct.
        updated_hypertree = %{current_hypertree_struct | 
                                nodes: updated_nodes_list, 
                                hyperedges: updated_hyperedges_list,
                                properties: Map.put(current_hypertree_struct.properties, :last_attached_at, DateTime.utc_now())
                              }

        {:ok, %{"updated_hypertree" => updated_hypertree}}
    end
  end

  @doc """
  Returns the JSON schema for input validation for this operator.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "expanded_nodes" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string"},
              "content" => %{"type" => "string"}
              # Add other expected node properties
            },
            "required" => ["id", "content"]
          },
          "description" => "List of new nodes to attach."
        },
        "current_hypertree" => %{
          "type" => "object", 
          "description" => "The current Hypertree structure."
        },
        "parent_node_id" => %{
          "type" => "string", 
          "description" => "ID of the parent node in the hypertree to attach new nodes to."
        }
      },
      "required" => ["expanded_nodes", "current_hypertree", "parent_node_id"]
    }
  end

  @doc """
  Returns the JSON schema for output validation for this operator.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "updated_hypertree" => %{
          "type" => "object", 
          "description" => "The Hypertree structure after attaching new nodes."
        }
      },
      "required" => ["updated_hypertree"]
    }
  end
end

