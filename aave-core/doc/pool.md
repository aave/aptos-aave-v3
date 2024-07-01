
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool`



-  [Struct `ReserveInitialized`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveInitialized)
-  [Struct `ReserveDataUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveDataUpdated)
-  [Struct `MintedToTreasury`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_MintedToTreasury)
-  [Struct `IsolationModeTotalDebtUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_IsolationModeTotalDebtUpdated)
-  [Resource `ReserveExtendConfiguration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveExtendConfiguration)
-  [Resource `ReserveData`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData)
-  [Resource `ReserveList`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveList)
-  [Resource `ReserveAddressesList`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveAddressesList)
-  [Resource `UsersConfig`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_UsersConfig)
-  [Constants](#@Constants_0)
-  [Function `init_pool`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_pool)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_revision)
-  [Function `init_reserve`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_reserve)
-  [Function `drop_reserve`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_drop_reserve)
-  [Function `get_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data)
-  [Function `get_reserve_data_and_reserves_count`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data_and_reserves_count)
-  [Function `get_reserve_configuration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration)
-  [Function `get_reserves_count`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_count)
-  [Function `get_reserve_configuration_by_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration_by_reserve_data)
-  [Function `get_reserve_last_update_timestamp`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_last_update_timestamp)
-  [Function `get_reserve_id`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_id)
-  [Function `get_reserve_a_token_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_a_token_address)
-  [Function `set_reserve_accrued_to_treasury`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_accrued_to_treasury)
-  [Function `get_reserve_accrued_to_treasury`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_accrued_to_treasury)
-  [Function `get_reserve_variable_borrow_index`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_borrow_index)
-  [Function `get_reserve_liquidity_index`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_liquidity_index)
-  [Function `get_reserve_current_liquidity_rate`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_liquidity_rate)
-  [Function `get_reserve_current_variable_borrow_rate`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_variable_borrow_rate)
-  [Function `get_reserve_variable_debt_token_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_debt_token_address)
-  [Function `set_reserve_unbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_unbacked)
-  [Function `get_reserve_unbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_unbacked)
-  [Function `set_reserve_isolation_mode_total_debt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_isolation_mode_total_debt)
-  [Function `get_reserve_isolation_mode_total_debt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_isolation_mode_total_debt)
-  [Function `set_reserve_configuration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_configuration)
-  [Function `get_user_configuration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_user_configuration)
-  [Function `set_user_configuration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_user_configuration)
-  [Function `get_reserve_normalized_income`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_income)
-  [Function `get_normalized_income_by_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_income_by_reserve_data)
-  [Function `update_state`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_state)
-  [Function `get_reserve_normalized_variable_debt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_variable_debt)
-  [Function `get_normalized_debt_by_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_debt_by_reserve_data)
-  [Function `get_reserves_list`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_list)
-  [Function `get_reserve_address_by_id`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_address_by_id)
-  [Function `mint_to_treasury`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_mint_to_treasury)
-  [Function `get_bridge_protocol_fee`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_bridge_protocol_fee)
-  [Function `set_bridge_protocol_fee`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_bridge_protocol_fee)
-  [Function `get_flashloan_premium_total`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_total)
-  [Function `set_flashloan_premiums`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_flashloan_premiums)
-  [Function `get_flashloan_premium_to_protocol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_to_protocol)
-  [Function `max_number_reserves`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_max_number_reserves)
-  [Function `update_interest_rates`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_interest_rates)
-  [Function `get_isolation_mode_state`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_isolation_mode_state)
-  [Function `get_siloed_borrowing_state`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_siloed_borrowing_state)
-  [Function `cumulate_to_liquidity_index`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_cumulate_to_liquidity_index)
-  [Function `reset_isolation_mode_total_debt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_reset_isolation_mode_total_debt)
-  [Function `rescue_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_rescue_tokens)
-  [Function `scale_a_token_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_total_supply)
-  [Function `scale_a_token_balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_balance_of)
-  [Function `scale_variable_token_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_total_supply)
-  [Function `scale_variable_token_balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_balance_of)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::default_reserve_interest_rate_strategy</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveInitialized"></a>

## Struct `ReserveInitialized`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveInitialized">ReserveInitialized</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveDataUpdated"></a>

## Struct `ReserveDataUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveDataUpdated">ReserveDataUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_MintedToTreasury"></a>

