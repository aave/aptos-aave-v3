
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_validation`



-  [Function `validate_hf_and_ltv`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_hf_and_ltv)
-  [Function `validate_automatic_use_as_collateral`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_automatic_use_as_collateral)
-  [Function `validate_use_as_collateral`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_use_as_collateral)
-  [Function `validate_health_factor`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_health_factor)
-  [Function `validate_set_user_emode`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_set_user_emode)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::generic_logic</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_hf_and_ltv"></a>

## Function `validate_hf_and_ltv`

@notice Validates the health factor of a user and the ltv of the asset being withdrawn.
@param reserves_data The reserve data of reserve
@param reserves_count The number of available reserves
@param user_config_map the user configuration map
@param from The user from which the aTokens are being transferred
@param user_emode_category The users active efficiency mode category
@param emode_ltv The ltv of the efficiency mode category
@param emode_liq_threshold The liquidation threshold of the efficiency mode category
@param emode_asset_price The price of the efficiency mode category


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_hf_and_ltv">validate_hf_and_ltv</a>(reserve_data: &<b>mut</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, from: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_automatic_use_as_collateral"></a>

## Function `validate_automatic_use_as_collateral`

@notice Validates if an asset should be automatically activated as collateral in the following actions: supply,
transfer, mint unbacked, and liquidate
@dev This is used to ensure that isolated assets are not enabled as collateral automatically
@param user_config_map the user configuration map
@param reserve_config_map The reserve configuration map
@return True if the asset can be activated as collateral, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_automatic_use_as_collateral">validate_automatic_use_as_collateral</a>(<a href="">account</a>: <b>address</b>, user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_config_map: &<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_use_as_collateral"></a>

## Function `validate_use_as_collateral`

@notice Validates the action of activating the asset as collateral.
@dev Only possible if the asset has non-zero LTV and the user is not in isolation mode
@param user_config_map the user configuration map
@param reserve_config_map The reserve configuration map
@return True if the asset can be activated as collateral, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_use_as_collateral">validate_use_as_collateral</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_config_map: &<a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_health_factor"></a>

## Function `validate_health_factor`

notice Validates the health factor of a user.
@param reserves_count The number of available reserves
@param user_config_map the user configuration map
@param user The user to validate health factor of
@param user_emode_category The users active efficiency mode category
@param emode_ltv The ltv of the efficiency mode category
@param emode_liq_threshold The liquidation threshold of the efficiency mode category
@param emode_asset_price The price of the efficiency mode category


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_health_factor">validate_health_factor</a>(reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256): (u256, bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_set_user_emode"></a>

## Function `validate_set_user_emode`

@notice Validates the action of setting efficiency mode.
@param user_config_map the user configuration map
@param reserves_count The total number of valid reserves
@param category_id The id of the category
@param liquidation_threshold The liquidation threshold


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation_validate_set_user_emode">validate_set_user_emode</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserves_count: u256, category_id: u8, liquidation_threshold: u16)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic`



-  [Struct `ValidateBorrowLocalVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_ValidateBorrowLocalVars)
-  [Function `validate_flashloan_complex`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_complex)
-  [Function `validate_flashloan_simple`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_simple)
-  [Function `validate_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_supply)
-  [Function `validate_withdraw`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_withdraw)
-  [Function `validate_transfer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_transfer)
-  [Function `validate_set_use_reserve_as_collateral`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_set_use_reserve_as_collateral)
-  [Function `validate_borrow`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_borrow)
-  [Function `validate_repay`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_repay)
-  [Function `validate_liquidation_call`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_liquidation_call)


<pre><code><b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::generic_logic</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle_sentinel</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_ValidateBorrowLocalVars"></a>

## Struct `ValidateBorrowLocalVars`


* ----------------------------
* Borrow Validate
* ----------------------------



<pre><code><b>struct</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_ValidateBorrowLocalVars">ValidateBorrowLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_complex"></a>

## Function `validate_flashloan_complex`

@notice Validates a flashloan action.
@param reserves_data The data of all the reserves
@param assets The assets being flash-borrowed
@param amounts The amounts for each asset being borrowed


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_complex">validate_flashloan_complex</a>(reserves_data: &<a href="">vector</a>&lt;<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>&gt;, assets: &<a href="">vector</a>&lt;<b>address</b>&gt;, amounts: &<a href="">vector</a>&lt;u256&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_simple"></a>

## Function `validate_flashloan_simple`

@notice Validates a flashloan action.
@param reserve_data The reserve data the reserve


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_flashloan_simple">validate_flashloan_simple</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_supply"></a>

## Function `validate_supply`

@notice Validates a supply action.
@param reserve_data The reserve data the reserve
@param amount The amount to be supplied


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_supply">validate_supply</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, amount: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_withdraw"></a>

## Function `validate_withdraw`

@notice Validates a withdraw action.
@param reserve_data The reserve data the reserve
@param amount The amount to be withdrawn
@param user_balance The balance of the user


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_withdraw">validate_withdraw</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, amount: u256, user_balance: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_transfer"></a>

## Function `validate_transfer`

@notice Validates a transfer action.
@param reserve_data The reserve data the reserve


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_transfer">validate_transfer</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_set_use_reserve_as_collateral"></a>

## Function `validate_set_use_reserve_as_collateral`

@notice Validates the action of setting an asset as collateral.
@param reserve_data The reserve data the reserve
@param user_balance The balance of the user


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_set_use_reserve_as_collateral">validate_set_use_reserve_as_collateral</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, user_balance: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_borrow"></a>

## Function `validate_borrow`

@notice Validates a borrow action.
@param reserve_data The reserve data the reserve
@param user_config_map The UserConfigurationMap object
@param asset The address of the asset to be borrowed
@param user_address The address of the user
@param amount The amount to be borrowed
@param interest_rate_mode The interest rate mode
@param reserves_count The number of reserves
@param user_emode_category The user's eMode category
@param isolation_mode_active The isolation mode state
@param isolation_mode_collateral_address The address of the collateral reserve in isolation mode
@param isolation_mode_debt_ceiling The debt ceiling in isolation mode


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_borrow">validate_borrow</a>(reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, asset: <b>address</b>, user_address: <b>address</b>, amount: u256, interest_rate_mode: u8, reserves_count: u256, user_emode_category: u8, isolation_mode_active: bool, isolation_mode_collateral_address: <b>address</b>, isolation_mode_debt_ceiling: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_repay"></a>

## Function `validate_repay`

@notice Validates a repay action.
@param account The address of the user
@param reserve_data The reserve data the reserve
@param amount_sent The amount sent for the repayment. Can be an actual value or uint(-1)
@param interest_rate_mode The interest rate mode of the debt being repaid
@param on_behalf_of The address of the user msg.sender is repaying for
@param variable_debt The borrow balance of the user


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_repay">validate_repay</a>(<a href="">account</a>: &<a href="">signer</a>, reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, amount_sent: u256, interest_rate_mode: u8, on_behalf_of: <b>address</b>, variable_debt: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_liquidation_call"></a>

## Function `validate_liquidation_call`

@notice Validates the liquidation action.
@param user_config_map The user configuration mapping
@param collateral_reserve The reserve data of the collateral
@param debt_reserve The reserve data of the debt
@param total_debt The total debt of the user
@param health_factor The health factor of the user


<pre><code><b>public</b> <b>fun</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic_validate_liquidation_call">validate_liquidation_call</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, collateral_reserve: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, debt_reserve: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, total_debt: u256, health_factor: u256)
</code></pre>
