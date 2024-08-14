
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::rewards_controller`



-  [Resource `RewardsControllerData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsControllerData)
-  [Resource `AssetData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetData)
-  [Resource `RewardData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardData)
-  [Resource `UserData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserData)
-  [Struct `UserAssetBalance`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserAssetBalance)
-  [Struct `ClaimerSet`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ClaimerSet)
-  [Struct `Accrued`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_Accrued)
-  [Struct `AssetConfigUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetConfigUpdated)
-  [Struct `RewardsClaimed`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsClaimed)
-  [Struct `RewardOracleUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardOracleUpdated)
-  [Struct `PullRewardsTransferStrategyInstalled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_PullRewardsTransferStrategyInstalled)
-  [Struct `StakedTokenTransferStrategyInstalled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_StakedTokenTransferStrategyInstalled)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_initialize)
-  [Function `create_asset_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_create_asset_data)
-  [Function `rewards_controller_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_address)
-  [Function `rewards_controller_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_object)
-  [Function `get_claimer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_claimer)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_revision)
-  [Function `get_reward_oracle`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_reward_oracle)
-  [Function `get_pull_rewards_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_pull_rewards_transfer_strategy)
-  [Function `get_staked_token_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_staked_token_transfer_strategy)
-  [Function `configure_assets`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_configure_assets)
-  [Function `set_pull_rewards_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_pull_rewards_transfer_strategy)
-  [Function `set_staked_token_transfer_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_staked_token_transfer_strategy)
-  [Function `set_reward_oracle`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle)
-  [Function `claim_rewards`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_rewards)
-  [Function `claim_all_rewards`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_all_rewards)
-  [Function `set_claimer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_claimer)
-  [Function `set_reward_oracle_internal`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle_internal)
-  [Function `get_rewards_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_data)
-  [Function `get_asset_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_index)
-  [Function `get_distribution_end`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_distribution_end)
-  [Function `get_rewards_by_asset`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_by_asset)
-  [Function `get_rewards_list`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_list)
-  [Function `get_user_asset_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_asset_index)
-  [Function `get_user_accrued_rewards`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_accrued_rewards)
-  [Function `get_user_rewards`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_rewards)
-  [Function `get_all_user_rewards`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_all_user_rewards)
-  [Function `set_distribution_end`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_distribution_end)
-  [Function `set_emission_per_second`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_emission_per_second)
-  [Function `get_asset_decimals`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_decimals)
-  [Function `get_emission_manager`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_emission_manager)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::simple_map</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::transfer_strategy</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsControllerData"></a>

## Resource `RewardsControllerData`



<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsControllerData">RewardsControllerData</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetData"></a>

## Resource `AssetData`



<pre><code><b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetData">AssetData</a> <b>has</b> drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardData"></a>

## Resource `RewardData`



<pre><code><b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardData">RewardData</a> <b>has</b> drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserData"></a>

## Resource `UserData`



<pre><code><b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserData">UserData</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserAssetBalance"></a>

## Struct `UserAssetBalance`



<pre><code><b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_UserAssetBalance">UserAssetBalance</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ClaimerSet"></a>

## Struct `ClaimerSet`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ClaimerSet">ClaimerSet</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_Accrued"></a>

## Struct `Accrued`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_Accrued">Accrued</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetConfigUpdated"></a>

## Struct `AssetConfigUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetConfigUpdated">AssetConfigUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsClaimed"></a>

## Struct `RewardsClaimed`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsClaimed">RewardsClaimed</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardOracleUpdated"></a>

## Struct `RewardOracleUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardOracleUpdated">RewardOracleUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_PullRewardsTransferStrategyInstalled"></a>

## Struct `PullRewardsTransferStrategyInstalled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_PullRewardsTransferStrategyInstalled">PullRewardsTransferStrategyInstalled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_StakedTokenTransferStrategyInstalled"></a>

## Struct `StakedTokenTransferStrategyInstalled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_StakedTokenTransferStrategyInstalled">StakedTokenTransferStrategyInstalled</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_REVISION"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_REVISION">REVISION</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_CLAIMER_UNAUTHORIZED"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_CLAIMER_UNAUTHORIZED">CLAIMER_UNAUTHORIZED</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_DISTRIBUTION_DOES_NOT_EXIST"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_DISTRIBUTION_DOES_NOT_EXIST">DISTRIBUTION_DOES_NOT_EXIST</a>: u64 = 5;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_INDEX_OVERFLOW"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_INDEX_OVERFLOW">INDEX_OVERFLOW</a>: u64 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_INVALID_INPUT"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_INVALID_INPUT">INVALID_INPUT</a>: u64 = 4;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_NOT_REWARDS_CONTROLLER_ADMIN"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_NOT_REWARDS_CONTROLLER_ADMIN">NOT_REWARDS_CONTROLLER_ADMIN</a>: u64 = 8;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ONLY_EMISSION_MANAGER"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ONLY_EMISSION_MANAGER">ONLY_EMISSION_MANAGER</a>: u64 = 3;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ORACLE_MUST_RETURN_PRICE"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_ORACLE_MUST_RETURN_PRICE">ORACLE_MUST_RETURN_PRICE</a>: u64 = 6;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_REWARDS_CONTROLLER_NAME"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_REWARDS_CONTROLLER_NAME">REWARDS_CONTROLLER_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [82, 69, 87, 65, 82, 68, 83, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 82, 95, 78, 65, 77, 69];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_TRANSFER_ERROR"></a>



<pre><code><b>const</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_TRANSFER_ERROR">TRANSFER_ERROR</a>: u64 = 7;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_initialize"></a>

## Function `initialize`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_initialize">initialize</a>(sender: &<a href="">signer</a>, <a href="emission_manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emission_manager">emission_manager</a>: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_create_asset_data"></a>

## Function `create_asset_data`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_create_asset_data">create_asset_data</a>(rewards: <a href="_SimpleMap">simple_map::SimpleMap</a>&lt;<b>address</b>, <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardData">rewards_controller::RewardData</a>&gt;, available_rewards: <a href="_SimpleMap">simple_map::SimpleMap</a>&lt;u128, <b>address</b>&gt;, available_rewards_count: u128, decimals: u8): <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_AssetData">rewards_controller::AssetData</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_address"></a>

## Function `rewards_controller_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_address">rewards_controller_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_object"></a>

## Function `rewards_controller_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_rewards_controller_object">rewards_controller_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_RewardsControllerData">rewards_controller::RewardsControllerData</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_claimer"></a>

## Function `get_claimer`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_claimer">get_claimer</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, rewards_controller_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_revision">get_revision</a>(): u64
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_reward_oracle"></a>

## Function `get_reward_oracle`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_reward_oracle">get_reward_oracle</a>(reward: <b>address</b>, rewards_controller_address: <b>address</b>): <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_pull_rewards_transfer_strategy"></a>

## Function `get_pull_rewards_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_pull_rewards_transfer_strategy">get_pull_rewards_transfer_strategy</a>(reward: <b>address</b>, rewards_controller_address: <b>address</b>): <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_staked_token_transfer_strategy"></a>

## Function `get_staked_token_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_staked_token_transfer_strategy">get_staked_token_transfer_strategy</a>(reward: <b>address</b>, rewards_controller_address: <b>address</b>): <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_configure_assets"></a>

## Function `configure_assets`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_configure_assets">configure_assets</a>(caller: &<a href="">signer</a>, config: <a href="">vector</a>&lt;<a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>&gt;, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_pull_rewards_transfer_strategy"></a>

## Function `set_pull_rewards_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_pull_rewards_transfer_strategy">set_pull_rewards_transfer_strategy</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_staked_token_transfer_strategy"></a>

## Function `set_staked_token_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_staked_token_transfer_strategy">set_staked_token_transfer_strategy</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, staked_token_transfer_strategy: <a href="transfer_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle"></a>

## Function `set_reward_oracle`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle">set_reward_oracle</a>(caller: &<a href="">signer</a>, reward: <b>address</b>, reward_oracle: <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_rewards"></a>

## Function `claim_rewards`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_rewards">claim_rewards</a>(caller: &<a href="">signer</a>, assets: <a href="">vector</a>&lt;<b>address</b>&gt;, amount: u256, <b>to</b>: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_all_rewards"></a>

## Function `claim_all_rewards`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_claim_all_rewards">claim_all_rewards</a>(caller: &<a href="">signer</a>, assets: <a href="">vector</a>&lt;<b>address</b>&gt;, <b>to</b>: <b>address</b>, rewards_controller_address: <b>address</b>): (<a href="">vector</a>&lt;<b>address</b>&gt;, <a href="">vector</a>&lt;u256&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_claimer"></a>

## Function `set_claimer`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_claimer">set_claimer</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, claimer: <b>address</b>, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle_internal"></a>

## Function `set_reward_oracle_internal`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_reward_oracle_internal">set_reward_oracle_internal</a>(reward: <b>address</b>, reward_oracle: <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_data"></a>

## Function `get_rewards_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_data">get_rewards_data</a>(asset: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): (u256, u256, u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_index"></a>

## Function `get_asset_index`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_index">get_asset_index</a>(asset: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): (u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_distribution_end"></a>

## Function `get_distribution_end`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_distribution_end">get_distribution_end</a>(asset: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_by_asset"></a>

## Function `get_rewards_by_asset`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_by_asset">get_rewards_by_asset</a>(asset: <b>address</b>, rewards_controller_address: <b>address</b>): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_list"></a>

## Function `get_rewards_list`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_rewards_list">get_rewards_list</a>(rewards_controller_address: <b>address</b>): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_asset_index"></a>

## Function `get_user_asset_index`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_asset_index">get_user_asset_index</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, asset: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_accrued_rewards"></a>

## Function `get_user_accrued_rewards`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_accrued_rewards">get_user_accrued_rewards</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_rewards"></a>

## Function `get_user_rewards`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_user_rewards">get_user_rewards</a>(assets: <a href="">vector</a>&lt;<b>address</b>&gt;, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, reward: <b>address</b>, rewards_controller_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_all_user_rewards"></a>

## Function `get_all_user_rewards`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_all_user_rewards">get_all_user_rewards</a>(assets: <a href="">vector</a>&lt;<b>address</b>&gt;, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, rewards_controller_address: <b>address</b>): (<a href="">vector</a>&lt;<b>address</b>&gt;, <a href="">vector</a>&lt;u256&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_distribution_end"></a>

## Function `set_distribution_end`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_distribution_end">set_distribution_end</a>(caller: &<a href="">signer</a>, asset: <b>address</b>, reward: <b>address</b>, new_distribution_end: u32, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_emission_per_second"></a>

## Function `set_emission_per_second`



<pre><code><b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_set_emission_per_second">set_emission_per_second</a>(caller: &<a href="">signer</a>, asset: <b>address</b>, rewards: <a href="">vector</a>&lt;<b>address</b>&gt;, new_emissions_per_second: <a href="">vector</a>&lt;u128&gt;, rewards_controller_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_decimals"></a>

## Function `get_asset_decimals`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_asset_decimals">get_asset_decimals</a>(asset: <b>address</b>, rewards_controller_address: <b>address</b>): u8
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_emission_manager"></a>

## Function `get_emission_manager`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller_get_emission_manager">get_emission_manager</a>(rewards_controller_address: <b>address</b>): <b>address</b>
</code></pre>
