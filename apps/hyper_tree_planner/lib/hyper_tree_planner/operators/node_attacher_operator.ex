defmodule HyperTreePlanner.Operators.NodeAttacherOperator do
  @moduledoc """
  Operator responsible for attaching a list of newly expanded nodes to the Hypertree (H)
  under a specified parent node.

  This operator implements the `H <- AttachNodes({s_i_p}, H, g_i*)` step from Algorithm 1
  of the Top-down HyperTree Construction process. Its main function is to update the
  hypertree structure by incorporating new nodes and creating the necessary hyperedges
  to link them to their parent node, representing an expansion in the planning process.
  """

  alias HyperTreePlanner.DataStructures.Hypertree

  @doc """
  Attaches a list of expanded nodes to the current `HyperTreePlanner.DataStructures.Hypertree`
  under a specified parent node.

  The input `params` map is expected to contain:
  - `"expanded_nodes"`: A list of maps, where each map represents a new node to be attached.
    Each new node map must contain at least an `:id` (string) and `:content` (string).
    Other fields like `:type` can also be included.
  - `"current_hypertree"`: The current `HyperTreePlanner.DataStructures.Hypertree` struct to which
    the new nodes will be added.
  - `"parent_node_id"`: The string ID of an existing node within `current_hypertree` that will
    serve as the parent for the `expanded_nodes`.

  The operator performs the following actions:
  1. Validates the input parameters.
  2. Adds each node from `expanded_nodes` to the `nodes` list of the `current_hypertree`.
     It assumes new node IDs are unique; robust error handling for ID clashes might be needed
     in a production system.
  3. For each newly added node, it creates a new hyperedge. This hyperedge links the
     `parent_node_id` (as the head) to the new node (as the tail). The hyperedge is given
     a unique ID and a type (e.g., `:expansion_link`).
  4. Returns the updated `Hypertree` struct.

  Returns `{:ok, %{"updated_hypertree" => updated_hypertree_struct}}` on success, or
  `{:error, reason_string}` if input parameters are invalid or the parent node is not found.

  ## Parameters

    - `params`: A map containing the input parameters as described above.

  ## Examples

      iex> parent_node = %{id: "parent1", content: "Parent Node", type: :task}
      iex> initial_tree = HyperTreePlanner.DataStructures.Hypertree.new()
      iex> tree_with_parent = HyperTreePlanner.DataStructures.Hypertree.add_node(initial_tree, "parent1", parent_node)
      iex> 
      iex> new_nodes_to_attach = [
      ...>   %{id: "child1_of_parent1", content: "Child node 1", type: :sub_task},
      ...>   %{id: "child2_of_parent1", content: "Child node 2", type: :sub_task}
      ...> ]
      iex> params = %{
      ...>   "expanded_nodes" => new_nodes_to_attach,
      ...>   "current_hypertree" => tree_with_parent,
      ...>   "parent_node_id" => "parent1"
      ...> }
      iex> {:ok, result} = HyperTreePlanner.Operators.NodeAttacherOperator.call(params)
      iex> updated_tree = result["updated_hypertree"]
      iex> is_struct(updated_tree, HyperTreePlanner.DataStructures.Hypertree)
      true
      iex> Enum.count(updated_tree.nodes)
      3 # parent1, child1, child2
      iex> Enum.count(updated_tree.hyperedges)
      2 # One edge for each new child
      iex> child1_node = Enum.find(updated_tree.nodes, &(&1.id == "child1_of_parent1"))
      iex> child1_node.content
      "Child node 1"
      iex> edge_for_child1 = Enum.find(updated_tree.hyperedges, fn he -> he.tail_nodes == ["child1_of_parent1"] end)
      iex> edge_for_child1.head_nodes
      ["parent1"]
      iex> edge_for_child1.type
      :expansion_link

      iex> HyperTreePlanner.Operators.NodeAttacherOperator.call(%{"expanded_nodes" => [], "current_hypertree" => tree_with_parent, "parent_node_id" => "non_existent_parent"})
      {:error, "Parent node with ID 'non_existent_parent' not found in hypertree."}

      iex> HyperTreePlanner.Operators.NodeAttacherOperator.call(%{"expanded_nodes" => "not a list", "current_hypertree" => tree_with_parent, "parent_node_id" => "parent1"})
      {:error, "Input 'expanded_nodes' are missing or not a list."}
  """
  def call(params) do
    expanded_nodes = Map.get(params, "expanded_nodes")
    current_hypertree_struct = Map.get(params, "current_hypertree")
    parent_node_id = Map.get(params, "parent_node_id")

    # --- Input Validation ---
    cond do
      is_nil(expanded_nodes) or not is_list(expanded_nodes) ->
        {:error, "Input 'expanded_nodes' are missing or not a list."}
      # Basic check for hypertree structure; a more robust check might use Hypertree.is_hypertree?/1
      is_nil(current_hypertree_struct) or not is_map(current_hypertree_struct) or not Map.has_key?(current_hypertree_struct, :nodes) or not Map.has_key?(current_hypertree_struct, :hyperedges) ->
        {:error, "Input 'current_hypertree' is missing or invalid."}
      is_nil(parent_node_id) or not is_binary(parent_node_id) ->
        {:error, "Input 'parent_node_id' is missing or not a string."}
      # Ensure parent_node_id exists in the current_hypertree_struct.nodes (which is a list of maps)
      not Enum.any?(current_hypertree_struct.nodes, fn node -> node.id == parent_node_id end) ->
        {:error, "Parent node with ID '#{parent_node_id}' not found in hypertree."}
      true ->
        # --- Functional Node Attachment Logic ---
        # 1. Add new nodes to the hypertree's node list.
        #    Ensure new nodes have unique IDs. For simplicity, we assume they are provided and unique.
        #    A production system might generate IDs or check for collisions.
        updated_nodes_map = Enum.reduce(expanded_nodes, current_hypertree_struct.nodes, fn new_node, acc_nodes ->
          # Assuming new_node is %{id: "...", content: "...", type: "..."}
          # If nodes were a map, this would be Map.put(acc_nodes, new_node.id, new_node)
          # Since nodes is a list of maps, we append. Consider if IDs should be unique.
          acc_nodes ++ [new_node] 
        end)

        # 2. Create new hyperedges connecting the parent_node_id to each of the expanded_nodes.
        new_hyperedges = Enum.map(expanded_nodes, fn new_node ->
          unless Map.has_key?(new_node, :id) do
            # This case should ideally be caught by input validation or node creation logic
            raise "New node is missing an :id field: #{inspect(new_node)}"
          end
          %{
            id: "he_" <> Ecto.UUID.generate(), # Generate a unique ID for the hyperedge
            type: :expansion_link,             # Type of relationship
            head_nodes: [parent_node_id],      # Parent node ID
            tail_nodes: [new_node.id],         # New child node ID
            properties: %{created_at: DateTime.utc_now(), reason: "expansion"}
          }
        end)

        updated_hyperedges_list = current_hypertree_struct.hyperedges ++ new_hyperedges

        # 3. Construct the updated Hypertree struct.
        updated_hypertree = %{current_hypertree_struct | 
                                nodes: updated_nodes_map, # Using the updated list of node maps
                                hyperedges: updated_hyperedges_list,
                                metadata: Map.put(current_hypertree_struct.metadata || %{}, :last_attached_at, DateTime.utc_now())
                              }

        {:ok, %{"updated_hypertree" => updated_hypertree}}
    end
  end

  @doc """
  Returns the JSON schema specification for the input parameters of this operator.

  This schema defines the expected structure for the `params` map passed to `call/1`:
  - `"expanded_nodes"`: An array of node objects to be attached.
  - `"current_hypertree"`: An object representing the current hypertree.
  - `"parent_node_id"`: A string ID of the parent node.
  """
  def input_spec do
    %{
      "type" => "object",
      "properties" => %{
        "expanded_nodes" => %{
          "type" => "array",
          "description" => "A list of new node objects to attach to the hypertree.",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string", "description" => "Unique identifier for the new node."},
              "content" => %{"type" => "string", "description" => "The content of the new node."},
              "type" => %{"type" => "string", "description" => "Optional type of the new node (e.g., :sub_task, :information)."}
              # Add other expected node properties as needed
            },
            "required" => ["id", "content"]
          }
        },
        "current_hypertree" => %{
          "type" => "object", 
          "description" => "The current Hypertree structure (HyperTreePlanner.DataStructures.Hypertree.t()) to be updated."
          # Ideally, this would reference a detailed schema for the Hypertree struct
        },
        "parent_node_id" => %{
          "type" => "string", 
          "description" => "The ID of the existing node in the hypertree to which the new nodes will be attached as children."
        }
      },
      "required" => ["expanded_nodes", "current_hypertree", "parent_node_id"]
    }
  end

  @doc """
  Returns the JSON schema specification for the output produced by this operator.

  This schema defines that the output will be an object with a required `"updated_hypertree"` property.
  The value of `"updated_hypertree"` should be an object representing the
  `HyperTreePlanner.DataStructures.Hypertree` struct after the new nodes and hyperedges
  have been added.
  """
  def output_spec do
    %{
      "type" => "object",
      "properties" => %{
        "updated_hypertree" => %{
          "type" => "object", 
          "description" => "The Hypertree structure (HyperTreePlanner.DataStructures.Hypertree.t()) after attaching the new nodes and their corresponding hyperedges."
          # Ideally, this would reference a detailed schema for the Hypertree struct
        }
      },
      "required" => ["updated_hypertree"]
    }
  end
end

