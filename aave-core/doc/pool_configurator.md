
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_configurator`



-  [Struct `ReserveBorrowing`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveBorrowing)
-  [Struct `ReserveFlashLoaning`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFlashLoaning)
-  [Struct `CollateralConfigurationChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_CollateralConfigurationChanged)
-  [Struct `ReserveActive`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveActive)
-  [Struct `ReserveFrozen`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFrozen)
-  [Struct `ReservePaused`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReservePaused)
-  [Struct `ReserveDropped`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveDropped)
-  [Struct `ReserveFactorChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFactorChanged)
-  [Struct `BorrowCapChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowCapChanged)
-  [Struct `SupplyCapChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SupplyCapChanged)
-  [Struct `LiquidationProtocolFeeChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_LiquidationProtocolFeeChanged)
-  [Struct `UnbackedMintCapChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_UnbackedMintCapChanged)
-  [Struct `EModeAssetCategoryChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeAssetCategoryChanged)
-  [Struct `EModeCategoryAdded`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeCategoryAdded)
-  [Struct `DebtCeilingChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_DebtCeilingChanged)
-  [Struct `SiloedBorrowingChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SiloedBorrowingChanged)
-  [Struct `BridgeProtocolFeeUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BridgeProtocolFeeUpdated)
-  [Struct `FlashloanPremiumTotalUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumTotalUpdated)
-  [Struct `FlashloanPremiumToProtocolUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumToProtocolUpdated)
-  [Struct `BorrowableInIsolationChanged`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowableInIsolationChanged)
-  [Constants](#@Constants_0)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_get_revision)
-  [Function `init_reserves`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_init_reserves)
-  [Function `drop_reserve`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_drop_reserve)
-  [Function `set_reserve_borrowing`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_borrowing)
-  [Function `configure_reserve_as_collateral`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserve_as_collateral)
-  [Function `set_reserve_flash_loaning`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_flash_loaning)
-  [Function `set_reserve_active`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_active)
-  [Function `set_reserve_freeze`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_freeze)
-  [Function `set_borrowable_in_isolation`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrowable_in_isolation)
-  [Function `set_reserve_pause`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_pause)
-  [Function `set_reserve_factor`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_factor)
-  [Function `set_debt_ceiling`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_debt_ceiling)
-  [Function `set_siloed_borrowing`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_siloed_borrowing)
-  [Function `set_borrow_cap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrow_cap)
-  [Function `set_supply_cap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_supply_cap)
-  [Function `set_liquidation_protocol_fee`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_liquidation_protocol_fee)
-  [Function `set_emode_category`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_emode_category)
-  [Function `set_asset_emode_category`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_asset_emode_category)
-  [Function `set_unbacked_mint_cap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_unbacked_mint_cap)
-  [Function `set_pool_pause`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_pool_pause)
-  [Function `update_bridge_protocol_fee`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_bridge_protocol_fee)
-  [Function `update_flashloan_premium_total`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_total)
-  [Function `update_flashloan_premium_to_protocol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_to_protocol)
-  [Function `configure_reserves`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserves)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::default_reserve_interest_rate_strategy</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveBorrowing"></a>

## Struct `ReserveBorrowing`

@dev Emitted when borrowing is enabled or disabled on a reserve.
@param asset The address of the underlying asset of the reserve
@param enabled True if borrowing is enabled, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveBorrowing">ReserveBorrowing</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFlashLoaning"></a>

## Struct `ReserveFlashLoaning`

@dev Emitted when flashloans are enabled or disabled on a reserve.
@param asset The address of the underlying asset of the reserve
@param enabled True if flashloans are enabled, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFlashLoaning">ReserveFlashLoaning</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_CollateralConfigurationChanged"></a>

## Struct `CollateralConfigurationChanged`

@dev Emitted when the collateralization risk parameters for the specified asset are updated.
@param asset The address of the underlying asset of the reserve
@param ltv The loan to value of the asset when used as collateral
@param liquidation_threshold The threshold at which loans using this asset as collateral will be considered undercollateralized
@param liquidation_bonus The bonus liquidators receive to liquidate this asset


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_CollateralConfigurationChanged">CollateralConfigurationChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveActive"></a>

## Struct `ReserveActive`

@dev Emitted when a reserve is activated or deactivated
@param asset The address of the underlying asset of the reserve
@param active True if reserve is active, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveActive">ReserveActive</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFrozen"></a>

## Struct `ReserveFrozen`

@dev Emitted when a reserve is frozen or unfrozen
@param asset The address of the underlying asset of the reserve
@param frozen True if reserve is frozen, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFrozen">ReserveFrozen</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReservePaused"></a>

## Struct `ReservePaused`

@dev Emitted when a reserve is paused or unpaused
@param asset The address of the underlying asset of the reserve
@param paused True if reserve is paused, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReservePaused">ReservePaused</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveDropped"></a>

## Struct `ReserveDropped`

@dev Emitted when a reserve is dropped.
@param asset The address of the underlying asset of the reserve


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveDropped">ReserveDropped</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFactorChanged"></a>

## Struct `ReserveFactorChanged`

@dev Emitted when a reserve factor is updated.
@param asset The address of the underlying asset of the reserve
@param old_reserve_factor The old reserve factor, expressed in bps
@param new_reserve_factor The new reserve factor, expressed in bps


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_ReserveFactorChanged">ReserveFactorChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowCapChanged"></a>

## Struct `BorrowCapChanged`

@dev Emitted when the borrow cap of a reserve is updated.
@param asset The address of the underlying asset of the reserve
@param old_borrow_cap The old borrow cap
@param new_borrow_cap The new borrow cap


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowCapChanged">BorrowCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SupplyCapChanged"></a>

## Struct `SupplyCapChanged`

@dev Emitted when the supply cap of a reserve is updated.
@param asset The address of the underlying asset of the reserve
@param old_supply_cap The old supply cap
@param new_supply_cap The new supply cap


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SupplyCapChanged">SupplyCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_LiquidationProtocolFeeChanged"></a>

## Struct `LiquidationProtocolFeeChanged`

@dev Emitted when the liquidation protocol fee of a reserve is updated.
@param asset The address of the underlying asset of the reserve
@param old_fee The old liquidation protocol fee, expressed in bps
@param new_fee The new liquidation protocol fee, expressed in bps


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_LiquidationProtocolFeeChanged">LiquidationProtocolFeeChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_UnbackedMintCapChanged"></a>

## Struct `UnbackedMintCapChanged`

@dev Emitted when the unbacked mint cap of a reserve is updated.
@param asset The address of the underlying asset of the reserve
@param old_unbacked_mint_cap The old unbacked mint cap
@param new_unbacked_mint_cap The new unbacked mint cap


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_UnbackedMintCapChanged">UnbackedMintCapChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeAssetCategoryChanged"></a>

## Struct `EModeAssetCategoryChanged`

@dev Emitted when the category of an asset in eMode is changed.
@param asset The address of the underlying asset of the reserve
@param old_category_id The old eMode asset category
@param new_category_id The new eMode asset category


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeAssetCategoryChanged">EModeAssetCategoryChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeCategoryAdded"></a>

## Struct `EModeCategoryAdded`

@dev Emitted when a new eMode category is added.
@param category_id The new eMode category id
@param ltv The ltv for the asset category in eMode
@param liquidation_threshold The liquidationThreshold for the asset category in eMode
@param liquidation_bonus The liquidationBonus for the asset category in eMode
@param oracle The optional address of the price oracle specific for this category
@param label A human readable identifier for the category


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_EModeCategoryAdded">EModeCategoryAdded</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_DebtCeilingChanged"></a>

## Struct `DebtCeilingChanged`

@dev Emitted when the debt ceiling of an asset is set.
@param asset The address of the underlying asset of the reserve
@param old_debt_ceiling The old debt ceiling
@param new_debt_ceiling The new debt ceiling


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_DebtCeilingChanged">DebtCeilingChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SiloedBorrowingChanged"></a>

## Struct `SiloedBorrowingChanged`

@dev Emitted when the the siloed borrowing state for an asset is changed.
@param asset The address of the underlying asset of the reserve
@param old_state The old siloed borrowing state
@param new_state The new siloed borrowing state


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_SiloedBorrowingChanged">SiloedBorrowingChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BridgeProtocolFeeUpdated"></a>

## Struct `BridgeProtocolFeeUpdated`

@dev Emitted when the bridge protocol fee is updated.
@param old_bridge_protocol_fee The old protocol fee, expressed in bps
@param new_bridge_protocol_fee The new protocol fee, expressed in bps


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BridgeProtocolFeeUpdated">BridgeProtocolFeeUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumTotalUpdated"></a>

## Struct `FlashloanPremiumTotalUpdated`

@dev Emitted when the total premium on flashloans is updated.
@param old_flashloan_premium_total The old premium, expressed in bps
@param new_flashloan_premium_total The new premium, expressed in bps


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumTotalUpdated">FlashloanPremiumTotalUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumToProtocolUpdated"></a>

## Struct `FlashloanPremiumToProtocolUpdated`

@dev Emitted when the part of the premium that goes to protocol is updated.
@param old_flashloan_premium_to_protocol The old premium, expressed in bps
@param new_flashloan_premium_to_protocol The new premium, expressed in bps


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_FlashloanPremiumToProtocolUpdated">FlashloanPremiumToProtocolUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowableInIsolationChanged"></a>

## Struct `BorrowableInIsolationChanged`

@dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
@param asset The address of the underlying asset of the reserve
@param borrowable True if the reserve is borrowable in isolation, false otherwise


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_BorrowableInIsolationChanged">BorrowableInIsolationChanged</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_CONFIGURATOR_REVISION"></a>



<pre><code><b>const</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_CONFIGURATOR_REVISION">CONFIGURATOR_REVISION</a>: u256 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_get_revision"></a>

## Function `get_revision`

@notice Returns the revision of the configurator


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_init_reserves"></a>

## Function `init_reserves`

@notice Initializes multiple reserves.
@param account The address of the caller
@param underlying_asset The list of the underlying assets of the reserves
@param underlying_asset_decimals The list of the decimals of the underlying assets
@param treasury The list of the treasury addresses of the reserves
@param a_token_name The list of the aToken names of the reserves
@param a_token_symbol The list of the aToken symbols of the reserves
@param variable_debt_token_name The list of the variable debt token names of the reserves
@param variable_debt_token_symbol The list of the variable debt token symbols of the reserves
@dev The caller needs to be an asset listing or pool admin


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_init_reserves">init_reserves</a>(<a href="">account</a>: &<a href="">signer</a>, underlying_asset: <a href="">vector</a>&lt;<b>address</b>&gt;, underlying_asset_decimals: <a href="">vector</a>&lt;u8&gt;, treasury: <a href="">vector</a>&lt;<b>address</b>&gt;, a_token_name: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, a_token_symbol: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, variable_debt_token_name: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, variable_debt_token_symbol: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_drop_reserve"></a>

## Function `drop_reserve`

@notice Drops a reserve entirely.
@param account The address of the caller
@param asset The address of the reserve to drop


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_drop_reserve">drop_reserve</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_borrowing"></a>

## Function `set_reserve_borrowing`

@notice Configures borrowing on a reserve.
@dev Can only be disabled (set to false)
@param asset The address of the underlying asset of the reserve
@param enabled True if borrowing needs to be enabled, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_borrowing">set_reserve_borrowing</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, enabled: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserve_as_collateral"></a>

## Function `configure_reserve_as_collateral`

@notice Configures the reserve collateralization parameters.
@dev All the values are expressed in bps. A value of 10000, results in 100.00%
@dev The <code>liquidation_bonus</code> is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
@param asset The address of the underlying asset of the reserve
@param ltv The loan to value of the asset when used as collateral
@param liquidation_threshold The threshold at which loans using this asset as collateral will be considered undercollateralized
@param liquidation_bonus The bonus liquidators receive to liquidate this asset


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserve_as_collateral">configure_reserve_as_collateral</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, ltv: u256, liquidation_threshold: u256, liquidation_bonus: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_flash_loaning"></a>

## Function `set_reserve_flash_loaning`

@notice Enable or disable flashloans on a reserve
@param asset The address of the underlying asset of the reserve
@param enabled True if flashloans need to be enabled, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_flash_loaning">set_reserve_flash_loaning</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, enabled: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_active"></a>

## Function `set_reserve_active`

@notice Activate or deactivate a reserve
@param asset The address of the underlying asset of the reserve
@param active True if the reserve needs to be active, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_active">set_reserve_active</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, active: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_freeze"></a>

## Function `set_reserve_freeze`

@notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
@param asset The address of the underlying asset of the reserve
@param freeze True if the reserve needs to be frozen, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_freeze">set_reserve_freeze</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, <b>freeze</b>: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrowable_in_isolation"></a>

## Function `set_borrowable_in_isolation`

@notice Sets the borrowable in isolation flag for the reserve.
@dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
borrowed amount will be accumulated in the isolated collateral's total debt exposure
@dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
consistency in the debt ceiling calculations
@param asset The address of the underlying asset of the reserve
@param borrowable True if the asset should be borrowable in isolation, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrowable_in_isolation">set_borrowable_in_isolation</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, borrowable: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_pause"></a>

## Function `set_reserve_pause`

@notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
swap interest rate, liquidate, atoken transfers).
@param asset The address of the underlying asset of the reserve
@param paused True if pausing the reserve, false if unpausing


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_pause">set_reserve_pause</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, paused: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_factor"></a>

## Function `set_reserve_factor`

@notice Updates the reserve factor of a reserve.
@param asset The address of the underlying asset of the reserve
@param new_reserve_factor The new reserve factor of the reserve


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_reserve_factor">set_reserve_factor</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_reserve_factor: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_debt_ceiling"></a>

## Function `set_debt_ceiling`

@notice Sets the debt ceiling for an asset.
@param new_debt_ceiling The new debt ceiling


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_debt_ceiling">set_debt_ceiling</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_debt_ceiling: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_siloed_borrowing"></a>

## Function `set_siloed_borrowing`

@notice Sets siloed borrowing for an asset
@param new_siloed The new siloed borrowing state


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_siloed_borrowing">set_siloed_borrowing</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_siloed: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrow_cap"></a>

## Function `set_borrow_cap`

@notice Updates the borrow cap of a reserve.
@param asset The address of the underlying asset of the reserve
@param new_borrow_cap The new borrow cap of the reserve


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_borrow_cap">set_borrow_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_borrow_cap: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_supply_cap"></a>

## Function `set_supply_cap`

@notice Updates the supply cap of a reserve.
@param asset The address of the underlying asset of the reserve
@param new_supply_cap The new supply cap of the reserve


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_supply_cap">set_supply_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_supply_cap: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_liquidation_protocol_fee"></a>

## Function `set_liquidation_protocol_fee`

@notice Updates the liquidation protocol fee of reserve.
@param asset The address of the underlying asset of the reserve
@param new_fee The new liquidation protocol fee of the reserve, expressed in bps


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_liquidation_protocol_fee">set_liquidation_protocol_fee</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_fee: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_emode_category"></a>

## Function `set_emode_category`

@notice Adds a new efficiency mode (eMode) category.
@dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
overcollateralization of the users using this category.
@dev The new ltv and liquidation threshold must be greater than the base
ltvs and liquidation thresholds of all assets within the eMode category
@param category_id The id of the category to be configured
@param ltv The ltv associated with the category
@param liquidation_threshold The liquidation threshold associated with the category
@param liquidation_bonus The liquidation bonus associated with the category
@param oracle The oracle associated with the category
@param label A label identifying the category


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_emode_category">set_emode_category</a>(<a href="">account</a>: &<a href="">signer</a>, category_id: u8, ltv: u16, liquidation_threshold: u16, liquidation_bonus: u16, <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">oracle</a>: <b>address</b>, label: <a href="_String">string::String</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_asset_emode_category"></a>

## Function `set_asset_emode_category`

@notice Assign an efficiency mode (eMode) category to asset.
@param asset The address of the underlying asset of the reserve
@param new_category_id The new category id of the asset


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_asset_emode_category">set_asset_emode_category</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_category_id: u8)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_unbacked_mint_cap"></a>

## Function `set_unbacked_mint_cap`

@notice Updates the unbacked mint cap of reserve.
@param asset The address of the underlying asset of the reserve
@param new_unbacked_mint_cap The new unbacked mint cap of the reserve


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_unbacked_mint_cap">set_unbacked_mint_cap</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, new_unbacked_mint_cap: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_pool_pause"></a>

## Function `set_pool_pause`

@notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
are suspended.
@param paused True if protocol needs to be paused, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_set_pool_pause">set_pool_pause</a>(<a href="">account</a>: &<a href="">signer</a>, paused: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_bridge_protocol_fee"></a>

## Function `update_bridge_protocol_fee`

@notice Updates the protocol fee on the bridging
@param new_bridge_protocol_fee The part of the premium sent to the protocol treasury


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_bridge_protocol_fee">update_bridge_protocol_fee</a>(<a href="">account</a>: &<a href="">signer</a>, new_bridge_protocol_fee: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_total"></a>

## Function `update_flashloan_premium_total`

@notice Updates the total flash loan premium.
Total flash loan premium consists of two parts:
- A part is sent to aToken holders as extra balance
- A part is collected by the protocol reserves
@dev Expressed in bps
@dev The premium is calculated on the total amount borrowed
@param new_flashloan_premium_total The total flashloan premium


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_total">update_flashloan_premium_total</a>(<a href="">account</a>: &<a href="">signer</a>, new_flashloan_premium_total: u128)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_to_protocol"></a>

## Function `update_flashloan_premium_to_protocol`

@notice Updates the flash loan premium collected by protocol reserves
@dev Expressed in bps
@dev The premium to protocol is calculated on the total flashloan premium
@param new_flashloan_premium_to_protocol The part of the flashloan premium sent to the protocol treasury


<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_update_flashloan_premium_to_protocol">update_flashloan_premium_to_protocol</a>(<a href="">account</a>: &<a href="">signer</a>, new_flashloan_premium_to_protocol: u128)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserves"></a>

## Function `configure_reserves`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_configurator.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_configurator_configure_reserves">configure_reserves</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <a href="">vector</a>&lt;<b>address</b>&gt;, base_ltv: <a href="">vector</a>&lt;u256&gt;, liquidation_threshold: <a href="">vector</a>&lt;u256&gt;, liquidation_bonus: <a href="">vector</a>&lt;u256&gt;, reserve_factor: <a href="">vector</a>&lt;u256&gt;, borrow_cap: <a href="">vector</a>&lt;u256&gt;, supply_cap: <a href="">vector</a>&lt;u256&gt;, borrowing_enabled: <a href="">vector</a>&lt;bool&gt;, flash_loan_enabled: <a href="">vector</a>&lt;bool&gt;)
</code></pre>