## Struct `MintedToTreasury`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_MintedToTreasury">MintedToTreasury</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveExtendConfiguration"></a>

## Resource `ReserveExtendConfiguration`



<pre><code><b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveExtendConfiguration">ReserveExtendConfiguration</a> <b>has</b> drop, store, key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData"></a>

## Resource `ReserveData`



<pre><code><b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">ReserveData</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveList"></a>

## Resource `ReserveList`



<pre><code><b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveList">ReserveList</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveAddressesList"></a>

## Resource `ReserveAddressesList`



<pre><code><b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveAddressesList">ReserveAddressesList</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_UsersConfig"></a>

## Resource `UsersConfig`



<pre><code><b>struct</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_UsersConfig">UsersConfig</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_POOL_REVISION"></a>



<pre><code><b>const</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_POOL_REVISION">POOL_REVISION</a>: u256 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_pool"></a>

## Function `init_pool`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_pool">init_pool</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_reserve"></a>

## Function `init_reserve`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_init_reserve">init_reserve</a>(<a href="">account</a>: &<a href="">signer</a>, underlying_asset: <b>address</b>, underlying_asset_decimals: u8, treasury: <b>address</b>, a_token_name: <a href="_String">string::String</a>, a_token_symbol: <a href="_String">string::String</a>, variable_debt_token_name: <a href="_String">string::String</a>, variable_debt_token_symbol: <a href="_String">string::String</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_drop_reserve"></a>

## Function `drop_reserve`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_drop_reserve">drop_reserve</a>(asset: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data"></a>

## Function `get_reserve_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data">get_reserve_data</a>(asset: <b>address</b>): <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data_and_reserves_count"></a>

## Function `get_reserve_data_and_reserves_count`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_data_and_reserves_count">get_reserve_data_and_reserves_count</a>(asset: <b>address</b>): (<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration"></a>

## Function `get_reserve_configuration`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration">get_reserve_configuration</a>(asset: <b>address</b>): <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_count"></a>

## Function `get_reserves_count`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_count">get_reserves_count</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration_by_reserve_data"></a>

## Function `get_reserve_configuration_by_reserve_data`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_configuration_by_reserve_data">get_reserve_configuration_by_reserve_data</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_last_update_timestamp"></a>

## Function `get_reserve_last_update_timestamp`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_last_update_timestamp">get_reserve_last_update_timestamp</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u64
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_id"></a>

## Function `get_reserve_id`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_id">get_reserve_id</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_a_token_address"></a>

## Function `get_reserve_a_token_address`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_a_token_address">get_reserve_a_token_address</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_accrued_to_treasury"></a>

## Function `set_reserve_accrued_to_treasury`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_accrued_to_treasury">set_reserve_accrued_to_treasury</a>(asset: <b>address</b>, accrued_to_treasury: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_accrued_to_treasury"></a>

## Function `get_reserve_accrued_to_treasury`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_accrued_to_treasury">get_reserve_accrued_to_treasury</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_borrow_index"></a>

## Function `get_reserve_variable_borrow_index`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_borrow_index">get_reserve_variable_borrow_index</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_liquidity_index"></a>

## Function `get_reserve_liquidity_index`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_liquidity_index">get_reserve_liquidity_index</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_liquidity_rate"></a>

## Function `get_reserve_current_liquidity_rate`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_liquidity_rate">get_reserve_current_liquidity_rate</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_variable_borrow_rate"></a>

## Function `get_reserve_current_variable_borrow_rate`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_current_variable_borrow_rate">get_reserve_current_variable_borrow_rate</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_debt_token_address"></a>

## Function `get_reserve_variable_debt_token_address`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_variable_debt_token_address">get_reserve_variable_debt_token_address</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_unbacked"></a>

## Function `set_reserve_unbacked`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_unbacked">set_reserve_unbacked</a>(asset: <b>address</b>, unbacked: u128)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_unbacked"></a>

## Function `get_reserve_unbacked`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_unbacked">get_reserve_unbacked</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_isolation_mode_total_debt"></a>

## Function `set_reserve_isolation_mode_total_debt`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_isolation_mode_total_debt">set_reserve_isolation_mode_total_debt</a>(asset: <b>address</b>, isolation_mode_total_debt: u128)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_isolation_mode_total_debt"></a>

## Function `get_reserve_isolation_mode_total_debt`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_isolation_mode_total_debt">get_reserve_isolation_mode_total_debt</a>(<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_configuration"></a>

