
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::bridge_logic`



-  [Struct `ReserveUsedAsCollateralEnabled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `MintUnbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_MintUnbacked)
-  [Struct `BackUnbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_BackUnbacked)
-  [Function `mint_unbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_mint_unbacked)
-  [Function `back_unbacked`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_back_unbacked)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_validation</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`

@dev Emitted on setUserUseReserveAsCollateral()
@param reserve The address of the underlying asset of the reserve
@param user The address of the user enabling the usage as collateral


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_MintUnbacked"></a>

## Struct `MintUnbacked`

@dev Emitted on mint_unbacked()
@param reserve The address of the underlying asset of the reserve
@param user The address initiating the supply
@param on_behalf_of The beneficiary of the supplied assets, receiving the aTokens
@param amount The amount of supplied assets
@param referral_code The referral code used


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_MintUnbacked">MintUnbacked</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_BackUnbacked"></a>

## Struct `BackUnbacked`

@dev Emitted on back_unbacked()
@param reserve The address of the underlying asset of the reserve
@param backer The address paying for the backing
@param amount The amount added as backing
@param fee The amount paid in fees


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_BackUnbacked">BackUnbacked</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_mint_unbacked"></a>

## Function `mint_unbacked`

@notice Mint unbacked aTokens to a user and updates the unbacked for the reserve.
@dev Essentially a supply without transferring the underlying.
@dev Emits the <code><a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_MintUnbacked">MintUnbacked</a></code> event
@dev Emits the <code><a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a></code> if asset is set as collateral
@param asset The address of the underlying asset to mint aTokens of
@param amount The amount to mint
@param on_behalf_of The address that will receive the aTokens
@param referral_code Code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle-man


<pre><code><b>public</b> entry <b>fun</b> <a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_mint_unbacked">mint_unbacked</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_back_unbacked"></a>

## Function `back_unbacked`

@notice Back the current unbacked with <code>amount</code> and pay <code>fee</code>.
@dev It is not possible to back more than the existing unbacked amount of the reserve
@dev Emits the <code><a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_BackUnbacked">BackUnbacked</a></code> event
@param asset The address of the underlying asset to repay
@param amount The amount to back
@param fee The amount paid in fees
@return The backed amount


<pre><code><b>public</b> entry <b>fun</b> <a href="bridge_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_bridge_logic_back_unbacked">back_unbacked</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, fee: u256)
</code></pre>
