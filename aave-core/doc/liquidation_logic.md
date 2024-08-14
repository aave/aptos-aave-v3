
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::liquidation_logic`

@title liquidation_logic module
@author Aave
@notice Implements actions involving management of collateral in the protocol, the main one being the liquidations


-  [Struct `ReserveUsedAsCollateralEnabled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `ReserveUsedAsCollateralDisabled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralDisabled)
-  [Struct `LiquidationCall`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCall)
-  [Struct `LiquidationCallLocalVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCallLocalVars)
-  [Struct `ExecuteLiquidationCallParams`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ExecuteLiquidationCallParams)
-  [Struct `AvailableCollateralToLiquidateLocalVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_AvailableCollateralToLiquidateLocalVars)
-  [Constants](#@Constants_0)
-  [Function `liquidation_call`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_liquidation_call)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::generic_logic</a>;
<b>use</b> <a href="isolation_mode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::isolation_mode_logic</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_validation</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`

@dev Emitted on setUserUseReserveAsCollateral()
@param reserve The address of the underlying asset of the reserve
@param user The address of the user enabling the usage as collateral


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralDisabled"></a>

## Struct `ReserveUsedAsCollateralDisabled`

@dev Emitted on setUserUseReserveAsCollateral()
@param reserve The address of the underlying asset of the reserve
@param user The address of the user enabling the usage as collateral


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ReserveUsedAsCollateralDisabled">ReserveUsedAsCollateralDisabled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCall"></a>

## Struct `LiquidationCall`

@dev Emitted when a borrower is liquidated.
@param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
@param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
@param user The address of the borrower getting liquidated
@param debt_to_cover The debt amount of borrowed <code>asset</code> the liquidator wants to cover
@param liquidated_collateral_amount The amount of collateral received by the liquidator
@param liquidator The address of the liquidator
@param receive_a_token True if the liquidators wants to receive the collateral aTokens, <code><b>false</b></code> if he wants
to receive the underlying collateral asset directly


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCall">LiquidationCall</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCallLocalVars"></a>

## Struct `LiquidationCallLocalVars`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCallLocalVars">LiquidationCallLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ExecuteLiquidationCallParams"></a>

## Struct `ExecuteLiquidationCallParams`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_ExecuteLiquidationCallParams">ExecuteLiquidationCallParams</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_AvailableCollateralToLiquidateLocalVars"></a>

## Struct `AvailableCollateralToLiquidateLocalVars`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_AvailableCollateralToLiquidateLocalVars">AvailableCollateralToLiquidateLocalVars</a> <b>has</b> drop
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD"></a>

@dev This constant represents below which health factor value it is possible to liquidate
an amount of debt corresponding to <code><a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR">MAX_LIQUIDATION_CLOSE_FACTOR</a></code>.
A value of 0.95e18 results in 0.95
0.95 * 10 ** 18


<pre><code><b>const</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a>: u256 = 950000000000000000;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_DEFAULT_LIQUIDATION_CLOSE_FACTOR"></a>

@dev Default percentage of borrower's debt to be repaid in a liquidation.
@dev Percentage applied when the users health factor is above <code><a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a></code>
Expressed in bps, a value of 0.5e4 results in 50.00%
5 * 10 ** 3


<pre><code><b>const</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_DEFAULT_LIQUIDATION_CLOSE_FACTOR">DEFAULT_LIQUIDATION_CLOSE_FACTOR</a>: u256 = 5000;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR"></a>

@dev Maximum percentage of borrower's debt to be repaid in a liquidation
@dev Percentage applied when the users health factor is below <code><a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a></code>
Expressed in bps, a value of 1e4 results in 100.00%
1 * 10 ** 4


<pre><code><b>const</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR">MAX_LIQUIDATION_CLOSE_FACTOR</a>: u256 = 10000;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_liquidation_call"></a>

## Function `liquidation_call`

@notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
- The caller (liquidator) covers <code>debt_to_cover</code> amount of debt of the user getting liquidated, and receives
a proportionally amount of the <code>collateral_asset</code> plus a bonus to cover market risk
@dev Emits the <code><a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_LiquidationCall">LiquidationCall</a>()</code> event
@param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
@param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
@param user The address of the borrower getting liquidated
@param debt_to_cover The debt amount of borrowed <code>asset</code> the liquidator wants to cover
@param receive_a_token True if the liquidators wants to receive the collateral aTokens, <code><b>false</b></code> if he wants
to receive the underlying collateral asset directly


<pre><code><b>public</b> entry <b>fun</b> <a href="liquidation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_liquidation_logic_liquidation_call">liquidation_call</a>(<a href="">account</a>: &<a href="">signer</a>, collateral_asset: <b>address</b>, debt_asset: <b>address</b>, <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, debt_to_cover: u256, receive_a_token: bool)
</code></pre>
