
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::token_base`



-  [Struct `Transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Transfer)
-  [Struct `Mint`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Mint)
-  [Struct `Burn`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Burn)
-  [Struct `UserState`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserState)
-  [Resource `UserStateMap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserStateMap)
-  [Struct `TokenData`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData)
-  [Resource `TokenMap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenMap)
-  [Resource `ManagedFungibleAsset`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_ManagedFungibleAsset)
-  [Constants](#@Constants_0)
-  [Function `get_user_state`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_user_state)
-  [Function `get_token_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_token_data)
-  [Function `get_underlying_asset`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_underlying_asset)
-  [Function `get_treasury_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_treasury_address)
-  [Function `get_resource_account`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_resource_account)
-  [Function `get_previous_index`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_previous_index)
-  [Function `get_scale_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scale_total_supply)
-  [Function `create_a_token`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_a_token)
-  [Function `create_variable_token`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_variable_token)
-  [Function `mint_scaled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_mint_scaled)
-  [Function `burn_scaled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_burn_scaled)
-  [Function `transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer)
-  [Function `transfer_internal`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer_internal)
-  [Function `scale_balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_balance_of)
-  [Function `balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_balance_of)
-  [Function `scale_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_total_supply)
-  [Function `supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_supply)
-  [Function `get_scaled_user_balance_and_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scaled_user_balance_and_supply)
-  [Function `maximum`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_maximum)
-  [Function `name`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_name)
-  [Function `symbol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_symbol)
-  [Function `decimals`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_decimals)
-  [Function `only_pool_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_pool_admin)
-  [Function `only_token_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_token_admin)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::string_utils</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Transfer"></a>

## Struct `Transfer`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Transfer">Transfer</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Mint"></a>

## Struct `Mint`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Mint">Mint</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Burn"></a>

## Struct `Burn`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_Burn">Burn</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserState"></a>

## Struct `UserState`



<pre><code><b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserState">UserState</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserStateMap"></a>

## Resource `UserStateMap`



<pre><code><b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserStateMap">UserStateMap</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData"></a>

## Struct `TokenData`



<pre><code><b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">TokenData</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenMap"></a>

## Resource `TokenMap`



<pre><code><b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenMap">TokenMap</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_ManagedFungibleAsset"></a>

## Resource `ManagedFungibleAsset`

Hold refs to control the minting, transfer and burning of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_ManagedFungibleAsset">ManagedFungibleAsset</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_ENOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_ENOT_OWNER">ENOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_ACCOUNT_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_ACCOUNT_NOT_EXISTS">E_ACCOUNT_NOT_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_TOKEN_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_TOKEN_ALREADY_EXISTS">E_TOKEN_ALREADY_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_TOKEN_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_E_TOKEN_NOT_EXISTS">E_TOKEN_NOT_EXISTS</a>: u64 = 4;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_user_state"></a>

## Function `get_user_state`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_user_state">get_user_state</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, token_metadata_address: <b>address</b>): <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_UserState">token_base::UserState</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_token_data"></a>

## Function `get_token_data`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_token_data">get_token_data</a>(token_metadata_address: <b>address</b>): <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">token_base::TokenData</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_underlying_asset"></a>

## Function `get_underlying_asset`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_underlying_asset">get_underlying_asset</a>(token_data: &<a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">token_base::TokenData</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_treasury_address"></a>

## Function `get_treasury_address`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_treasury_address">get_treasury_address</a>(token_data: &<a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">token_base::TokenData</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_resource_account"></a>

## Function `get_resource_account`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_resource_account">get_resource_account</a>(token_data: &<a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">token_base::TokenData</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_previous_index"></a>

## Function `get_previous_index`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_previous_index">get_previous_index</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scale_total_supply"></a>

## Function `get_scale_total_supply`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scale_total_supply">get_scale_total_supply</a>(token_data: &<a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_TokenData">token_base::TokenData</a>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_a_token"></a>

## Function `create_a_token`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_a_token">create_a_token</a>(<a href="">signer</a>: &<a href="">signer</a>, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, underlying_asset: <b>address</b>, treasury: <b>address</b>, <a href="">resource_account</a>: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_variable_token"></a>

## Function `create_variable_token`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_create_variable_token">create_variable_token</a>(<a href="">signer</a>: &<a href="">signer</a>, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, underlying_asset: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_mint_scaled"></a>

## Function `mint_scaled`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_mint_scaled">mint_scaled</a>(caller: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_burn_scaled"></a>

## Function `burn_scaled`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_burn_scaled">burn_scaled</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, target: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer"></a>

## Function `transfer`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer">transfer</a>(sender: <b>address</b>, recipient: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer_internal"></a>

## Function `transfer_internal`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_transfer_internal">transfer_internal</a>(from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_balance_of"></a>

## Function `scale_balance_of`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_balance_of">scale_balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_balance_of"></a>

## Function `balance_of`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_balance_of">balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_total_supply"></a>

## Function `scale_total_supply`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_scale_total_supply">scale_total_supply</a>(metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_supply"></a>

## Function `supply`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_supply">supply</a>(metadata_address: <b>address</b>): <a href="_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scaled_user_balance_and_supply"></a>

## Function `get_scaled_user_balance_and_supply`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_get_scaled_user_balance_and_supply">get_scaled_user_balance_and_supply</a>(owner: <b>address</b>, metadata_address: <b>address</b>): (u256, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_maximum"></a>

## Function `maximum`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_maximum">maximum</a>(metadata_address: <b>address</b>): <a href="_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_name"></a>

## Function `name`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_name">name</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_symbol"></a>

## Function `symbol`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_symbol">symbol</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_decimals"></a>

## Function `decimals`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_decimals">decimals</a>(metadata_address: <b>address</b>): u8
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_pool_admin"></a>

## Function `only_pool_admin`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_pool_admin">only_pool_admin</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_token_admin"></a>

## Function `only_token_admin`



<pre><code><b>public</b> <b>fun</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base_only_token_admin">only_token_admin</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>
