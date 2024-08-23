
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::supply_logic`



-  [Struct `Supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Supply)
-  [Struct `Withdraw`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Withdraw)
-  [Struct `ReserveUsedAsCollateralEnabled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `ReserveUsedAsCollateralDisabled`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralDisabled)
-  [Function `supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_supply)
-  [Function `withdraw`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_withdraw)
-  [Function `finalize_transfer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_finalize_transfer)
-  [Function `set_user_use_reserve_as_collateral`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_set_user_use_reserve_as_collateral)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_validation</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Supply"></a>

## Struct `Supply`

@dev Emitted on supply()
@param reserve The address of the underlying asset of the reserve
@param user The address initiating the supply
@param on_behalf_of The beneficiary of the supply, receiving the aTokens
@param amount The amount supplied
@param referral_code The referral code used


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Supply">Supply</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Withdraw"></a>

## Struct `Withdraw`

@dev Emitted on withdraw()
@param reserve The address of the underlying asset being withdrawn
@param user The address initiating the withdrawal, owner of aTokens
@param to The address that will receive the underlying
@param amount The amount to be withdrawn


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_Withdraw">Withdraw</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`

@dev Emitted on setUserUseReserveAsCollateral()
@param reserve The address of the underlying asset of the reserve
@param user The address of the user enabling the usage as collateral


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralDisabled"></a>

## Struct `ReserveUsedAsCollateralDisabled`

@dev Emitted on setUserUseReserveAsCollateral()
@param reserve The address of the underlying asset of the reserve
@param user The address of the user enabling the usage as collateral


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_ReserveUsedAsCollateralDisabled">ReserveUsedAsCollateralDisabled</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_supply"></a>

## Function `supply`

@notice Supplies an <code>amount</code> of underlying asset into the reserve, receiving in return overlying aTokens.
- E.g. User supplies 100 USDC and gets in return 100 aUSDC
@param account The account that will supply the asset
@param asset The address of the underlying asset to supply
@param amount The amount to be supplied
@param on_behalf_of The address that will receive the aTokens, same as msg.sender if the user
wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
is a different wallet
@param referral_code Code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle-man


<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_supply">supply</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_withdraw"></a>

## Function `withdraw`

@notice Withdraws an <code>amount</code> of underlying asset from the reserve, burning the equivalent aTokens owned
E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
@param asset The address of the underlying asset to withdraw
@param amount The underlying amount to be withdrawn
- Send the value type(uint256).max in order to withdraw the whole aToken balance
@param to The address that will receive the underlying, same as msg.sender if the user
wants to receive it on his own wallet, or a different address if the beneficiary is a
different wallet


<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_withdraw">withdraw</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, <b>to</b>: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_finalize_transfer"></a>

## Function `finalize_transfer`

@notice Validates and finalizes an aToken transfer
@dev Only callable by the overlying aToken of the <code>asset</code>
@param asset The address of the underlying asset of the aToken
@param from The user from which the aTokens are transferred
@param to The user receiving the aTokens
@param amount The amount being transferred/withdrawn
@param balance_from_before The aToken balance of the <code>from</code> user before the transfer
@param balance_to_before The aToken balance of the <code><b>to</b></code> user before the transfer


<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_finalize_transfer">finalize_transfer</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256, balance_from_before: u256, balance_to_before: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_set_user_use_reserve_as_collateral"></a>

## Function `set_user_use_reserve_as_collateral`

@notice Allows suppliers to enable/disable a specific supplied asset as collateral
@param asset The address of the underlying asset supplied
@param use_as_collateral True if the user wants to use the supply as collateral, false otherwise


<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_supply_logic_set_user_use_reserve_as_collateral">set_user_use_reserve_as_collateral</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, use_as_collateral: bool)
</code></pre>
