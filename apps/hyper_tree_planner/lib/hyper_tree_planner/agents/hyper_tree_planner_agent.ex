# apps/hyper_tree_planner/lib/hyper_tree_planner/agents/hyper_tree_planner_agent.ex
defmodule HyperTreePlanner.Agents.HyperTreePlannerAgent do
  @moduledoc """
  This agent orchestrates the Top-down HyperTree Construction algorithm.
  It interacts with various operators to perform tasks like rule conversion,
  hypergraph generation, and result presentation.
  It uses other modules for LLM interactions and data structure management.
  """

  use GenServer
  require Logger

  alias HyperTreePlanner.DataStructures.Hypertree
  alias HyperTreePlanner.DataStructures.Hyperchain # Ensure this is used correctly
  alias HyperTreePlanner.DataStructures.DivisibleSet
  alias HyperTreePlanner.DataStructures.PlanningOutline

  alias HyperTreePlanner.Operators.RuleConverterOperator
  alias HyperTreePlanner.Operators.InitializeHypertreeOperator
  alias HyperTreePlanner.Operators.HyperchainExtractorOperator 
  alias HyperTreePlanner.Operators.NodeAttacherOperator 

  # Placeholder for a module that would interact with an LLM service
  # In a real Hypergraph Agents setup, this would likely be a call to a registered LLMOperator service.
  defmodule LLMService do
    def request(prompt_type, input_data) do
      Logger.debug("LLMService Request: Prompt Type - #{prompt_type}, Input - #{inspect(input_data)}")
      # Simulate LLM responses for now. This needs to be replaced with actual LLM calls.
      case prompt_type do
        "filter_hyperchains" -> 
          chains = Map.get(input_data, :chains, [])
          w = Map.get(input_data, :W, 1)
          {:ok, %{"filtered_chains" => Enum.take(chains, w)}}
        "extract_divisible_nodes" ->
          _chain_ci = Map.get(input_data, :chain)
          _divisible_set = Map.get(input_data, :divisible_set)
          sample_nodes = Enum.map(1..(:rand.uniform(3) + 1), fn i -> 
            %{id: "div_node_#{Ecto.UUID.generate()}_#{i}", content: "Simulated Divisible Node #{i}", type: :goal}
          end)
          {:ok, %{"divisible_nodes" => sample_nodes}}
        "select_node" ->
          divisible_nodes = Map.get(input_data, :divisible_nodes, [])
          if Enum.empty?(divisible_nodes) do
            {:ok, %{"selected_node" => nil}} 
          else
            {:ok, %{"selected_node" => List.first(divisible_nodes)}}
          end
        "retrieve_rules" ->
          _selected_node = Map.get(input_data, :selected_node)
          _rules_db = Map.get(input_data, :rules_db)
          sample_rules = Enum.map(1..(:rand.uniform(2) + 1), fn i -> 
            %{id: "rule_#{Ecto.UUID.generate()}_#{i}", content: "Simulated Rule #{i}"}
          end)
          {:ok, %{"retrieved_rules" => sample_rules}}
        "expand_nodes" ->
          _selected_node = Map.get(input_data, :selected_node)
          _rule = Map.get(input_data, :rule)
          new_nodes = [%{id: "exp_node_#{Ecto.UUID.generate()}", content: "Simulated Expanded Node based on rule", type: :subgoal}]
          {:ok, %{"expanded_nodes" => new_nodes}}
        "select_optimal_hyperchain" ->
          hypertree = Map.get(input_data, :hypertree)
          case HyperchainExtractorOperator.call(%{"hypertree" => hypertree}) do
            {:ok, %{"hyperchains" => [first_chain | _]}} -> 
              {:ok, %{"optimal_chain" => first_chain}}
            _ -> 
              dummy_optimal_chain = HyperTreePlanner.DataStructures.Hyperchain.new([], [], %{status: "dummy_fallback"})
              {:ok, %{"optimal_chain" => dummy_optimal_chain}}
          end
        _ -> 
          {:error, "Unknown LLM prompt type: #{prompt_type}"}
      end
    end
  end

  # --- GenServer Callbacks ---

  def start_link(opts \\ []) do
    opts_keyword = if is_list(opts), do: opts, else: [] 
    GenServer.start_link(__MODULE__, opts_keyword, name: Keyword.get(opts_keyword, :name, __MODULE__))
  end

  @impl true
  def init(_opts) do
    Logger.info("HyperTreePlannerAgent initialized.")
    {:ok, %{original_rules: nil, query: nil, k_depth: 0, w_width: 0, current_hypertree: nil}}
  end

  # --- Public API ---
  def plan_hyper_tree(pid \\ __MODULE__, params) do
    GenServer.call(pid, {:plan_hyper_tree, params})
  end

  @impl true
  def handle_call({:plan_hyper_tree, params}, _from, state) do
    Logger.info("Received request to plan hyper tree with params: #{inspect(params)}")

    rules_input = Map.get(params, "rules") 
    query_content = Map.get(params, "query") 
    k_depth = Map.get(params, "k_depth")     
    w_width = Map.get(params, "w_width")     

    if is_nil(rules_input) || not is_list(rules_input) || is_nil(query_content) || not is_binary(query_content) || not is_integer(k_depth) || not is_integer(w_width) do
      Logger.error("Invalid or missing parameters for plan_hyper_tree. Rules: #{is_list(rules_input)}, Query: #{is_binary(query_content)}, K: #{is_integer(k_depth)}, W: #{is_integer(w_width)}")
      return {:reply, {:error, "Invalid or missing parameters"}, state}
    end

    # Step 1: Convert rules to a divisible set (D)
    case RuleConverterOperator.call(%{"rules" => rules_input}) do
      {:ok, %{"divisible_set" => divisible_set_struct}} ->
        Logger.info("Rules converted to divisible set.")
        
        # Step 2: Initialize the hypertree (H) with the query (q)
        case InitializeHypertreeOperator.call(%{"query" => query_content}) do
          {:ok, %{"hypertree" => initial_hypertree_struct}} ->
            Logger.info("Hypertree initialized.")
            
            updated_state = %{state | original_rules: rules_input, query: query_content, k_depth: k_depth, w_width: w_width, current_hypertree: initial_hypertree_struct}

            # --- Main Algorithm Loop ---
            final_hypertree = 
              Enum.reduce(1..k_depth, initial_hypertree_struct, fn d_iter, current_h_acc ->
                Logger.info("[Depth #{d_iter}/#{k_depth}] Starting iteration.")

                # Step 4: Extract hyperchains {C1,...,Cm} <- Map(H)
                case HyperchainExtractorOperator.call(%{"hypertree" => current_h_acc}) do
                  {:ok, %{"hyperchains" => chains}} ->
                    Logger.info("[Depth #{d_iter}] Extracted #{Enum.count(chains)} hyperchains.")

                    # Step 5: Filter hyperchains if m > W: {C1,...,Cw} <- πθ(H)
                    filtered_chains = 
                      if Enum.count(chains) > w_width do
                        Logger.info("[Depth #{d_iter}] Filtering #{Enum.count(chains)} chains to #{w_width}.")
                        case LLMService.request("filter_hyperchains", %{chains: chains, W: w_width, hypertree: current_h_acc}) do
                          {:ok, %{"filtered_chains" => f_chains}} -> f_chains
                          {:error, reason} -> 
                            Logger.error("[Depth #{d_iter}] Error filtering hyperchains: #{inspect(reason)}. Using top W.")
                            Enum.take(chains, w_width)
                        end
                      else
                        chains
                      end
                    Logger.info("[Depth #{d_iter}] Processing #{Enum.count(filtered_chains)} filtered hyperchains.")

                    # Step 6-12: Loop through filtered chains and expand
                    Enum.reduce(filtered_chains, current_h_acc, fn chain_ci, h_for_chain_expansion ->
                      Logger.info("[Depth #{d_iter}, Chain #{inspect(chain_ci.id || "N/A")}] Processing chain.")

                      # Step 7: Extract divisible nodes: g1,...,gni <- πθ(Ci, D)
                      case LLMService.request("extract_divisible_nodes", %{chain: chain_ci, divisible_set: divisible_set_struct, query: query_content, hypertree: h_for_chain_expansion}) do
                        {:ok, %{"divisible_nodes" => divisible_nodes}} when is_list(divisible_nodes) and not Enum.empty?(divisible_nodes) ->
                          Logger.info("[Depth #{d_iter}, Chain] Extracted #{Enum.count(divisible_nodes)} divisible nodes.")

                          # Step 8: Select node: gi* <- πθ(q, H, g1,...,gni)
                          case LLMService.request("select_node", %{query: query_content, hypertree: h_for_chain_expansion, divisible_nodes: divisible_nodes}) do
                            {:ok, %{"selected_node" => gi_star}} when not is_nil(gi_star) ->
                              Logger.info("[Depth #{d_iter}, Chain] Selected node: #{inspect(gi_star.id || gi_star)}")

                              # Step 9: Retrieve rules: r1,...,rP <- πθ(R, gi*)
                              case LLMService.request("retrieve_rules", %{rules_db: rules_input, selected_node: gi_star, query: query_content, hypertree: h_for_chain_expansion}) do
                                {:ok, %{"retrieved_rules" => rules_rp_list}} when is_list(rules_rp_list) and not Enum.empty?(rules_rp_list) ->
                                  Logger.info("[Depth #{d_iter}, Chain] Retrieved #{Enum.count(rules_rp_list)} rules for node.")

                                  # Step 10-12: Loop through rules and expand nodes
                                  Enum.reduce(rules_rp_list, h_for_chain_expansion, fn rule_rp, h_for_rule_expansion ->
                                    # Step 11: Expand nodes: {si_p} <- πθ(q, Ci, gi*, rp)
                                    case LLMService.request("expand_nodes", %{query: query_content, chain: chain_ci, selected_node: gi_star, rule: rule_rp, hypertree: h_for_rule_expansion}) do
                                      {:ok, %{"expanded_nodes" => si_p_nodes}} when is_list(si_p_nodes) and not Enum.empty?(si_p_nodes) ->
                                        Logger.info("[Depth #{d_iter}, Chain, Rule #{inspect(rule_rp.id || rule_rp)}] Generated #{Enum.count(si_p_nodes)} expanded nodes.")
                                        
                                        parent_node_id_for_attachment = if is_map(gi_star), do: gi_star.id, else: gi_star
                                        case NodeAttacherOperator.call(%{"expanded_nodes" => si_p_nodes, "current_hypertree" => h_for_rule_expansion, "parent_node_id" => parent_node_id_for_attachment}) do
                                          {:ok, %{"updated_hypertree" => h_after_attach}} ->
                                            Logger.info("[Depth #{d_iter}, Chain, Rule] Nodes attached.")
                                            h_after_attach
                                          {:error, attach_reason} ->
                                            Logger.error("[Depth #{d_iter}, Chain, Rule] Failed to attach nodes: #{inspect(attach_reason)}")
                                            h_for_rule_expansion
                                        end
                                      {:ok, %{"expanded_nodes" => _}} -> 
                                        Logger.info("[Depth #{d_iter}, Chain, Rule #{inspect(rule_rp.id || rule_rp)}] No nodes expanded by LLM.")
                                        h_for_rule_expansion
                                      {:error, expand_reason} ->
                                        Logger.error("[Depth #{d_iter}, Chain, Rule #{inspect(rule_rp.id || rule_rp)}] Error expanding nodes: #{inspect(expand_reason)}")
                                        h_for_rule_expansion
                                    end
                                  end)
                                {:ok, %{"retrieved_rules" => _}} -> 
                                  Logger.info("[Depth #{d_iter}, Chain] No rules retrieved for node.")
                                  h_for_chain_expansion
                                {:error, retrieve_reason} ->
                                  Logger.error("[Depth #{d_iter}, Chain] Error retrieving rules: #{inspect(retrieve_reason)}")
                                  h_for_chain_expansion
                              end
                            {:ok, %{"selected_node" => _}} -> 
                              Logger.info("[Depth #{d_iter}, Chain] No node selected by LLM.")
                              h_for_chain_expansion
                            {:error, select_reason} ->
                              Logger.error("[Depth #{d_iter}, Chain] Error selecting node: #{inspect(select_reason)}")
                              h_for_chain_expansion
                          end
                        {:ok, %{"divisible_nodes" => _}} -> 
                          Logger.info("[Depth #{d_iter}, Chain] No divisible nodes extracted.")
                          h_for_chain_expansion
                        {:error, extract_reason} ->
                          Logger.error("[Depth #{d_iter}, Chain] Error extracting divisible nodes: #{inspect(extract_reason)}")
                          h_for_chain_expansion
                      end
                    end)
                  {:error, extract_chains_reason} ->
                    Logger.error("[Depth #{d_iter}] Error extracting hyperchains: #{inspect(extract_chains_reason)}")
                    current_h_acc
                end
              end)

            # Step 13: Select the optimal hyperchain: C* <- πθ(H_final)
            case LLMService.request("select_optimal_hyperchain", %{hypertree: final_hypertree, query: query_content}) do
              {:ok, %{"optimal_chain" => optimal_chain_struct}} when not is_nil(optimal_chain_struct) ->
                Logger.info("Optimal hyperchain selected: #{inspect(optimal_chain_struct)}")
                planning_outline = PlanningOutline.new(optimal_chain_struct, %{generation_details: "Generated by HyperTreePlannerAgent"})
                {:reply, {:ok, planning_outline}, updated_state}
              _ ->
                Logger.error("Failed to select optimal hyperchain or none found from final tree.")
                empty_chain = HyperTreePlanner.DataStructures.Hyperchain.new([], [], %{status: "fallback_empty_optimal_chain"})
                planning_outline = PlanningOutline.new(empty_chain, %{generation_details: "Failed to select optimal, fallback"})
                {:reply, {:ok, planning_outline}, updated_state}
            end

          {:error, init_reason} ->
            Logger.error("Failed to initialize hypertree: #{inspect(init_reason)}")
            {:reply, {:error, "Failed to initialize hypertree: #{inspect(init_reason)}"}, state}
        end
      {:error, convert_reason} ->
        Logger.error("Failed to convert rules: #{inspect(convert_reason)}")
        {:reply, {:error, "Failed to convert rules: #{inspect(convert_reason)}"}, state}
    end
  end
end

