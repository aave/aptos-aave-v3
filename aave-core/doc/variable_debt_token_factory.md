
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory`



-  [Struct `Initialized`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_Initialized)
-  [Constants](#@Constants_0)
-  [Function `create_token`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_create_token)
-  [Function `mint`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_mint)
-  [Function `burn`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_burn)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_revision)
-  [Function `get_underlying_asset_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_underlying_asset_address)
-  [Function `get_metadata_by_symbol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_metadata_by_symbol)
-  [Function `token_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_token_address)
-  [Function `asset_metadata`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_asset_metadata)
-  [Function `get_previous_index`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_previous_index)
-  [Function `scaled_balance_of`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_balance_of)
-  [Function `scaled_total_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_total_supply)
-  [Function `get_scaled_user_balance_and_supply`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_scaled_user_balance_and_supply)
-  [Function `name`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_name)
-  [Function `symbol`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_symbol)
-  [Function `decimals`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_decimals)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="token_base.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_token_base">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::token_base</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_Initialized"></a>

## Struct `Initialized`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_Initialized">Initialized</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_DEBT_TOKEN_REVISION"></a>



<pre><code><b>const</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_DEBT_TOKEN_REVISION">DEBT_TOKEN_REVISION</a>: u256 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_E_NOT_V_TOKEN_ADMIN"></a>



<pre><code><b>const</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_E_NOT_V_TOKEN_ADMIN">E_NOT_V_TOKEN_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_create_token"></a>

## Function `create_token`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_create_token">create_token</a>(<a href="">signer</a>: &<a href="">signer</a>, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, underlying_asset: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_mint"></a>

## Function `mint`

@notice Mints debt token to the <code>on_behalf_of</code> address
@param caller The address receiving the borrowed underlying, being the delegatee in case
of credit delegate, or same as <code>on_behalf_of</code> otherwise
@param on_behalf_of The address receiving the debt tokens
@param amount The amount of debt being minted
@param index The variable debt index of the reserve
@param metadata_address The address of the metadata object


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_mint">mint</a>(caller: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_burn"></a>

## Function `burn`

@notice Burns user variable debt
@dev In some instances, a burn transaction will emit a mint event
if the amount to burn is less than the interest that the user accrued
@param from The address from which the debt will be burned
@param amount The amount getting burned
@param index The variable debt index of the reserve
@param metadata_address The address of the metadata object


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_burn">burn</a>(from: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_underlying_asset_address"></a>

## Function `get_underlying_asset_address`

@notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
@param metadata_address The address of the metadata object
@return The address of the underlying asset


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_underlying_asset_address">get_underlying_asset_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_metadata_by_symbol"></a>

## Function `get_metadata_by_symbol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_metadata_by_symbol">get_metadata_by_symbol</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_token_address"></a>

## Function `token_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_token_address">token_address</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_asset_metadata"></a>

## Function `asset_metadata`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_asset_metadata">asset_metadata</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_previous_index"></a>

## Function `get_previous_index`

@notice Returns last index interest was accrued to the user's balance
@param user The address of the user
@param metadata_address The address of the variable debt token
@return The last index interest was accrued to the user's balance, expressed in ray


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_previous_index">get_previous_index</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_balance_of"></a>

## Function `scaled_balance_of`

@notice Returns the scaled balance of the user.
@dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
at the moment of the update
@param owner The user whose balance is calculated
@param metadata_address The address of the variable debt token
@return The scaled balance of the user


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_balance_of">scaled_balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_total_supply"></a>

## Function `scaled_total_supply`

@notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
@param metadata_address The address of the variable debt token
@return The scaled total supply


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_scaled_total_supply">scaled_total_supply</a>(metadata_address: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_scaled_user_balance_and_supply"></a>

## Function `get_scaled_user_balance_and_supply`

@notice Returns the scaled balance of the user and the scaled total supply.
@param owner The address of the user
@param metadata_address The address of the variable debt token
@return The scaled balance of the user
@return The scaled total supply


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_get_scaled_user_balance_and_supply">get_scaled_user_balance_and_supply</a>(owner: <b>address</b>, metadata_address: <b>address</b>): (u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_name"></a>

## Function `name`

Get the name of the fungible asset from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_name">name</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_symbol"></a>

## Function `symbol`

Get the symbol of the fungible asset from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_symbol">symbol</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_decimals"></a>

## Function `decimals`

Get the decimals from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory_decimals">decimals</a>(metadata_address: <b>address</b>): u8
</code></pre>
