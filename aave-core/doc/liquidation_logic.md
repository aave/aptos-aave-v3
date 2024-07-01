
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::liquidation_logic`



-  [Struct `ReserveUsedAsCollateralEnabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `ReserveUsedAsCollateralDisabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralDisabled)
-  [Struct `LiquidationCall`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCall)
-  [Struct `LiquidationCallLocalVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCallLocalVars)
-  [Struct `ExecuteLiquidationCallParams`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ExecuteLiquidationCallParams)
-  [Struct `AvailableCollateralToLiquidateLocalVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_AvailableCollateralToLiquidateLocalVars)
-  [Constants](#@Constants_0)
-  [Function `liquidation_call`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_liquidation_call)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::generic_logic</a>;
<b>use</b> <a href="isolation_mode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::isolation_mode_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_validation</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralDisabled"></a>

## Struct `ReserveUsedAsCollateralDisabled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ReserveUsedAsCollateralDisabled">ReserveUsedAsCollateralDisabled</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCall"></a>

## Struct `LiquidationCall`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCall">LiquidationCall</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCallLocalVars"></a>

## Struct `LiquidationCallLocalVars`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_LiquidationCallLocalVars">LiquidationCallLocalVars</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ExecuteLiquidationCallParams"></a>

## Struct `ExecuteLiquidationCallParams`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_ExecuteLiquidationCallParams">ExecuteLiquidationCallParams</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_AvailableCollateralToLiquidateLocalVars"></a>

## Struct `AvailableCollateralToLiquidateLocalVars`



<pre><code><b>struct</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_AvailableCollateralToLiquidateLocalVars">AvailableCollateralToLiquidateLocalVars</a> <b>has</b> drop
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD"></a>


* @dev This constant represents below which health factor value it is possible to liquidate
* an amount of debt corresponding to <code><a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR">MAX_LIQUIDATION_CLOSE_FACTOR</a></code>.
* A value of 0.95e18 results in 0.95



<pre><code><b>const</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a>: u256 = 950000000000000000;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_DEFAULT_LIQUIDATION_CLOSE_FACTOR"></a>


* @dev Default percentage of borrower's debt to be repaid in a liquidation.
* @dev Percentage applied when the users health factor is above <code><a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a></code>
* Expressed in bps, a value of 0.5e4 results in 50.00%



<pre><code><b>const</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_DEFAULT_LIQUIDATION_CLOSE_FACTOR">DEFAULT_LIQUIDATION_CLOSE_FACTOR</a>: u256 = 5000;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR"></a>


* @dev Maximum percentage of borrower's debt to be repaid in a liquidation
* @dev Percentage applied when the users health factor is below <code><a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_CLOSE_FACTOR_HF_THRESHOLD">CLOSE_FACTOR_HF_THRESHOLD</a></code>
* Expressed in bps, a value of 1e4 results in 100.00%



<pre><code><b>const</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_MAX_LIQUIDATION_CLOSE_FACTOR">MAX_LIQUIDATION_CLOSE_FACTOR</a>: u256 = 10000;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_liquidation_call"></a>

## Function `liquidation_call`



<pre><code><b>public</b> entry <b>fun</b> <a href="liquidation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_liquidation_logic_liquidation_call">liquidation_call</a>(<a href="">account</a>: &<a href="">signer</a>, collateral_asset: <b>address</b>, debt_asset: <b>address</b>, <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, debt_to_cover: u256, receive_a_token: bool)
</code></pre>
