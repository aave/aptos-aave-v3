
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::transfer_strategy`



-  [Resource `PullRewardsTransferStrategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy)
-  [Resource `StakedTokenTransferStrategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy)
-  [Struct `RewardsConfigInput`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput)
-  [Struct `EmergencyWithdrawal`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_EmergencyWithdrawal)
-  [Constants](#@Constants_0)
-  [Function `check_is_emission_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_check_is_emission_admin)
-  [Function `create_pull_rewards_transfer_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_pull_rewards_transfer_strategy)
-  [Function `pull_rewards_transfer_strategy_perform_transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_perform_transfer)
-  [Function `pull_rewards_transfer_strategy_get_rewards_vault`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_vault)
-  [Function `pull_rewards_transfer_strategy_get_incentives_controller`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_incentives_controller)
-  [Function `pull_rewards_transfer_strategy_get_rewards_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_admin)
-  [Function `create_staked_token_transfer_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_staked_token_transfer_strategy)
-  [Function `staked_token_transfer_strategy_perform_transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_perform_transfer)
-  [Function `staked_token_transfer_strategy_get_stake_contract`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_stake_contract)
-  [Function `staked_token_transfer_strategy_get_underlying_token`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_underlying_token)
-  [Function `staked_token_transfer_strategy_get_incentives_controller`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_incentives_controller)
-  [Function `staked_token_transfer_strategy_get_rewards_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_rewards_admin)
-  [Function `get_reward`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward)
-  [Function `get_reward_oracle`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward_oracle)
-  [Function `get_asset`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_asset)
-  [Function `get_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_total_supply)
-  [Function `get_emission_per_second`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_emission_per_second)
-  [Function `get_distribution_end`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_distribution_end)
-  [Function `set_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_set_total_supply)
-  [Function `pull_rewards_transfer_strategy_get_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_strategy)
-  [Function `staked_token_transfer_strategy_get_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_strategy)
-  [Function `validate_rewards_config_input`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_validate_rewards_config_input)
-  [Function `has_pull_rewards_transfer_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_has_pull_rewards_transfer_strategy)
-  [Function `emit_emergency_withdrawal_event`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_emit_emergency_withdrawal_event)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="staked_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_staked_token">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::staked_token</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy"></a>

## Resource `PullRewardsTransferStrategy`



<pre><code><b>struct</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">PullRewardsTransferStrategy</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy"></a>

## Resource `StakedTokenTransferStrategy`



<pre><code><b>struct</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">StakedTokenTransferStrategy</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput"></a>

## Struct `RewardsConfigInput`



<pre><code><b>struct</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">RewardsConfigInput</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_EmergencyWithdrawal"></a>

## Struct `EmergencyWithdrawal`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_EmergencyWithdrawal">EmergencyWithdrawal</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_CALLER_NOT_INCENTIVES_CONTROLLER"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_CALLER_NOT_INCENTIVES_CONTROLLER">CALLER_NOT_INCENTIVES_CONTROLLER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_EMISSION_MANAGER_NAME"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_EMISSION_MANAGER_NAME">EMISSION_MANAGER_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 73, 83, 83, 73, 79, 78, 95, 77, 65, 78, 65, 71, 69, 82];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_NOT_EMISSION_ADMIN"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_NOT_EMISSION_ADMIN">NOT_EMISSION_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_ONLY_REWARDS_ADMIN"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_ONLY_REWARDS_ADMIN">ONLY_REWARDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_REWARD_TOKEN_NOT_STAKE_CONTRACT"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_REWARD_TOKEN_NOT_STAKE_CONTRACT">REWARD_TOKEN_NOT_STAKE_CONTRACT</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_TOO_MANY_STRATEGIES"></a>



<pre><code><b>const</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_TOO_MANY_STRATEGIES">TOO_MANY_STRATEGIES</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_check_is_emission_admin"></a>

## Function `check_is_emission_admin`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_check_is_emission_admin">check_is_emission_admin</a>(<a href="">account</a>: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_pull_rewards_transfer_strategy"></a>

## Function `create_pull_rewards_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_pull_rewards_transfer_strategy">create_pull_rewards_transfer_strategy</a>(rewards_admin: <b>address</b>, incentives_controller: <b>address</b>, rewards_vault: <b>address</b>): <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_perform_transfer"></a>

## Function `pull_rewards_transfer_strategy_perform_transfer`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_perform_transfer">pull_rewards_transfer_strategy_perform_transfer</a>(caller: &<a href="">signer</a>, <b>to</b>: <b>address</b>, reward: <b>address</b>, amount: u256, pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_vault"></a>

## Function `pull_rewards_transfer_strategy_get_rewards_vault`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_vault">pull_rewards_transfer_strategy_get_rewards_vault</a>(pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_incentives_controller"></a>

## Function `pull_rewards_transfer_strategy_get_incentives_controller`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_incentives_controller">pull_rewards_transfer_strategy_get_incentives_controller</a>(pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_admin"></a>

## Function `pull_rewards_transfer_strategy_get_rewards_admin`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_rewards_admin">pull_rewards_transfer_strategy_get_rewards_admin</a>(pull_rewards_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_staked_token_transfer_strategy"></a>

## Function `create_staked_token_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_create_staked_token_transfer_strategy">create_staked_token_transfer_strategy</a>(rewards_admin: <b>address</b>, incentives_controller: <b>address</b>, stake_contract: <a href="staked_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_staked_token_MockStakedToken">staked_token::MockStakedToken</a>, underlying_token: <b>address</b>): <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_perform_transfer"></a>

## Function `staked_token_transfer_strategy_perform_transfer`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_perform_transfer">staked_token_transfer_strategy_perform_transfer</a>(caller: &<a href="">signer</a>, <b>to</b>: <b>address</b>, reward: <b>address</b>, amount: u256, staked_token_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_stake_contract"></a>

## Function `staked_token_transfer_strategy_get_stake_contract`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_stake_contract">staked_token_transfer_strategy_get_stake_contract</a>(staked_token_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_underlying_token"></a>

## Function `staked_token_transfer_strategy_get_underlying_token`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_underlying_token">staked_token_transfer_strategy_get_underlying_token</a>(staked_token_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_incentives_controller"></a>

## Function `staked_token_transfer_strategy_get_incentives_controller`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_incentives_controller">staked_token_transfer_strategy_get_incentives_controller</a>(staked_token_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_rewards_admin"></a>

## Function `staked_token_transfer_strategy_get_rewards_admin`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_rewards_admin">staked_token_transfer_strategy_get_rewards_admin</a>(staked_token_transfer_strategy: <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward"></a>

## Function `get_reward`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward">get_reward</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward_oracle"></a>

## Function `get_reward_oracle`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_reward_oracle">get_reward_oracle</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_RewardOracle">oracle::RewardOracle</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_asset"></a>

## Function `get_asset`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_asset">get_asset</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_total_supply"></a>

## Function `get_total_supply`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_total_supply">get_total_supply</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_emission_per_second"></a>

## Function `get_emission_per_second`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_emission_per_second">get_emission_per_second</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_distribution_end"></a>

## Function `get_distribution_end`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_get_distribution_end">get_distribution_end</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): u32
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_set_total_supply"></a>

## Function `set_total_supply`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_set_total_supply">set_total_supply</a>(rewards_config_input: &<b>mut</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>, total_supply: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_strategy"></a>

## Function `pull_rewards_transfer_strategy_get_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_pull_rewards_transfer_strategy_get_strategy">pull_rewards_transfer_strategy_get_strategy</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_PullRewardsTransferStrategy">transfer_strategy::PullRewardsTransferStrategy</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_strategy"></a>

## Function `staked_token_transfer_strategy_get_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_staked_token_transfer_strategy_get_strategy">staked_token_transfer_strategy_get_strategy</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_StakedTokenTransferStrategy">transfer_strategy::StakedTokenTransferStrategy</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_validate_rewards_config_input"></a>

## Function `validate_rewards_config_input`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_validate_rewards_config_input">validate_rewards_config_input</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_has_pull_rewards_transfer_strategy"></a>

## Function `has_pull_rewards_transfer_strategy`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_has_pull_rewards_transfer_strategy">has_pull_rewards_transfer_strategy</a>(rewards_config_input: &<a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_RewardsConfigInput">transfer_strategy::RewardsConfigInput</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_emit_emergency_withdrawal_event"></a>

## Function `emit_emergency_withdrawal_event`



<pre><code><b>public</b> <b>fun</b> <a href="transfer_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_transfer_strategy_emit_emergency_withdrawal_event">emit_emergency_withdrawal_event</a>(caller: &<a href="">signer</a>, token: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256)
</code></pre>
