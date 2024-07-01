
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_validation`



-  [Function `validate_hf_and_ltv`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_hf_and_ltv)
-  [Function `validate_automatic_use_as_collateral`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_automatic_use_as_collateral)
-  [Function `validate_use_as_collateral`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_use_as_collateral)
-  [Function `validate_health_factor`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_health_factor)
-  [Function `validate_set_user_emode`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_set_user_emode)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::generic_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_hf_and_ltv"></a>

## Function `validate_hf_and_ltv`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_hf_and_ltv">validate_hf_and_ltv</a>(reserve_data: &<b>mut</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, from: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_automatic_use_as_collateral"></a>

## Function `validate_automatic_use_as_collateral`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_automatic_use_as_collateral">validate_automatic_use_as_collateral</a>(<a href="">account</a>: <b>address</b>, user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_config_map: &<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_use_as_collateral"></a>

## Function `validate_use_as_collateral`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_use_as_collateral">validate_use_as_collateral</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_config_map: &<a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_health_factor"></a>

## Function `validate_health_factor`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_health_factor">validate_health_factor</a>(reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256): (u256, bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_set_user_emode"></a>

## Function `validate_set_user_emode`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation_validate_set_user_emode">validate_set_user_emode</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserves_count: u256, category_id: u8, liquidation_threshold: u16)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic`



-  [Struct `ValidateBorrowLocalVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_ValidateBorrowLocalVars)
-  [Function `validate_flashloan_complex`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_complex)
-  [Function `validate_flashloan_simple`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_simple)
-  [Function `validate_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_supply)
-  [Function `validate_withdraw`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_withdraw)
-  [Function `validate_transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_transfer)
-  [Function `validate_set_use_reserve_as_collateral`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_set_use_reserve_as_collateral)
-  [Function `validate_borrow`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_borrow)
-  [Function `validate_repay`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_repay)
-  [Function `validate_liquidation_call`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_liquidation_call)


<pre><code><b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::generic_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle_sentinel</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_ValidateBorrowLocalVars"></a>

## Struct `ValidateBorrowLocalVars`


* ----------------------------
* Borrow Validate
* ----------------------------



<pre><code><b>struct</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_ValidateBorrowLocalVars">ValidateBorrowLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_complex"></a>

## Function `validate_flashloan_complex`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_complex">validate_flashloan_complex</a>(reserve_data: &<a href="">vector</a>&lt;<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>&gt;, assets: &<a href="">vector</a>&lt;<b>address</b>&gt;, amounts: &<a href="">vector</a>&lt;u256&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_simple"></a>

## Function `validate_flashloan_simple`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_flashloan_simple">validate_flashloan_simple</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_supply"></a>

## Function `validate_supply`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_supply">validate_supply</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, amount: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_withdraw"></a>

## Function `validate_withdraw`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_withdraw">validate_withdraw</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, amount: u256, user_balance: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_transfer"></a>

## Function `validate_transfer`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_transfer">validate_transfer</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_set_use_reserve_as_collateral"></a>

## Function `validate_set_use_reserve_as_collateral`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_set_use_reserve_as_collateral">validate_set_use_reserve_as_collateral</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, user_balance: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_borrow"></a>

## Function `validate_borrow`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_borrow">validate_borrow</a>(reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, asset: <b>address</b>, user_address: <b>address</b>, amount: u256, interest_rate_mode: u8, reserves_count: u256, user_emode_category: u8, isolation_mode_active: bool, isolation_mode_collateral_address: <b>address</b>, isolation_mode_debt_ceiling: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_repay"></a>

## Function `validate_repay`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_repay">validate_repay</a>(<a href="">account</a>: &<a href="">signer</a>, reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, amount_sent: u256, interest_rate_mode: u8, on_behalf_of: <b>address</b>, variable_debt: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_liquidation_call"></a>

## Function `validate_liquidation_call`



<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic_validate_liquidation_call">validate_liquidation_call</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, collateral_reserve: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, debt_reserve: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, total_debt: u256, health_factor: u256)
</code></pre>
