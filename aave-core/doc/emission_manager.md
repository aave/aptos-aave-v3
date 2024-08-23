
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emission_manager`



-  [Resource `EmissionManagerData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionManagerData)
-  [Struct `EmissionAdminUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionAdminUpdated)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_initialize)
-  [Function `emission_manager_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_address)
-  [Function `emission_manager_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_object)
-  [Function `configure_assets`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_configure_assets)
-  [Function `set_pull_rewards_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_pull_rewards_transfer_strategy)
-  [Function `set_staked_token_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_staked_token_transfer_strategy)
-  [Function `set_reward_oracle`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_reward_oracle)
-  [Function `set_distribution_end`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_distribution_end)
-  [Function `set_emission_per_second`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_per_second)
-  [Function `set_claimer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_claimer)
-  [Function `set_emission_admin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_admin)
-  [Function `set_rewards_controller`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_rewards_controller)
-  [Function `get_rewards_controller`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_rewards_controller)
-  [Function `get_emission_admin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_emission_admin)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::rewards_controller</a>;
<b>use</b> <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::transfer_strategy</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionManagerData"></a>

## Resource `EmissionManagerData`



<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionManagerData">EmissionManagerData</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionAdminUpdated"></a>

## Struct `EmissionAdminUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionAdminUpdated">EmissionAdminUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_ENOT_MANAGEMENT"></a>



<pre><code><b>const</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_ENOT_MANAGEMENT">ENOT_MANAGEMENT</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EMISSION_MANAGER_NAME"></a>



<pre><code><b>const</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EMISSION_MANAGER_NAME">EMISSION_MANAGER_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 73, 83, 83, 73, 79, 78, 95, 77, 65, 78, 65, 71, 69, 82];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_NOT_EMISSION_ADMIN"></a>



<pre><code><b>const</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_NOT_EMISSION_ADMIN">NOT_EMISSION_ADMIN</a>: u64 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_ONLY_EMISSION_ADMIN"></a>



<pre><code><b>const</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_ONLY_EMISSION_ADMIN">ONLY_EMISSION_ADMIN</a>: u64 = 3;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_initialize"></a>

## Function `initialize`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_initialize">initialize</a>(sender: &<a href="">signer</a>, <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller">rewards_controller</a>: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_address"></a>

## Function `emission_manager_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_address">emission_manager_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_object"></a>

## Function `emission_manager_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_emission_manager_object">emission_manager_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_EmissionManagerData">emission_manager::EmissionManagerData</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_configure_assets"></a>

## Function `configure_assets`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_configure_assets">configure_assets</a>(<a href="">account</a>: &<a href="">signer</a>, config: <a href="">vector</a>&lt;<a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_pull_rewards_transfer_strategy"></a>

## Function `set_pull_rewards_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_pull_rewards_transfer_strategy">set_pull_rewards_transfer_strategy</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_staked_token_transfer_strategy"></a>

## Function `set_staked_token_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_staked_token_transfer_strategy">set_staked_token_transfer_strategy</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, staked_token_transfer_strategy: <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_reward_oracle"></a>

## Function `set_reward_oracle`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_reward_oracle">set_reward_oracle</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, reward_oracle: <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_distribution_end"></a>

## Function `set_distribution_end`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_distribution_end">set_distribution_end</a>(caller: &<a href="">signer</a>, asset: <b>address</b>, reward: <b>address</b>, new_distribution_end: u32)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_per_second"></a>

## Function `set_emission_per_second`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_per_second">set_emission_per_second</a>(caller: &<a href="">signer</a>, asset: <b>address</b>, rewards: <a href="">vector</a>&lt;<b>address</b>&gt;, new_emissions_per_second: <a href="">vector</a>&lt;u128&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_claimer"></a>

## Function `set_claimer`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_claimer">set_claimer</a>(<a href="">account</a>: &<a href="">signer</a>, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, claimer: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_admin"></a>

## Function `set_emission_admin`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_emission_admin">set_emission_admin</a>(<a href="">account</a>: &<a href="">signer</a>, reward: <b>address</b>, new_admin: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_rewards_controller"></a>

## Function `set_rewards_controller`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_set_rewards_controller">set_rewards_controller</a>(<a href="">account</a>: &<a href="">signer</a>, controller: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_rewards_controller"></a>

## Function `get_rewards_controller`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_rewards_controller">get_rewards_controller</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_emission_admin"></a>

## Function `get_emission_admin`



<pre><code><b>public</b> <b>fun</b> <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager_get_emission_admin">get_emission_admin</a>(reward: <b>address</b>): <b>address</b>
</code></pre>
