
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::generic_logic`

@title GenericLogic module
@author Aave
@notice Implements protocol-level logic to calculate and validate the state of a user


-  [Struct `CalculateUserAccountDataVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_CalculateUserAccountDataVars)
-  [Function `calculate_user_account_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_user_account_data)
-  [Function `calculate_available_borrows`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_available_borrows)


<pre><code><b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_CalculateUserAccountDataVars"></a>

## Struct `CalculateUserAccountDataVars`



<pre><code><b>struct</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_CalculateUserAccountDataVars">CalculateUserAccountDataVars</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_user_account_data"></a>

## Function `calculate_user_account_data`

@notice Calculates the user data across the reserves.
@dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
the average Loan To Value, the average Liquidation Ratio, and the Health factor.
@param params reserves_count The number of reserves
@param params user_config_map The user configuration map
@param params user The address of the user
@param params user_emode_category The category of the user in the emode
@param params emode_ltv The ltv of the user in the emode
@param params emode_liq_threshold The liquidation threshold of the user in the emode
@param params emode_asset_price The price of the asset in the emode
@return The total collateral of the user in the base currency used by the price feed
@return The total debt of the user in the base currency used by the price feed
@return The average ltv of the user
@return The average liquidation threshold of the user
@return The health factor of the user
@return True if the ltv is zero, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_user_account_data">calculate_user_account_data</a>(reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256): (u256, u256, u256, u256, u256, bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_available_borrows"></a>

## Function `calculate_available_borrows`

@notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
and the average Loan To Value
@param total_collateral_in_base_currency The total collateral in the base currency used by the price feed
@param total_debt_in_base_currency The total borrow balance in the base currency used by the price feed
@param ltv The average loan to value
@return The amount available to borrow in the base currency of the used by the price feed


<pre><code><b>public</b> <b>fun</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic_calculate_available_borrows">calculate_available_borrows</a>(total_collateral_in_base_currency: u256, total_debt_in_base_currency: u256, ltv: u256): u256
</code></pre>