## Function `set_reserve_configuration`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_reserve_configuration">set_reserve_configuration</a>(asset: <b>address</b>, reserve_config_map: <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_user_configuration"></a>

## Function `get_user_configuration`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_user_configuration">get_user_configuration</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>): <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_user_configuration"></a>

## Function `set_user_configuration`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_user_configuration">set_user_configuration</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, user_config_map: <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_income"></a>

## Function `get_reserve_normalized_income`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_income">get_reserve_normalized_income</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_income_by_reserve_data"></a>

## Function `get_normalized_income_by_reserve_data`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_income_by_reserve_data">get_normalized_income_by_reserve_data</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_state"></a>

## Function `update_state`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_state">update_state</a>(asset: <b>address</b>, reserve_data: &<b>mut</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_variable_debt"></a>

## Function `get_reserve_normalized_variable_debt`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_normalized_variable_debt">get_reserve_normalized_variable_debt</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_debt_by_reserve_data"></a>

## Function `get_normalized_debt_by_reserve_data`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_normalized_debt_by_reserve_data">get_normalized_debt_by_reserve_data</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_list"></a>

## Function `get_reserves_list`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserves_list">get_reserves_list</a>(): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_address_by_id"></a>

## Function `get_reserve_address_by_id`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_reserve_address_by_id">get_reserve_address_by_id</a>(id: u256): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_mint_to_treasury"></a>

## Function `mint_to_treasury`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_mint_to_treasury">mint_to_treasury</a>(assets: <a href="">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_bridge_protocol_fee"></a>

## Function `get_bridge_protocol_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_bridge_protocol_fee">get_bridge_protocol_fee</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_bridge_protocol_fee"></a>

## Function `set_bridge_protocol_fee`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_bridge_protocol_fee">set_bridge_protocol_fee</a>(protocol_fee: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_total"></a>

## Function `get_flashloan_premium_total`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_total">get_flashloan_premium_total</a>(): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_flashloan_premiums"></a>

## Function `set_flashloan_premiums`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_set_flashloan_premiums">set_flashloan_premiums</a>(flash_loan_premium_total: u128, flash_loan_premium_to_protocol: u128)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_to_protocol"></a>

## Function `get_flashloan_premium_to_protocol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_flashloan_premium_to_protocol">get_flashloan_premium_to_protocol</a>(): u128
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_max_number_reserves"></a>

## Function `max_number_reserves`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_max_number_reserves">max_number_reserves</a>(): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_interest_rates"></a>

## Function `update_interest_rates`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_update_interest_rates">update_interest_rates</a>(reserve_data: &<b>mut</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, reserve_address: <b>address</b>, liquidity_added: u256, liquidity_taken: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_isolation_mode_state"></a>

## Function `get_isolation_mode_state`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_isolation_mode_state">get_isolation_mode_state</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): (bool, <b>address</b>, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_siloed_borrowing_state"></a>

## Function `get_siloed_borrowing_state`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_get_siloed_borrowing_state">get_siloed_borrowing_state</a>(<a href="">account</a>: <b>address</b>): (bool, <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_cumulate_to_liquidity_index"></a>

## Function `cumulate_to_liquidity_index`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_cumulate_to_liquidity_index">cumulate_to_liquidity_index</a>(asset: <b>address</b>, reserve_data: &<b>mut</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, total_liquidity: u256, amount: u256): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_reset_isolation_mode_total_debt"></a>

## Function `reset_isolation_mode_total_debt`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_reset_isolation_mode_total_debt">reset_isolation_mode_total_debt</a>(asset: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_rescue_tokens"></a>

## Function `rescue_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_rescue_tokens">rescue_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, token: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_total_supply"></a>

## Function `scale_a_token_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_total_supply">scale_a_token_total_supply</a>(a_token_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_balance_of"></a>

## Function `scale_a_token_balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_a_token_balance_of">scale_a_token_balance_of</a>(owner: <b>address</b>, a_token_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_total_supply"></a>

## Function `scale_variable_token_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_total_supply">scale_variable_token_total_supply</a>(variable_debt_token_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_balance_of"></a>

## Function `scale_variable_token_balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_scale_variable_token_balance_of">scale_variable_token_balance_of</a>(owner: <b>address</b>, variable_debt_token_address: <b>address</b>): u256
</code></pre>
