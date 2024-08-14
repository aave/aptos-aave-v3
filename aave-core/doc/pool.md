
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool`



-  [Struct `ReserveInitialized`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveInitialized)
-  [Struct `ReserveDataUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveDataUpdated)
-  [Struct `MintedToTreasury`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_MintedToTreasury)
-  [Struct `IsolationModeTotalDebtUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_IsolationModeTotalDebtUpdated)
-  [Resource `ReserveExtendConfiguration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveExtendConfiguration)
-  [Resource `ReserveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData)
-  [Resource `ReserveList`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveList)
-  [Resource `ReserveAddressesList`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveAddressesList)
-  [Resource `UsersConfig`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_UsersConfig)
-  [Constants](#@Constants_0)
-  [Function `init_pool`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_pool)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_revision)
-  [Function `init_reserve`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_reserve)
-  [Function `drop_reserve`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_drop_reserve)
-  [Function `get_reserve_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data)
-  [Function `get_reserve_data_and_reserves_count`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data_and_reserves_count)
-  [Function `get_reserve_configuration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration)
-  [Function `get_reserves_count`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_count)
-  [Function `get_reserve_configuration_by_reserve_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration_by_reserve_data)
-  [Function `get_reserve_last_update_timestamp`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_last_update_timestamp)
-  [Function `get_reserve_id`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_id)
-  [Function `get_reserve_a_token_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_a_token_address)
-  [Function `set_reserve_accrued_to_treasury`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_accrued_to_treasury)
-  [Function `get_reserve_accrued_to_treasury`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_accrued_to_treasury)
-  [Function `get_reserve_variable_borrow_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_borrow_index)
-  [Function `get_reserve_liquidity_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_liquidity_index)
-  [Function `get_reserve_current_liquidity_rate`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_liquidity_rate)
-  [Function `get_reserve_current_variable_borrow_rate`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_variable_borrow_rate)
-  [Function `get_reserve_variable_debt_token_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_debt_token_address)
-  [Function `set_reserve_unbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_unbacked)
-  [Function `get_reserve_unbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_unbacked)
-  [Function `set_reserve_isolation_mode_total_debt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_isolation_mode_total_debt)
-  [Function `get_reserve_isolation_mode_total_debt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_isolation_mode_total_debt)
-  [Function `set_reserve_configuration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_configuration)
-  [Function `get_user_configuration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_user_configuration)
-  [Function `set_user_configuration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_user_configuration)
-  [Function `get_reserve_normalized_income`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_income)
-  [Function `get_normalized_income_by_reserve_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_income_by_reserve_data)
-  [Function `update_state`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_state)
-  [Function `get_reserve_normalized_variable_debt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_variable_debt)
-  [Function `get_normalized_debt_by_reserve_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_debt_by_reserve_data)
-  [Function `get_reserves_list`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_list)
-  [Function `get_reserve_address_by_id`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_address_by_id)
-  [Function `mint_to_treasury`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_mint_to_treasury)
-  [Function `get_bridge_protocol_fee`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_bridge_protocol_fee)
-  [Function `set_bridge_protocol_fee`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_bridge_protocol_fee)
-  [Function `get_flashloan_premium_total`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_total)
-  [Function `update_flashloan_premiums`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_flashloan_premiums)
-  [Function `get_flashloan_premium_to_protocol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_to_protocol)
-  [Function `max_number_reserves`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_max_number_reserves)
-  [Function `update_interest_rates`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_interest_rates)
-  [Function `get_isolation_mode_state`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_isolation_mode_state)
-  [Function `get_siloed_borrowing_state`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_siloed_borrowing_state)
-  [Function `cumulate_to_liquidity_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_cumulate_to_liquidity_index)
-  [Function `reset_isolation_mode_total_debt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_reset_isolation_mode_total_debt)
-  [Function `rescue_tokens`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_rescue_tokens)
-  [Function `scaled_a_token_total_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_total_supply)
-  [Function `scaled_a_token_balance_of`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_balance_of)
-  [Function `scaled_variable_token_total_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_total_supply)
-  [Function `scaled_variable_token_balance_of`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_balance_of)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::default_reserve_interest_rate_strategy</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveInitialized"></a>

## Struct `ReserveInitialized`

@dev Emitted when a reserve is initialized.
@param asset The address of the underlying asset of the reserve
@param a_token The address of the associated aToken contract
@param variable_debt_token The address of the associated variable rate debt token


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveInitialized">ReserveInitialized</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveDataUpdated"></a>

## Struct `ReserveDataUpdated`

@dev Emitted when the state of a reserve is updated.
@param reserve The address of the underlying asset of the reserve
@param liquidity_rate The next liquidity rate
@param variable_borrow_rate The next variable borrow rate
@param liquidity_index The next liquidity index
@param variable_borrow_index The next variable borrow index


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveDataUpdated">ReserveDataUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_MintedToTreasury"></a>

## Struct `MintedToTreasury`

@dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
@param reserve The address of the reserve
@param amount_minted The amount minted to the treasury


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_MintedToTreasury">MintedToTreasury</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`

@dev Emitted on borrow(), repay() and liquidation_call() when using isolated assets
@param asset The address of the underlying asset of the reserve
@param totalDebt The total isolation mode debt for the reserve


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveExtendConfiguration"></a>

## Resource `ReserveExtendConfiguration`



<pre><code><b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveExtendConfiguration">ReserveExtendConfiguration</a> <b>has</b> drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData"></a>

## Resource `ReserveData`



<pre><code><b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">ReserveData</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveList"></a>

## Resource `ReserveList`

Map of reserves and their data (underlying_asset_of_reserve => reserveData)


<pre><code><b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveList">ReserveList</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveAddressesList"></a>

## Resource `ReserveAddressesList`

List of reserves as a map (reserveId => reserve).
It is structured as a mapping for gas savings reasons, using the reserve id as index


<pre><code><b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveAddressesList">ReserveAddressesList</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_UsersConfig"></a>

## Resource `UsersConfig`

Map of users address and their configuration data (user_address => UserConfigurationMap)


<pre><code><b>struct</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_UsersConfig">UsersConfig</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_POOL_REVISION"></a>



<pre><code><b>const</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_POOL_REVISION">POOL_REVISION</a>: u256 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_pool"></a>

## Function `init_pool`

@notice init pool


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_pool">init_pool</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_revision"></a>

## Function `get_revision`

@notice Returns the revision number of the contract
@dev Needs to be defined in the inherited class as a constant.
@return The revision number


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_reserve"></a>

## Function `init_reserve`

@notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
interest rate strategy
@dev Only callable by the pool_configurator contract
@param account The address of the caller
@param underlying_asset The address of the underlying asset of the reserve
@param underlying_asset_decimals The decimals of the underlying asset
@param treasury The address of the treasury
@param a_token_name The name of the aToken
@param a_token_symbol The symbol of the aToken
@param variable_debt_token_name The name of the variable debt token
@param variable_debt_token_symbol The symbol of the variable debt token


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_init_reserve">init_reserve</a>(<a href="">account</a>: &<a href="">signer</a>, underlying_asset: <b>address</b>, underlying_asset_decimals: u8, treasury: <b>address</b>, a_token_name: <a href="_String">string::String</a>, a_token_symbol: <a href="_String">string::String</a>, variable_debt_token_name: <a href="_String">string::String</a>, variable_debt_token_symbol: <a href="_String">string::String</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_drop_reserve"></a>

## Function `drop_reserve`

@notice Drop a reserve
@dev Only callable by the pool_configurator contract
@param asset The address of the underlying asset of the reserve


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_drop_reserve">drop_reserve</a>(asset: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data"></a>

## Function `get_reserve_data`

@notice Returns the state and configuration of the reserve
@param asset The address of the underlying asset of the reserve
@return The state and configuration data of the reserve


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data">get_reserve_data</a>(asset: <b>address</b>): <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data_and_reserves_count"></a>

## Function `get_reserve_data_and_reserves_count`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_data_and_reserves_count">get_reserve_data_and_reserves_count</a>(asset: <b>address</b>): (<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration"></a>

## Function `get_reserve_configuration`

@notice Returns the configuration of the reserve
@param asset The address of the underlying asset of the reserve
@return The configuration of the reserve


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration">get_reserve_configuration</a>(asset: <b>address</b>): <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_count"></a>

## Function `get_reserves_count`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_count">get_reserves_count</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration_by_reserve_data"></a>

## Function `get_reserve_configuration_by_reserve_data`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_configuration_by_reserve_data">get_reserve_configuration_by_reserve_data</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_last_update_timestamp"></a>

## Function `get_reserve_last_update_timestamp`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_last_update_timestamp">get_reserve_last_update_timestamp</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u64
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_id"></a>

## Function `get_reserve_id`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_id">get_reserve_id</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_a_token_address"></a>

## Function `get_reserve_a_token_address`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_a_token_address">get_reserve_a_token_address</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_accrued_to_treasury"></a>

## Function `set_reserve_accrued_to_treasury`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_accrued_to_treasury">set_reserve_accrued_to_treasury</a>(asset: <b>address</b>, accrued_to_treasury: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_accrued_to_treasury"></a>

## Function `get_reserve_accrued_to_treasury`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_accrued_to_treasury">get_reserve_accrued_to_treasury</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_borrow_index"></a>

## Function `get_reserve_variable_borrow_index`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_borrow_index">get_reserve_variable_borrow_index</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_liquidity_index"></a>

## Function `get_reserve_liquidity_index`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_liquidity_index">get_reserve_liquidity_index</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_liquidity_rate"></a>

## Function `get_reserve_current_liquidity_rate`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_liquidity_rate">get_reserve_current_liquidity_rate</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_variable_borrow_rate"></a>

## Function `get_reserve_current_variable_borrow_rate`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_current_variable_borrow_rate">get_reserve_current_variable_borrow_rate</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_debt_token_address"></a>

## Function `get_reserve_variable_debt_token_address`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_variable_debt_token_address">get_reserve_variable_debt_token_address</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_unbacked"></a>

## Function `set_reserve_unbacked`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_unbacked">set_reserve_unbacked</a>(asset: <b>address</b>, reserve_data_mut: &<b>mut</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, unbacked: u128)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_unbacked"></a>

## Function `get_reserve_unbacked`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_unbacked">get_reserve_unbacked</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_isolation_mode_total_debt"></a>

## Function `set_reserve_isolation_mode_total_debt`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_isolation_mode_total_debt">set_reserve_isolation_mode_total_debt</a>(asset: <b>address</b>, isolation_mode_total_debt: u128)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_isolation_mode_total_debt"></a>

## Function `get_reserve_isolation_mode_total_debt`



<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_isolation_mode_total_debt">get_reserve_isolation_mode_total_debt</a>(<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_configuration"></a>

## Function `set_reserve_configuration`

@notice Sets the configuration bitmap of the reserve as a whole
@dev Only callable by the pool_configurator and pool contract
@param asset The address of the underlying asset of the reserve
@param reserve_config_map The new configuration bitmap


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_reserve_configuration">set_reserve_configuration</a>(asset: <b>address</b>, reserve_config_map: <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_user_configuration"></a>

## Function `get_user_configuration`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_user_configuration">get_user_configuration</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_user_configuration"></a>

## Function `set_user_configuration`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_user_configuration">set_user_configuration</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, user_config_map: <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_income"></a>

## Function `get_reserve_normalized_income`

@notice Returns the normalized income of the reserve
@param asset The address of the underlying asset of the reserve
@return The reserve's normalized income


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_income">get_reserve_normalized_income</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_income_by_reserve_data"></a>

## Function `get_normalized_income_by_reserve_data`

@notice Returns the ongoing normalized income for the reserve.
@dev A value of 1e27 means there is no income. As time passes, the income is accrued
@dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
@param reserve_data The reserve object
@return The normalized income, expressed in ray


<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_income_by_reserve_data">get_normalized_income_by_reserve_data</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_state"></a>

## Function `update_state`

@notice Updates the liquidity cumulative index and the variable borrow index.
@param asset The address of the underlying asset of the reserve
@param reserve_data The reserve data


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_state">update_state</a>(asset: <b>address</b>, reserve_data: &<b>mut</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_variable_debt"></a>

## Function `get_reserve_normalized_variable_debt`

@notice Returns the normalized variable debt per unit of asset
@dev WARNING: This function is intended to be used primarily by the protocol itself to get a
"dynamic" variable index based on time, current stored index and virtual rate at the current
moment (approx. a borrower would get if opening a position). This means that is always used in
combination with variable debt supply/balances.
If using this function externally, consider that is possible to have an increasing normalized
variable debt that is not equivalent to how the variable debt index would be updated in storage
(e.g. only updates with non-zero variable debt supply)
@param asset The address of the underlying asset of the reserve
@return The reserve normalized variable debt


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_normalized_variable_debt">get_reserve_normalized_variable_debt</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_debt_by_reserve_data"></a>

## Function `get_normalized_debt_by_reserve_data`

@notice Returns the ongoing normalized variable debt for the reserve.
@dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
@dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
@param reserve_data The reserve object
@return The normalized variable debt, expressed in ray


<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_normalized_debt_by_reserve_data">get_normalized_debt_by_reserve_data</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_list"></a>

## Function `get_reserves_list`

@notice Returns the list of the underlying assets of all the initialized reserves
@dev It does not include dropped reserves
@return The addresses of the underlying assets of the initialized reserves


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserves_list">get_reserves_list</a>(): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_address_by_id"></a>

## Function `get_reserve_address_by_id`

@notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the ReserveData struct
@param id The id of the reserve as stored in the ReserveData struct
@return The address of the reserve associated with id


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_reserve_address_by_id">get_reserve_address_by_id</a>(id: u256): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_mint_to_treasury"></a>

## Function `mint_to_treasury`

@notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
@param assets The list of reserves for which the minting needs to be executed


<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_mint_to_treasury">mint_to_treasury</a>(assets: <a href="">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_bridge_protocol_fee"></a>

## Function `get_bridge_protocol_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_bridge_protocol_fee">get_bridge_protocol_fee</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_bridge_protocol_fee"></a>

## Function `set_bridge_protocol_fee`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_set_bridge_protocol_fee">set_bridge_protocol_fee</a>(protocol_fee: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_total"></a>

## Function `get_flashloan_premium_total`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_total">get_flashloan_premium_total</a>(): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_flashloan_premiums"></a>

## Function `update_flashloan_premiums`

@notice Updates flash loan premiums. Flash loan premium consists of two parts:
- A part is sent to aToken holders as extra, one time accumulated interest
- A part is collected by the protocol treasury
@dev The total premium is calculated on the total borrowed amount
@dev The premium to protocol is calculated on the total premium, being a percentage of <code>flashLoanPremiumTotal</code>
@dev Only callable by the pool_configurator contract
@param flash_loan_premium_total The total premium, expressed in bps
@param flash_loan_premium_to_protocol The part of the premium sent to the protocol treasury, expressed in bps


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_flashloan_premiums">update_flashloan_premiums</a>(flash_loan_premium_total: u128, flash_loan_premium_to_protocol: u128)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_to_protocol"></a>

## Function `get_flashloan_premium_to_protocol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_flashloan_premium_to_protocol">get_flashloan_premium_to_protocol</a>(): u128
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_max_number_reserves"></a>

## Function `max_number_reserves`

@notice Returns the maximum number of reserves supported to be listed in this Pool
@return The maximum number of reserves supported


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_max_number_reserves">max_number_reserves</a>(): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_interest_rates"></a>

## Function `update_interest_rates`

@notice Updates the reserve the current variable borrow rate and the current liquidity rate.
@param reserve_data The reserve data reserve to be updated
@param reserve_address The address of the reserve to be updated
@param liquidity_added The amount of liquidity added to the protocol (supply or repay) in the previous action
@param liquidity_taken The amount of liquidity taken from the protocol (redeem or borrow)


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_update_interest_rates">update_interest_rates</a>(reserve_data: &<b>mut</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, reserve_address: <b>address</b>, liquidity_added: u256, liquidity_taken: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_isolation_mode_state"></a>

## Function `get_isolation_mode_state`

@notice Returns the Isolation Mode state of the user
@param user_config_map The configuration of the user
@return True if the user is in isolation mode, false otherwise
@return The address of the only asset used as collateral
@return The debt ceiling of the reserve


<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_isolation_mode_state">get_isolation_mode_state</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): (bool, <b>address</b>, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_siloed_borrowing_state"></a>

## Function `get_siloed_borrowing_state`

@notice Returns the siloed borrowing state for the user
@param account The address of the user
@return True if the user has borrowed a siloed asset, false otherwise
@return The address of the only borrowed asset


<pre><code><b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_get_siloed_borrowing_state">get_siloed_borrowing_state</a>(<a href="">account</a>: <b>address</b>): (bool, <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_cumulate_to_liquidity_index"></a>

## Function `cumulate_to_liquidity_index`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_cumulate_to_liquidity_index">cumulate_to_liquidity_index</a>(asset: <b>address</b>, reserve_data: &<b>mut</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, total_liquidity: u256, amount: u256): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_reset_isolation_mode_total_debt"></a>

## Function `reset_isolation_mode_total_debt`

@notice Resets the isolation mode total debt of the given asset to zero
@dev It requires the given asset has zero debt ceiling
@param asset The address of the underlying asset to reset the isolation_mode_total_debt


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_reset_isolation_mode_total_debt">reset_isolation_mode_total_debt</a>(asset: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_rescue_tokens"></a>

## Function `rescue_tokens`

@notice Rescue and transfer tokens locked in this contract
@param token The address of the token
@param to The address of the recipient
@param amount The amount of token to transfer


<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_rescue_tokens">rescue_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, token: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_total_supply"></a>

## Function `scaled_a_token_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_total_supply">scaled_a_token_total_supply</a>(a_token_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_balance_of"></a>

## Function `scaled_a_token_balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_a_token_balance_of">scaled_a_token_balance_of</a>(owner: <b>address</b>, a_token_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_total_supply"></a>

## Function `scaled_variable_token_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_total_supply">scaled_variable_token_total_supply</a>(variable_debt_token_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_balance_of"></a>

## Function `scaled_variable_token_balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_scaled_variable_token_balance_of">scaled_variable_token_balance_of</a>(owner: <b>address</b>, variable_debt_token_address: <b>address</b>): u256
</code></pre>
