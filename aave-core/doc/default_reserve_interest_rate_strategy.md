
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::default_reserve_interest_rate_strategy`

@title default_reserve_interest_rate_strategy module
@author Aave
@notice Implements the calculation of the interest rates depending on the reserve state
@dev The model of interest rate is based on 2 slopes, one before the <code>OPTIMAL_USAGE_RATIO</code>
point of usage and another from that one to 100%.


-  [Struct `ReserveInterestRateStrategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategy)
-  [Resource `DefaultReserveInterestRateStrategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy)
-  [Resource `ReserveInterestRateStrategyMap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap)
-  [Struct `CalcInterestRatesLocalVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars)
-  [Function `init_interest_rate_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_init_interest_rate_strategy)
-  [Function `set_reserve_interest_rate_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy)
-  [Function `asset_interest_rate_exists`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_asset_interest_rate_exists)
-  [Function `get_reserve_interest_rate_strategy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy)
-  [Function `get_optimal_usage_ratio`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_optimal_usage_ratio)
-  [Function `get_max_excess_usage_ratio`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio)
-  [Function `get_variable_rate_slope1`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope1)
-  [Function `get_variable_rate_slope2`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope2)
-  [Function `get_base_variable_borrow_rate`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate)
-  [Function `get_max_variable_borrow_rate`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate)
-  [Function `calculate_interest_rates`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_calculate_interest_rates)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategy"></a>

## Struct `ReserveInterestRateStrategy`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategy">ReserveInterestRateStrategy</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy"></a>

## Resource `DefaultReserveInterestRateStrategy`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy">DefaultReserveInterestRateStrategy</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap"></a>

## Resource `ReserveInterestRateStrategyMap`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap">ReserveInterestRateStrategyMap</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars"></a>

## Struct `CalcInterestRatesLocalVars`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars">CalcInterestRatesLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_init_interest_rate_strategy"></a>

## Function `init_interest_rate_strategy`

@notice Initializes the interest rate strategy


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_init_interest_rate_strategy">init_interest_rate_strategy</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy"></a>

## Function `set_reserve_interest_rate_strategy`

@notice Sets the interest rate strategy of a reserve
@param asset The address of the reserve
@param optimal_usage_ratio The optimal usage ratio
@param base_variable_borrow_rate The base variable borrow rate
@param variable_rate_slope1 The variable rate slope below optimal usage ratio
@param variable_rate_slope2 The variable rate slope above optimal usage ratio


<pre><code><b>public</b> entry <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy">set_reserve_interest_rate_strategy</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, optimal_usage_ratio: u256, base_variable_borrow_rate: u256, variable_rate_slope1: u256, variable_rate_slope2: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_asset_interest_rate_exists"></a>

## Function `asset_interest_rate_exists`



<pre><code><b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_asset_interest_rate_exists">asset_interest_rate_exists</a>(asset: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy"></a>

## Function `get_reserve_interest_rate_strategy`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy">get_reserve_interest_rate_strategy</a>(asset: <b>address</b>): <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy">default_reserve_interest_rate_strategy::DefaultReserveInterestRateStrategy</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_optimal_usage_ratio"></a>

## Function `get_optimal_usage_ratio`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_optimal_usage_ratio">get_optimal_usage_ratio</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio"></a>

## Function `get_max_excess_usage_ratio`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio">get_max_excess_usage_ratio</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope1"></a>

## Function `get_variable_rate_slope1`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope1">get_variable_rate_slope1</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope2"></a>

## Function `get_variable_rate_slope2`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_variable_rate_slope2">get_variable_rate_slope2</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate"></a>

## Function `get_base_variable_borrow_rate`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate">get_base_variable_borrow_rate</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate"></a>

## Function `get_max_variable_borrow_rate`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate">get_max_variable_borrow_rate</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_calculate_interest_rates"></a>

## Function `calculate_interest_rates`

@notice Calculates the interest rates depending on the reserve's state and configurations
@param unbacked The amount of unbacked liquidity
@param liquidity_added The amount of liquidity added
@param liquidity_taken The amount of liquidity taken
@param total_variable_debt The total variable debt of the reserve
@param reserve_factor The reserve factor
@param reserve The address of the reserve
@param a_token_address The address of the aToken
@return current_liquidity_rate The liquidity rate expressed in rays
@return current_variable_borrow_rate The variable borrow rate expressed in rays


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy_calculate_interest_rates">calculate_interest_rates</a>(unbacked: u256, liquidity_added: u256, liquidity_taken: u256, total_variable_debt: u256, reserve_factor: u256, <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">reserve</a>: <b>address</b>, a_token_address: <b>address</b>): (u256, u256)
</code></pre>
