
<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user"></a>

# Module `0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user`



-  [Resource `UserConfigurationMap`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap)
-  [Constants](#@Constants_0)
-  [Function `init`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_init)
-  [Function `get_interest_rate_mode_none`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_none)
-  [Function `get_interest_rate_mode_variable`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_variable)
-  [Function `get_borrowing_mask`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_borrowing_mask)
-  [Function `get_collateral_mask`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_collateral_mask)
-  [Function `get_rebalance_up_liquidity_rate_threshold`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_rebalance_up_liquidity_rate_threshold)
-  [Function `get_minimum_health_factor_liquidation_threshold`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_minimum_health_factor_liquidation_threshold)
-  [Function `get_health_factor_liquidation_threshold`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_health_factor_liquidation_threshold)
-  [Function `get_isolated_collateral_supplier_role`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_isolated_collateral_supplier_role)
-  [Function `set_borrowing`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_borrowing)
-  [Function `set_using_as_collateral`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_using_as_collateral)
-  [Function `is_using_as_collateral_or_borrowing`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_or_borrowing)
-  [Function `is_borrowing`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing)
-  [Function `is_using_as_collateral`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral)
-  [Function `is_using_as_collateral_one`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_one)
-  [Function `is_using_as_collateral_any`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_any)
-  [Function `is_borrowing_one`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_one)
-  [Function `is_borrowing_any`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_any)
-  [Function `is_empty`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_empty)
-  [Function `get_first_asset_id_by_mask`](#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_first_asset_id_by_mask)


<pre><code><b>use</b> <a href="error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="helper.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_helper">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::helper</a>;
<b>use</b> <a href="reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap"></a>

## Resource `UserConfigurationMap`



<pre><code><b>struct</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">UserConfigurationMap</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_BORROWING_MASK"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_BORROWING_MASK">BORROWING_MASK</a>: u256 = 38597363079105398474523661669562635951089994888546854679819194669304376546645;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_COLLATERAL_MASK"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_COLLATERAL_MASK">COLLATERAL_MASK</a>: u256 = 77194726158210796949047323339125271902179989777093709359638389338608753093290;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_HEALTH_FACTOR_LIQUIDATION_THRESHOLD"></a>


* @dev Minimum health factor to consider a user position healthy
* A value of 1e18 results in 1



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_HEALTH_FACTOR_LIQUIDATION_THRESHOLD">HEALTH_FACTOR_LIQUIDATION_THRESHOLD</a>: u256 = 1000000000000000000;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_INTEREST_RATE_MODE_NONE"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_INTEREST_RATE_MODE_NONE">INTEREST_RATE_MODE_NONE</a>: u8 = 0;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_INTEREST_RATE_MODE_VARIABLE"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_INTEREST_RATE_MODE_VARIABLE">INTEREST_RATE_MODE_VARIABLE</a>: u8 = 2;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_ISOLATED_COLLATERAL_SUPPLIER_ROLE"></a>


* @dev Role identifier for the role allowed to supply isolated reserves as collateral



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_ISOLATED_COLLATERAL_SUPPLIER_ROLE">ISOLATED_COLLATERAL_SUPPLIER_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [73, 83, 79, 76, 65, 84, 69, 68, 95, 67, 79, 76, 76, 65, 84, 69, 82, 65, 76, 95, 83, 85, 80, 80, 76, 73, 69, 82];
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD">MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD</a>: u256 = 950000000000000000;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD"></a>



<pre><code><b>const</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD">REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD</a>: u256 = 9000;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_init"></a>

## Function `init`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_init">init</a>(): <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_none"></a>

## Function `get_interest_rate_mode_none`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_none">get_interest_rate_mode_none</a>(): u8
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_variable"></a>

## Function `get_interest_rate_mode_variable`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_interest_rate_mode_variable">get_interest_rate_mode_variable</a>(): u8
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_borrowing_mask"></a>

## Function `get_borrowing_mask`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_borrowing_mask">get_borrowing_mask</a>(): u256
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_collateral_mask"></a>

## Function `get_collateral_mask`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_collateral_mask">get_collateral_mask</a>(): u256
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_rebalance_up_liquidity_rate_threshold"></a>

## Function `get_rebalance_up_liquidity_rate_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_rebalance_up_liquidity_rate_threshold">get_rebalance_up_liquidity_rate_threshold</a>(): u256
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_minimum_health_factor_liquidation_threshold"></a>

## Function `get_minimum_health_factor_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_minimum_health_factor_liquidation_threshold">get_minimum_health_factor_liquidation_threshold</a>(): u256
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_health_factor_liquidation_threshold"></a>

## Function `get_health_factor_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_health_factor_liquidation_threshold">get_health_factor_liquidation_threshold</a>(): u256
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_isolated_collateral_supplier_role"></a>

## Function `get_isolated_collateral_supplier_role`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_isolated_collateral_supplier_role">get_isolated_collateral_supplier_role</a>(): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_borrowing"></a>

## Function `set_borrowing`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_borrowing">set_borrowing</a>(user_configuration: &<b>mut</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256, borrowing: bool)
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_using_as_collateral"></a>

## Function `set_using_as_collateral`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_set_using_as_collateral">set_using_as_collateral</a>(user_configuration: &<b>mut</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256, using_as_collateral: bool)
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_or_borrowing"></a>

## Function `is_using_as_collateral_or_borrowing`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_or_borrowing">is_using_as_collateral_or_borrowing</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing"></a>

## Function `is_borrowing`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing">is_borrowing</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral"></a>

## Function `is_using_as_collateral`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral">is_using_as_collateral</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_one"></a>

## Function `is_using_as_collateral_one`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_one">is_using_as_collateral_one</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_any"></a>

## Function `is_using_as_collateral_any`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_using_as_collateral_any">is_using_as_collateral_any</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_one"></a>

## Function `is_borrowing_one`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_one">is_borrowing_one</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_any"></a>

## Function `is_borrowing_any`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_borrowing_any">is_borrowing_any</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_empty"></a>

## Function `is_empty`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_is_empty">is_empty</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_first_asset_id_by_mask"></a>

## Function `get_first_asset_id_by_mask`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_get_first_asset_id_by_mask">get_first_asset_id_by_mask</a>(user_configuration: &<a href="user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, mask: u256): u256
</code></pre>
