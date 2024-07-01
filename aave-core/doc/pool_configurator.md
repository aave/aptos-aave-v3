
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_configurator`



-  [Struct `ReserveBorrowing`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveBorrowing)
-  [Struct `ReserveFlashLoaning`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFlashLoaning)
-  [Struct `CollateralConfigurationChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_CollateralConfigurationChanged)
-  [Struct `ReserveActive`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveActive)
-  [Struct `ReserveFrozen`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFrozen)
-  [Struct `ReservePaused`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReservePaused)
-  [Struct `ReserveDropped`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveDropped)
-  [Struct `ReserveFactorChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFactorChanged)
-  [Struct `BorrowCapChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowCapChanged)
-  [Struct `SupplyCapChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SupplyCapChanged)
-  [Struct `LiquidationProtocolFeeChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_LiquidationProtocolFeeChanged)
-  [Struct `UnbackedMintCapChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_UnbackedMintCapChanged)
-  [Struct `EModeAssetCategoryChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeAssetCategoryChanged)
-  [Struct `EModeCategoryAdded`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeCategoryAdded)
-  [Struct `ReserveInterestRateStrategyChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveInterestRateStrategyChanged)
-  [Struct `DebtCeilingChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_DebtCeilingChanged)
-  [Struct `SiloedBorrowingChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SiloedBorrowingChanged)
-  [Struct `BridgeProtocolFeeUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BridgeProtocolFeeUpdated)
-  [Struct `FlashloanPremiumTotalUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumTotalUpdated)
-  [Struct `FlashloanPremiumToProtocolUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumToProtocolUpdated)
-  [Struct `BorrowableInIsolationChanged`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowableInIsolationChanged)
-  [Constants](#@Constants_0)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_get_revision)
-  [Function `init_reserves`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_init_reserves)
-  [Function `drop_reserve`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_drop_reserve)
-  [Function `set_reserve_borrowing`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_borrowing)
-  [Function `configure_reserve_as_collateral`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserve_as_collateral)
-  [Function `set_reserve_flash_loaning`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_flash_loaning)
-  [Function `set_reserve_active`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_active)
-  [Function `set_reserve_freeze`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_freeze)
-  [Function `set_borrowable_in_isolation`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrowable_in_isolation)
-  [Function `set_reserve_pause`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_pause)
-  [Function `set_reserve_factor`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_factor)
-  [Function `set_debt_ceiling`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_debt_ceiling)
-  [Function `set_siloed_borrowing`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_siloed_borrowing)
-  [Function `set_borrow_cap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrow_cap)
-  [Function `set_supply_cap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_supply_cap)
-  [Function `set_liquidation_protocol_fee`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_liquidation_protocol_fee)
-  [Function `set_emode_category`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_emode_category)
-  [Function `set_asset_emode_category`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_asset_emode_category)
-  [Function `set_unbacked_mint_cap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_unbacked_mint_cap)
-  [Function `set_pool_pause`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_pool_pause)
-  [Function `update_bridge_protocol_fee`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_bridge_protocol_fee)
-  [Function `update_flashloan_premium_total`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_total)
-  [Function `update_flashloan_premium_to_protocol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_to_protocol)
-  [Function `configure_reserves`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserves)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="default_reserve_interest_rate_strategy.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_default_reserve_interest_rate_strategy">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::default_reserve_interest_rate_strategy</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveBorrowing"></a>

## Struct `ReserveBorrowing`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveBorrowing">ReserveBorrowing</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFlashLoaning"></a>

## Struct `ReserveFlashLoaning`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFlashLoaning">ReserveFlashLoaning</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_CollateralConfigurationChanged"></a>

## Struct `CollateralConfigurationChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_CollateralConfigurationChanged">CollateralConfigurationChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveActive"></a>

## Struct `ReserveActive`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveActive">ReserveActive</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFrozen"></a>

## Struct `ReserveFrozen`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFrozen">ReserveFrozen</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReservePaused"></a>

## Struct `ReservePaused`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReservePaused">ReservePaused</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveDropped"></a>

## Struct `ReserveDropped`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveDropped">ReserveDropped</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFactorChanged"></a>

## Struct `ReserveFactorChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveFactorChanged">ReserveFactorChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowCapChanged"></a>

## Struct `BorrowCapChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowCapChanged">BorrowCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SupplyCapChanged"></a>

## Struct `SupplyCapChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SupplyCapChanged">SupplyCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_LiquidationProtocolFeeChanged"></a>

## Struct `LiquidationProtocolFeeChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_LiquidationProtocolFeeChanged">LiquidationProtocolFeeChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_UnbackedMintCapChanged"></a>

## Struct `UnbackedMintCapChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_UnbackedMintCapChanged">UnbackedMintCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeAssetCategoryChanged"></a>

## Struct `EModeAssetCategoryChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeAssetCategoryChanged">EModeAssetCategoryChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeCategoryAdded"></a>

## Struct `EModeCategoryAdded`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_EModeCategoryAdded">EModeCategoryAdded</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveInterestRateStrategyChanged"></a>

## Struct `ReserveInterestRateStrategyChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_ReserveInterestRateStrategyChanged">ReserveInterestRateStrategyChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_DebtCeilingChanged"></a>

## Struct `DebtCeilingChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_DebtCeilingChanged">DebtCeilingChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SiloedBorrowingChanged"></a>

## Struct `SiloedBorrowingChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_SiloedBorrowingChanged">SiloedBorrowingChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BridgeProtocolFeeUpdated"></a>

## Struct `BridgeProtocolFeeUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BridgeProtocolFeeUpdated">BridgeProtocolFeeUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumTotalUpdated"></a>

## Struct `FlashloanPremiumTotalUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumTotalUpdated">FlashloanPremiumTotalUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumToProtocolUpdated"></a>

## Struct `FlashloanPremiumToProtocolUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_FlashloanPremiumToProtocolUpdated">FlashloanPremiumToProtocolUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowableInIsolationChanged"></a>

## Struct `BorrowableInIsolationChanged`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_BorrowableInIsolationChanged">BorrowableInIsolationChanged</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_CONFIGURATOR_REVISION"></a>



<pre><code><b>const</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_CONFIGURATOR_REVISION">CONFIGURATOR_REVISION</a>: u256 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_init_reserves"></a>

## Function `init_reserves`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_init_reserves">init_reserves</a>(<a href="">account</a>: &<a href="">signer</a>, underlying_asset: <a href="">vector</a>&lt;<b>address</b>&gt;, underlying_asset_decimals: <a href="">vector</a>&lt;u8&gt;, treasury: <a href="">vector</a>&lt;<b>address</b>&gt;, a_token_name: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, a_token_symbol: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, variable_debt_token_name: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, variable_debt_token_symbol: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_drop_reserve"></a>

## Function `drop_reserve`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_drop_reserve">drop_reserve</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_borrowing"></a>

## Function `set_reserve_borrowing`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_borrowing">set_reserve_borrowing</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, enabled: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserve_as_collateral"></a>

## Function `configure_reserve_as_collateral`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserve_as_collateral">configure_reserve_as_collateral</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, ltv: u256, liquidation_threshold: u256, liquidation_bonus: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_flash_loaning"></a>

## Function `set_reserve_flash_loaning`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_flash_loaning">set_reserve_flash_loaning</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, enabled: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_active"></a>

## Function `set_reserve_active`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_active">set_reserve_active</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, active: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_freeze"></a>

## Function `set_reserve_freeze`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_freeze">set_reserve_freeze</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, <b>freeze</b>: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrowable_in_isolation"></a>

## Function `set_borrowable_in_isolation`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrowable_in_isolation">set_borrowable_in_isolation</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, borrowable: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_pause"></a>

## Function `set_reserve_pause`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_pause">set_reserve_pause</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, paused: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_factor"></a>

## Function `set_reserve_factor`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_reserve_factor">set_reserve_factor</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_reserve_factor: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_debt_ceiling"></a>

## Function `set_debt_ceiling`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_debt_ceiling">set_debt_ceiling</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_debt_ceiling: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_siloed_borrowing"></a>

## Function `set_siloed_borrowing`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_siloed_borrowing">set_siloed_borrowing</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_siloed: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrow_cap"></a>

## Function `set_borrow_cap`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_borrow_cap">set_borrow_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_borrow_cap: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_supply_cap"></a>

## Function `set_supply_cap`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_supply_cap">set_supply_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_supply_cap: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_liquidation_protocol_fee"></a>

## Function `set_liquidation_protocol_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_liquidation_protocol_fee">set_liquidation_protocol_fee</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_fee: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_emode_category"></a>

## Function `set_emode_category`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_emode_category">set_emode_category</a>(<a href="">account</a>: &<a href="">signer</a>, category_id: u8, ltv: u16, liquidation_threshold: u16, liquidation_bonus: u16, <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">oracle</a>: <b>address</b>, label: <a href="_String">string::String</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_asset_emode_category"></a>

## Function `set_asset_emode_category`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_asset_emode_category">set_asset_emode_category</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_category_id: u8)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_unbacked_mint_cap"></a>

## Function `set_unbacked_mint_cap`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_unbacked_mint_cap">set_unbacked_mint_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_unbacked_mint_cap: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_pool_pause"></a>

## Function `set_pool_pause`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_set_pool_pause">set_pool_pause</a>(<a href="">account</a>: &<a href="">signer</a>, paused: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_bridge_protocol_fee"></a>

## Function `update_bridge_protocol_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_bridge_protocol_fee">update_bridge_protocol_fee</a>(<a href="">account</a>: &<a href="">signer</a>, new_bridge_protocol_fee: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_total"></a>

## Function `update_flashloan_premium_total`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_total">update_flashloan_premium_total</a>(<a href="">account</a>: &<a href="">signer</a>, new_flashloan_premium_total: u128)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_to_protocol"></a>

## Function `update_flashloan_premium_to_protocol`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_update_flashloan_premium_to_protocol">update_flashloan_premium_to_protocol</a>(<a href="">account</a>: &<a href="">signer</a>, new_flashloan_premium_to_protocol: u128)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserves"></a>

## Function `configure_reserves`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_configurator_configure_reserves">configure_reserves</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <a href="">vector</a>&lt;<b>address</b>&gt;, base_ltv: <a href="">vector</a>&lt;u256&gt;, liquidation_threshold: <a href="">vector</a>&lt;u256&gt;, liquidation_bonus: <a href="">vector</a>&lt;u256&gt;, reserve_factor: <a href="">vector</a>&lt;u256&gt;, borrow_cap: <a href="">vector</a>&lt;u256&gt;, supply_cap: <a href="">vector</a>&lt;u256&gt;, borrowing_enabled: <a href="">vector</a>&lt;bool&gt;, flash_loan_enabled: <a href="">vector</a>&lt;bool&gt;)
</code></pre>
