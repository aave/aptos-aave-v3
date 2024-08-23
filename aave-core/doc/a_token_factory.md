
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory`



-  [Struct `Initialized`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_Initialized)
-  [Struct `BalanceTransfer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_BalanceTransfer)
-  [Constants](#@Constants_0)
-  [Function `create_token`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_create_token)
-  [Function `rescue_tokens`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_rescue_tokens)
-  [Function `mint`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint)
-  [Function `burn`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_burn)
-  [Function `mint_to_treasury`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint_to_treasury)
-  [Function `transfer_underlying_to`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_underlying_to)
-  [Function `transfer_on_liquidation`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_on_liquidation)
-  [Function `handle_repayment`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_handle_repayment)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_revision)
-  [Function `get_token_account_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_token_account_address)
-  [Function `get_metadata_by_symbol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_metadata_by_symbol)
-  [Function `token_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_token_address)
-  [Function `asset_metadata`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_asset_metadata)
-  [Function `get_reserve_treasury_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_reserve_treasury_address)
-  [Function `get_underlying_asset_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_underlying_asset_address)
-  [Function `get_previous_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_previous_index)
-  [Function `get_scaled_user_balance_and_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_scaled_user_balance_and_supply)
-  [Function `scaled_balance_of`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_balance_of)
-  [Function `scaled_total_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_total_supply)
-  [Function `name`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_name)
-  [Function `symbol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_symbol)
-  [Function `decimals`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_decimals)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::aptos_account</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::resource_account</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="token_base.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_token_base">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::token_base</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_Initialized"></a>

## Struct `Initialized`

@dev Emitted when an aToken is initialized
@param underlyingAsset The address of the underlying asset
@param treasury The address of the treasury
@param a_token_decimals The decimals of the underlying
@param a_token_name The name of the aToken
@param a_token_symbol The symbol of the aToken


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_Initialized">Initialized</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_BalanceTransfer"></a>

## Struct `BalanceTransfer`

@dev Emitted during the transfer action
@param from The user whose tokens are being transferred
@param to The recipient
@param value The scaled amount being transferred
@param index The next liquidity index of the reserve


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_BalanceTransfer">BalanceTransfer</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_ATOKEN_REVISION"></a>



<pre><code><b>const</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_ATOKEN_REVISION">ATOKEN_REVISION</a>: u256 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_E_NOT_A_TOKEN_ADMIN"></a>



<pre><code><b>const</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_E_NOT_A_TOKEN_ADMIN">E_NOT_A_TOKEN_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_create_token"></a>

## Function `create_token`

@notice Creates a new aToken
@param signer The signer of the transaction
@param name The name of the aToken
@param symbol The symbol of the aToken
@param decimals The decimals of the aToken
@param icon_uri The icon URI of the aToken
@param project_uri The project URI of the aToken
@param underlying_asset The address of the underlying asset
@param treasury The address of the treasury


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_create_token">create_token</a>(<a href="">signer</a>: &<a href="">signer</a>, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, underlying_asset: <b>address</b>, treasury: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_rescue_tokens"></a>

## Function `rescue_tokens`

@notice Rescue and transfer tokens locked in this contract
@param token The address of the token
@param to The address of the recipient
@param amount The amount of token to transfer


<pre><code><b>public</b> entry <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_rescue_tokens">rescue_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, token: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint"></a>

## Function `mint`

@notice Mints <code>amount</code> aTokens to <code><a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a></code>
@param caller The address performing the mint
@param on_behalf_of The address of the user that will receive the minted aTokens
@param amount The amount of tokens getting minted
@param index The next liquidity index of the reserve
@param metadata_address The address of the aToken


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint">mint</a>(caller: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_burn"></a>

## Function `burn`

@notice Burns aTokens from <code><a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a></code> and sends the equivalent amount of underlying to <code>receiverOfUnderlying</code>
@dev In some instances, the mint event could be emitted from a burn transaction
if the amount to burn is less than the interest that the user accrued
@param from The address from which the aTokens will be burned
@param receiver_of_underlying The address that will receive the underlying
@param amount The amount being burned
@param index The next liquidity index of the reserve
@param metadata_address The address of the aToken


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_burn">burn</a>(from: <b>address</b>, receiver_of_underlying: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint_to_treasury"></a>

## Function `mint_to_treasury`

@notice Mints aTokens to the reserve treasury
@param amount The amount of tokens getting minted
@param index The next liquidity index of the reserve
@param metadata_address The address of the aToken


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_mint_to_treasury">mint_to_treasury</a>(amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_underlying_to"></a>

## Function `transfer_underlying_to`

@notice Transfers the underlying asset to <code>target</code>.
@dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
@param to The recipient of the underlying
@param amount The amount getting transferred
@param metadata_address The address of the aToken


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_underlying_to">transfer_underlying_to</a>(<b>to</b>: <b>address</b>, amount: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_on_liquidation"></a>

## Function `transfer_on_liquidation`

@notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
@param from The address getting liquidated, current owner of the aTokens
@param to The recipient
@param amount The amount of tokens getting transferred
@param index The next liquidity index of the reserve
@param metadata_address The address of the aToken


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_transfer_on_liquidation">transfer_on_liquidation</a>(from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_handle_repayment"></a>

## Function `handle_repayment`

@notice Handles the underlying received by the aToken after the transfer has been completed.
@dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
to receive LM rewards. In that case, <code>handleRepayment()</code> would perform the staking of the underlying asset.
@param user The user executing the repayment
@param on_behalf_of The address of the user who will get his debt reduced/removed
@param amount The amount getting repaid
@param metadata_address The address of the aToken


<pre><code><b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_handle_repayment">handle_repayment</a>(_user: <b>address</b>, _onBehalfOf: <b>address</b>, _amount: u256, _metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_token_account_address"></a>

## Function `get_token_account_address`

@notice Return the address of the managed fungible asset that's created resource account.
@param metadata_address The address of the aToken


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_token_account_address">get_token_account_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_metadata_by_symbol"></a>

## Function `get_metadata_by_symbol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_metadata_by_symbol">get_metadata_by_symbol</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_token_address"></a>

## Function `token_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_token_address">token_address</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_asset_metadata"></a>

## Function `asset_metadata`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_asset_metadata">asset_metadata</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_reserve_treasury_address"></a>

## Function `get_reserve_treasury_address`

@notice Returns the address of the Aave treasury, receiving the fees on this aToken.
@param metadata_address The address of the aToken
@return Address of the Aave treasury


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_reserve_treasury_address">get_reserve_treasury_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_underlying_asset_address"></a>

## Function `get_underlying_asset_address`

@notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
@param metadata_address The address of the aToken
@return The address of the underlying asset


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_underlying_asset_address">get_underlying_asset_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_previous_index"></a>

## Function `get_previous_index`

@notice Returns last index interest was accrued to the user's balance
@param user The address of the user
@param metadata_address The address of the aToken
@return The last index interest was accrued to the user's balance, expressed in ray


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_previous_index">get_previous_index</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_scaled_user_balance_and_supply"></a>

## Function `get_scaled_user_balance_and_supply`

@notice Returns the scaled balance of the user and the scaled total supply.
@param owner The address of the user
@param metadata_address The address of the aToken
@return The scaled balance of the user
@return The scaled total supply


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_get_scaled_user_balance_and_supply">get_scaled_user_balance_and_supply</a>(owner: <b>address</b>, metadata_address: <b>address</b>): (u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_balance_of"></a>

## Function `scaled_balance_of`

@notice Returns the scaled balance of the user.
@dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
at the moment of the update
@param owner The user whose balance is calculated
@param metadata_address The address of the aToken
@return The scaled balance of the user


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_balance_of">scaled_balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_total_supply"></a>

## Function `scaled_total_supply`

@notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
@param metadata_address The address of the aToken
@return The scaled total supply


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_scaled_total_supply">scaled_total_supply</a>(metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_name"></a>

## Function `name`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_name">name</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_symbol"></a>

## Function `symbol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_symbol">symbol</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_decimals"></a>

## Function `decimals`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory_decimals">decimals</a>(metadata_address: <b>address</b>): u8
</code></pre>
