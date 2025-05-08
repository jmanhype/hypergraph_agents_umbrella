defmodule HyperTreePlanner.Agents.HyperTreePlannerAgent do
  @moduledoc """
  The `HyperTreePlannerAgent` is a GenServer responsible for orchestrating the
  Top-down HyperTree Construction algorithm (Algorithm 1 from the provided text).

  It manages the state of the planning process, including the current hypertree,
  divisible rules, query, reasoning depth (K), and expansion width (W).
  The agent interacts with various custom operators (`RuleConverterOperator`,
  `InitializeHypertreeOperator`, `HyperchainExtractorOperator`, `NodeAttacherOperator`)
  to perform specific steps of the algorithm. It also uses a (currently mocked)
  `LLMService` for tasks requiring language model inference, such as filtering
  hyperchains, selecting promising nodes, retrieving rules, and expanding nodes.

  The agent exposes a primary interface `plan_hyper_tree/2` to initiate the
  planning process. It also includes an LLM caching mechanism to optimize
  performance by avoiding redundant LLM calls and uses `Task.async_stream`
  for parallelizing LLM calls during rule expansion.

  ## Agent State

  The agent's state is a map containing:
  - `:original_rules`: The initial set of rules `R` provided as input.
  - `:query`: The input query `q`.
  - `:k_depth`: The maximum reasoning depth `K`.
  - `:w_width`: The maximum expansion width `W`.
  - `:current_hypertree`: The current state of the `HyperTreePlanner.DataStructures.Hypertree` `H`.
  - `:llm_cache`: A map used to cache responses from the `LLMService`.
  """

  use GenServer
  require Logger

  alias HyperTreePlanner.DataStructures.Hypertree
  alias HyperTreePlanner.DataStructures.Hyperchain
  alias HyperTreePlanner.DataStructures.DivisibleSet
  alias HyperTreePlanner.DataStructures.PlanningOutline

  alias HyperTreePlanner.Operators.RuleConverterOperator
  alias HyperTreePlanner.Operators.InitializeHypertreeOperator
  alias HyperTreePlanner.Operators.HyperchainExtractorOperator
  alias HyperTreePlanner.Operators.NodeAttacherOperator

  # --- Mock LLM Service ---
  defmodule LLMService do
    @moduledoc """
    A **mock** implementation of an LLM service for development and testing purposes.

    This module simulates responses that would typically come from a real Large
    Language Model. The responses are hardcoded or generated with simple logic
    to allow testing the `HyperTreePlannerAgent`'s control flow without actual
    LLM dependencies or costs.

    In a production environment, this module would be replaced by an actual
    client for an LLM service (e.g., OpenAI, Anthropic, or a self-hosted model)
    that integrates with the Hypergraph Agents Umbrella framework's `LLMOperator`.
    """

    @doc """
    Simulates a request to an LLM service.

    Based on the `prompt_type`, it returns a predefined or simply generated
    response structure. This helps in testing the agent's logic for handling
    different LLM outputs.

    ## Parameters

      - `prompt_type`: A string indicating the type of LLM task (e.g.,
        `"filter_hyperchains"`, `"expand_nodes"`).
      - `input_data`: A map containing the data relevant to the `prompt_type`.

    ## Returns

      - `{:ok, response_map}`: On successful simulation, where `response_map`
        contains the simulated LLM output.
      - `{:error, reason_string}`: If the `prompt_type` is unknown.
    """
    def request(prompt_type, input_data) do
      Logger.debug("[LLMService MOCK] Request: Type - #{prompt_type}, Input - #{inspect(input_data)}")
      # Simulate LLM responses
      case prompt_type do
        "filter_hyperchains" ->
          chains = Map.get(input_data, :chains, [])
          w = Map.get(input_data, :W, 1)
          {:ok, %{"filtered_chains" => Enum.take(chains, w)}}
        "extract_divisible_nodes" ->
          sample_nodes = Enum.map(1..(:rand.uniform(3) + 1), fn i ->
            %{id: "div_node_#{Ecto.UUID.generate()}_#{i}", content: "Simulated Divisible Node #{i}", type: :goal}
          end)
          {:ok, %{"divisible_nodes" => sample_nodes}}
        "select_node" ->
          divisible_nodes = Map.get(input_data, :divisible_nodes, [])
          if Enum.empty?(divisible_nodes) do
            {:ok, %{"selected_node" => nil}} # Simulate no node selected if input is empty
          else
            {:ok, %{"selected_node" => List.first(divisible_nodes)}} # Simulate selecting the first node
          end
        "retrieve_rules" ->
          sample_rules = Enum.map(1..(:rand.uniform(2) + 1), fn i ->
            %{id: "rule_#{Ecto.UUID.generate()}_#{i}", content: "Simulated Rule #{i}"}
          end)
          {:ok, %{"retrieved_rules" => sample_rules}}
        "expand_nodes" ->
          new_nodes = [%{id: "exp_node_#{Ecto.UUID.generate()}", content: "Simulated Expanded Node based on rule", type: :subgoal}]
          {:ok, %{"expanded_nodes" => new_nodes}}
        "select_optimal_hyperchain" ->
          hypertree = Map.get(input_data, :hypertree)
          # Simulate selecting the first hyperchain found, or a dummy if none
          case HyperchainExtractorOperator.call(%{"hypertree" => hypertree}) do
            {:ok, %{"hyperchains" => [first_chain | _]}} when not is_nil(first_chain) ->
              {:ok, %{"optimal_chain" => first_chain}}
            _ ->
              dummy_optimal_chain = HyperTreePlanner.DataStructures.Hyperchain.new([], [], %{status: "dummy_fallback_optimal_chain"})
              {:ok, %{"optimal_chain" => dummy_optimal_chain}}
          end
        _ ->
          Logger.error("[LLMService MOCK] Unknown prompt type: #{prompt_type}")
          {:error, "Unknown LLM prompt type: #{prompt_type}"}
      end
    end
  end

  # --- Public API ---
  @doc """
  Starts the `HyperTreePlannerAgent` GenServer.

  Accepts standard GenServer options. Can be used to start the agent with a specific name.

  ## Parameters
    - `opts`: A keyword list of options for `GenServer.start_link/3`. Defaults to `[]`.
      Commonly used option is `:name` to register the agent with a specific name.

  ## Examples

      iex> {:ok, pid} = HyperTreePlanner.Agents.HyperTreePlannerAgent.start_link(name: MyPlannerAgent)
      iex> is_pid(pid)
      true
  """
  def start_link(opts \\ []) do
    opts_keyword = if is_list(opts), do: opts, else: [] # Ensure opts is a keyword list
    GenServer.start_link(__MODULE__, opts_keyword, name: Keyword.get(opts_keyword, :name, __MODULE__))
  end

  @doc """
  Initiates the Top-down HyperTree Construction planning process.

  This is the main entry point for requesting a plan from the agent.
  It takes the agent's PID (or registered name) and a map of parameters.

  ## Parameters

    - `pid`: The PID or registered name of the `HyperTreePlannerAgent` process.
      Defaults to `HyperTreePlanner.Agents.HyperTreePlannerAgent` (the default registered name).
    - `params`: A map containing the input parameters for the planning algorithm:
      - `"rules"`: A list of rule maps (e.g., `[%{id: "r1", content: "Rule 1"}, ...]`).
      - `"query"`: A string representing the initial query `q`.
      - `"k_depth"`: An integer for the maximum reasoning depth `K`.
      - `"w_width"`: An integer for the maximum expansion width `W`.

  ## Returns

    - `{:ok, planning_outline_struct}`: On successful completion, where
      `planning_outline_struct` is a `HyperTreePlanner.DataStructures.PlanningOutline.t()`.
    - `{:error, reason_string}`: If there's an error during planning (e.g., invalid parameters).

  ## Examples

      iex> {:ok, agent_pid} = HyperTreePlanner.Agents.HyperTreePlannerAgent.start_link()
      iex> params = %{
      ...>   "rules" => [%{id: "rule1", content: "If A then B"}],
      ...>   "query" => "Achieve goal X",
      ...>   "k_depth" => 2,
      ...>   "w_width" => 1
      ...> }
      iex> {:ok, outline} = HyperTreePlanner.Agents.HyperTreePlannerAgent.plan_hyper_tree(agent_pid, params)
      iex> is_struct(outline, HyperTreePlanner.DataStructures.PlanningOutline)
      true
  """
  def plan_hyper_tree(pid \\ __MODULE__, params) do
    GenServer.call(pid, {:plan_hyper_tree, params})
  end

  # --- GenServer Callbacks ---
  @impl true
  @doc """
  Initializes the agent's state.

  Sets up an initial empty state with `nil` for rules, query, hypertree, etc.,
  and an empty `llm_cache`.
  """
  def init(_opts) do
    Logger.info("HyperTreePlannerAgent initialized.")
    initial_state = %{
      original_rules: nil,
      query: nil,
      k_depth: 0,
      w_width: 0,
      current_hypertree: nil,
      llm_cache: %{} # Initialize LLM cache
    }
    {:ok, initial_state}
  end

  @doc false # Private helper function, not part of the public API or GenServer behavior
  # Canonicalizes map input data for consistent cache key generation.
  # Sorts map keys to ensure that maps with the same content but different key order
  # produce the same cache key.
  defp canonical_input_for_key(input_data) do
    if is_map(input_data) do
      Map.to_list(input_data) |> Enum.sort()
    else
      input_data # For non-map inputs, use as is
    end
  end

  @doc false # Private helper function
  # Wraps LLMService.request with caching logic.
  # Checks the agent's llm_cache before making an actual LLM request.
  # Updates the cache with new responses.
  # Returns a tuple: {llm_response, updated_agent_state_with_cache}
  defp request_llm_with_cache(prompt_type, input_data, agent_state) do
    cache_key = {prompt_type, canonical_input_for_key(input_data)}
    llm_cache = agent_state.llm_cache

    case Map.get(llm_cache, cache_key) do
      nil -> # Cache MISS
        Logger.debug("[LLM Cache] MISS for key: #{inspect(prompt_type)}")
        llm_actual_response = LLMService.request(prompt_type, input_data)
        # Update cache only on successful LLM responses to avoid caching errors
        new_llm_cache =
          case llm_actual_response do
            {:ok, _} -> Map.put(llm_cache, cache_key, llm_actual_response)
            _ -> llm_cache # Don't cache errors
          end
        updated_agent_state = %{agent_state | llm_cache: new_llm_cache}
        {llm_actual_response, updated_agent_state}
      cached_response -> # Cache HIT
        Logger.debug("[LLM Cache] HIT for key: #{inspect(prompt_type)}")
        {cached_response, agent_state}
    end
  end

  @impl true
  @doc """
  Handles the `:plan_hyper_tree` call to execute Algorithm 1.

  This is the core logic of the agent. It orchestrates the calls to various
  operators and the LLMService (via `request_llm_with_cache`) to implement
  the steps of the Top-down HyperTree Construction algorithm.

  The main steps involve:
  1. Initializing the divisible set `D` and the hypertree `H`.
  2. Iterating `K` times (reasoning depth):
     a. Extracting hyperchains `C` from `H`.
     b. Filtering hyperchains if their count exceeds `W` (expansion width).
     c. For each selected hyperchain `Ci`:
        i. Extracting divisible nodes `g` from `D`.
        ii. Selecting the most promising node `gi*`.
        iii. Retrieving relevant rules `r` from `R`.
        iv. For each rule `rp`, expanding `gi*` to get new nodes `{si_p}`.
           (LLM calls for expansion are parallelized using `Task.async_stream`)
        v. Attaching `{si_p}` to `H`.
  3. After all iterations, selecting the optimal hyperchain `C*` from the final `H`.
  4. Constructing and returning the `PlanningOutline` based on `C*`.
  """
  def handle_call({:plan_hyper_tree, params}, _from, state) do
    Logger.info("Received request to plan hyper tree with params: #{inspect(params)}")

    rules_input = Map.get(params, "rules")
    query_content = Map.get(params, "query")
    k_depth = Map.get(params, "k_depth")
    w_width = Map.get(params, "w_width")

    # --- Input Validation ---
    if is_nil(rules_input) || not is_list(rules_input) ||
       is_nil(query_content) || not is_binary(query_content) ||
       not is_integer(k_depth) || k_depth <= 0 ||
       not is_integer(w_width) || w_width <= 0 do
      Logger.error("Invalid or missing parameters for plan_hyper_tree. K and W must be positive.")
      {:reply, {:error, "Invalid or missing parameters. K and W must be positive integers."}, state}
    else
      # --- Step 1 & 2: Initialize D (Divisible Set) and H (Hypertree) ---
      case RuleConverterOperator.call(%{"rules" => rules_input}) do
        {:ok, %{"divisible_set" => divisible_set_struct}} ->
          case InitializeHypertreeOperator.call(%{"query" => query_content}) do
            {:ok, %{"hypertree" => initial_hypertree_struct}} ->
              # Initial agent state for the planning loop
              current_planning_state = %{state | 
                original_rules: rules_input, 
                query: query_content, 
                k_depth: k_depth, 
                w_width: w_width, 
                current_hypertree: initial_hypertree_struct,
                llm_cache: %{} # Reset cache for each new plan_hyper_tree call
              }

              # --- Steps 3-12: Main Planning Loop (Iterate K times) ---
              {final_hypertree_after_k_iterations, final_state_after_k_iterations} =
                Enum.reduce(1..k_depth, {initial_hypertree_struct, current_planning_state}, fn d_iter, {current_h_for_depth_d, current_state_for_depth_d} ->
                  Logger.info("[Depth #{d_iter}/#{k_depth}] Starting iteration.")
                  # --- Step 4: Map(H) to get hyperchains {C1,...,Cm} ---
                  case HyperchainExtractorOperator.call(%{"hypertree" => current_h_for_depth_d}) do
                    {:ok, %{"hyperchains" => chains_from_h}} ->
                      # --- Step 5: Filter hyperchains if m > W ---
                      {filtered_chains_for_processing, state_after_filter_llm_call} =
                        if Enum.count(chains_from_h) > w_width do
                          llm_input_filter = %{chains: chains_from_h, W: w_width, hypertree: current_h_for_depth_d, query: query_content}
                          {filter_response, updated_state} = request_llm_with_cache("filter_hyperchains", llm_input_filter, current_state_for_depth_d)
                          filtered = 
                            case filter_response do
                              {:ok, %{"filtered_chains" => f_chains}} -> f_chains
                              _ -> 
                                Logger.warn("[Depth #{d_iter}] LLM for filtering chains failed or returned unexpected. Taking first W chains.")
                                Enum.take(chains_from_h, w_width) # Fallback
                            end
                          {filtered, updated_state}
                        else
                          {chains_from_h, current_state_for_depth_d} # No filtering needed
                        end

                      # --- Steps 6-12: Loop through selected hyperchains Ci ---
                      {h_after_all_chains_in_depth_d, state_after_all_chains_in_depth_d} =
                        Enum.reduce(filtered_chains_for_processing, {current_h_for_depth_d, state_after_filter_llm_call}, fn chain_ci, {h_acc_for_chain_ci, state_acc_for_chain_ci} ->
                          Logger.debug("[Depth #{d_iter}] Processing chain: #{inspect(chain_ci.id)}")
                          # --- Step 7: Extract divisible nodes g from D based on Ci ---
                          llm_input_div_nodes = %{chain: chain_ci, divisible_set: divisible_set_struct, query: query_content, hypertree: h_acc_for_chain_ci}
                          {div_nodes_resp, state_after_div_nodes_llm} = request_llm_with_cache("extract_divisible_nodes", llm_input_div_nodes, state_acc_for_chain_ci)
                          
                          case div_nodes_resp do
                            {:ok, %{"divisible_nodes" => divisible_nodes}} when is_list(divisible_nodes) and divisible_nodes != [] ->
                              # --- Step 8: Select most promising node gi* ---
                              llm_input_select_node = %{query: query_content, hypertree: h_acc_for_chain_ci, divisible_nodes: divisible_nodes, chain: chain_ci}
                              {select_node_resp, state_after_select_node_llm} = request_llm_with_cache("select_node", llm_input_select_node, state_after_div_nodes_llm)
                              
                              case select_node_resp do
                                {:ok, %{"selected_node" => gi_star}} when not is_nil(gi_star) and is_map(gi_star) and Map.has_key?(gi_star, :id) ->
                                  Logger.debug("[Depth #{d_iter}] Selected node gi*: #{inspect(gi_star.id)}")
                                  # --- Step 9: Retrieve relevant rules rp from R based on gi* ---
                                  llm_input_retrieve_rules = %{rules_db: rules_input, selected_node: gi_star, query: query_content, hypertree: h_acc_for_chain_ci, chain: chain_ci}
                                  {retrieve_rules_resp, state_after_retrieve_rules_llm} = request_llm_with_cache("retrieve_rules", llm_input_retrieve_rules, state_after_select_node_llm)
                                  
                                  case retrieve_rules_resp do
                                    {:ok, %{"retrieved_rules" => rules_rp_list}} when is_list(rules_rp_list) and rules_rp_list != [] ->
                                      Logger.debug("[Depth #{d_iter}] Retrieved #{Enum.count(rules_rp_list)} rules for node #{gi_star.id}.")
                                      # --- Steps 10-12: Loop through rules rp, expand gi*, attach {si_p} to H ---
                                      # Parallelize LLM calls for rule expansion
                                      state_before_rules_batch = state_after_retrieve_rules_llm
                                      h_before_rules_batch = h_acc_for_chain_ci

                                      {h_after_all_rules_for_gi_star, final_state_after_rules_batch} = 
                                        rules_rp_list
                                        |> Task.async_stream(
                                          fn rule_rp ->
                                            # Each task gets a snapshot of the hypertree and state for its LLM call
                                            llm_input_expand = %{query: query_content, chain: chain_ci, selected_node: gi_star, rule: rule_rp, hypertree: h_before_rules_batch}
                                            cache_key_expand = {"expand_nodes", canonical_input_for_key(llm_input_expand)}
                                            
                                            case Map.get(state_before_rules_batch.llm_cache, cache_key_expand) do
                                              nil -> # Cache MISS for this expansion task
                                                actual_llm_response_expand = LLMService.request("expand_nodes", llm_input_expand)
                                                {rule_rp, actual_llm_response_expand, :miss, llm_input_expand} # Pass llm_input for cache update
                                              cached_response_expand -> # Cache HIT for this expansion task
                                                {rule_rp, cached_response_expand, :hit, llm_input_expand}
                                            end
                                          end,
                                          ordered: false, # Results can be processed as they complete
                                          max_concurrency: System.schedulers_online() * 2, # Heuristic for concurrency
                                          timeout: 30_000 # 30s timeout for each LLM expansion task
                                        )
                                        |> Enum.reduce(
                                          {h_before_rules_batch, state_before_rules_batch}, # Initial accumulator for reduce
                                          fn
                                            # Case for successful task completion
                                            {:ok, {_rule_rp, llm_response_for_rule, cache_status_for_rule, llm_input_for_cache_key}}, {current_h_reduce, current_state_reduce} ->
                                              # Update LLM cache if it was a miss and successful
                                              updated_state_after_task = 
                                                if cache_status_for_rule == :miss do
                                                  case llm_response_for_rule do
                                                    {:ok, _} -> 
                                                      cache_key_update = {"expand_nodes", canonical_input_for_key(llm_input_for_cache_key)}
                                                      new_cache_after_task = Map.put(current_state_reduce.llm_cache, cache_key_update, llm_response_for_rule)
                                                      %{current_state_reduce | llm_cache: new_cache_after_task}
                                                    _ -> current_state_reduce # Don't update cache on LLM error
                                                  end
                                                else
                                                  current_state_reduce # No cache update needed for hits
                                                end

                                              # Attach nodes based on LLM response (sequentially)
                                              h_after_this_rule_attachment = 
                                                case llm_response_for_rule do
                                                  {:ok, %{"expanded_nodes" => si_p_nodes}} when is_list(si_p_nodes) and si_p_nodes != [] ->
                                                    parent_node_id_for_attach = gi_star.id # gi_star is a map with :id
                                                    case NodeAttacherOperator.call(%{"expanded_nodes" => si_p_nodes, "current_hypertree" => current_h_reduce, "parent_node_id" => parent_node_id_for_attach}) do
                                                      {:ok, %{"updated_hypertree" => h_after_attach}} -> h_after_attach
                                                      {:error, attach_err} -> 
                                                        Logger.error("[Depth #{d_iter}] NodeAttacherOperator failed: #{inspect(attach_err)}")
                                                        current_h_reduce 
                                                    end
                                                  _ -> 
                                                    Logger.debug("[Depth #{d_iter}] LLM for expanding node did not return valid nodes or failed.")
                                                    current_h_reduce # No nodes to attach or LLM error
                                                end
                                              {h_after_this_rule_attachment, updated_state_after_task}
                                            
                                            # Case for task failure
                                            {:exit, reason}, acc ->
                                              Logger.error("[Depth #{d_iter}] Task for rule expansion failed: #{inspect(reason)}")
                                              acc # Continue with accumulated H and state, skipping this failed task
                                          end)
                                      {h_after_all_rules_for_gi_star, final_state_after_rules_batch}
                                      
                                    _ -> 
                                      Logger.debug("[Depth #{d_iter}] No rules retrieved for node #{gi_star.id} or LLM error.")
                                      {h_acc_for_chain_ci, state_after_retrieve_rules_llm} # No rules, H and state unchanged from before rule retrieval
                                  end
                                _ -> 
                                  Logger.debug("[Depth #{d_iter}] No promising node gi* selected or LLM error.")
                                  {h_acc_for_chain_ci, state_after_select_node_llm} # No node selected, H and state unchanged
                              end
                            _ -> 
                              Logger.debug("[Depth #{d_iter}] No divisible nodes extracted for chain #{chain_ci.id} or LLM error.")
                              {h_acc_for_chain_ci, state_after_div_nodes_llm} # No divisible nodes, H and state unchanged
                          end
                        end)
                      # Return the hypertree and state accumulated after processing all chains in this depth
                      {h_after_all_chains_in_depth_d, state_after_all_chains_in_depth_d}
                    
                    {:error, extract_chains_err} -> 
                      Logger.error("[Depth #{d_iter}] HyperchainExtractorOperator failed: #{inspect(extract_chains_err)}")
                      {current_h_for_depth_d, current_state_for_depth_d} # Error extracting, H and state unchanged for this depth
                  end
                end)

              # --- Step 13: Select optimal hyperchain C* from final H ---
              llm_input_optimal_chain = %{hypertree: final_hypertree_after_k_iterations, query: query_content}
              {optimal_chain_response, final_agent_state_after_all} = request_llm_with_cache("select_optimal_hyperchain", llm_input_optimal_chain, final_state_after_k_iterations)
              
              case optimal_chain_response do
                {:ok, %{"optimal_chain" => optimal_chain_struct}} when not is_nil(optimal_chain_struct) and is_struct(optimal_chain_struct, HyperTreePlanner.DataStructures.Hyperchain) ->
                  Logger.info("Successfully selected optimal hyperchain: #{inspect(optimal_chain_struct.id)}")
                  planning_outline = PlanningOutline.new(optimal_chain_struct, %{generation_details: "Generated by HyperTreePlannerAgent after #{k_depth} iterations."})
                  {:reply, {:ok, planning_outline}, final_agent_state_after_all}
                _ ->
                  Logger.warn("Failed to select optimal hyperchain or received invalid structure. Returning fallback.")
                  # Fallback: create an empty/default planning outline
                  empty_chain_fallback = HyperTreePlanner.DataStructures.Hyperchain.new([], [], %{status: "fallback_empty_optimal_chain_selection_failed"})
                  planning_outline_fallback = PlanningOutline.new(empty_chain_fallback, %{generation_details: "Failed to select optimal hyperchain, providing fallback."})
                  {:reply, {:ok, planning_outline_fallback}, final_agent_state_after_all}
              end
            
            {:error, init_h_err} -> 
              Logger.error("Failed to initialize hypertree: #{inspect(init_h_err)}")
              {:reply, {:error, "Failed to initialize hypertree"}, state}
          end
        {:error, convert_r_err} -> 
          Logger.error("Failed to convert rules: #{inspect(convert_r_err)}")
          {:reply, {:error, "Failed to convert rules"}, state}
      end
    end
  end
end

