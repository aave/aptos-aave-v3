
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::default_reserve_interest_rate_strategy`



-  [Resource `DefaultReserveInterestRateStrategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy)
-  [Resource `ReserveInterestRateStrategyMap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap)
-  [Struct `CalcInterestRatesLocalVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars)
-  [Function `init_interest_rate_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_init_interest_rate_strategy)
-  [Function `set_reserve_interest_rate_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy)
-  [Function `get_reserve_interest_rate_strategy`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy)
-  [Function `get_optimal_usage_ratio`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_optimal_usage_ratio)
-  [Function `get_max_excess_usage_ratio`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio)
-  [Function `get_variable_rate_slope1`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope1)
-  [Function `get_variable_rate_slope2`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope2)
-  [Function `get_base_variable_borrow_rate`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate)
-  [Function `get_max_variable_borrow_rate`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate)
-  [Function `calculate_interest_rates`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_calculate_interest_rates)


<pre><code><b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy"></a>

## Resource `DefaultReserveInterestRateStrategy`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy">DefaultReserveInterestRateStrategy</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap"></a>

## Resource `ReserveInterestRateStrategyMap`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_ReserveInterestRateStrategyMap">ReserveInterestRateStrategyMap</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars"></a>

## Struct `CalcInterestRatesLocalVars`



<pre><code><b>struct</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_CalcInterestRatesLocalVars">CalcInterestRatesLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_init_interest_rate_strategy"></a>

## Function `init_interest_rate_strategy`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_init_interest_rate_strategy">init_interest_rate_strategy</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy"></a>

## Function `set_reserve_interest_rate_strategy`



<pre><code><b>public</b> entry <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_set_reserve_interest_rate_strategy">set_reserve_interest_rate_strategy</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, optimal_usage_ratio: u256, base_variable_borrow_rate: u256, variable_rate_slope1: u256, variable_rate_slope2: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy"></a>

## Function `get_reserve_interest_rate_strategy`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_reserve_interest_rate_strategy">get_reserve_interest_rate_strategy</a>(asset: <b>address</b>): <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_DefaultReserveInterestRateStrategy">default_reserve_interest_rate_strategy::DefaultReserveInterestRateStrategy</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_optimal_usage_ratio"></a>

## Function `get_optimal_usage_ratio`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_optimal_usage_ratio">get_optimal_usage_ratio</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio"></a>

## Function `get_max_excess_usage_ratio`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_excess_usage_ratio">get_max_excess_usage_ratio</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope1"></a>

## Function `get_variable_rate_slope1`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope1">get_variable_rate_slope1</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope2"></a>

## Function `get_variable_rate_slope2`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_variable_rate_slope2">get_variable_rate_slope2</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate"></a>

## Function `get_base_variable_borrow_rate`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_base_variable_borrow_rate">get_base_variable_borrow_rate</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate"></a>

## Function `get_max_variable_borrow_rate`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_get_max_variable_borrow_rate">get_max_variable_borrow_rate</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_calculate_interest_rates"></a>

## Function `calculate_interest_rates`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy_calculate_interest_rates">calculate_interest_rates</a>(unbacked: u256, liquidity_added: u256, liquidity_taken: u256, total_variable_debt: u256, reserve_factor: u256, <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">reserve</a>: <b>address</b>, a_token_address: <b>address</b>): (u256, u256)
</code></pre>
