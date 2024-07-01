
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory`



-  [Resource `ManagedFungibleAsset`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_ManagedFungibleAsset)
-  [Resource `CoinList`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_CoinList)
-  [Constants](#@Constants_0)
-  [Function `create_token`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_create_token)
-  [Function `assert_token_exists`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_assert_token_exists)
-  [Function `get_metadata_by_symbol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_metadata_by_symbol)
-  [Function `get_token_account_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_token_account_address)
-  [Function `mint`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_mint)
-  [Function `transfer_from`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_transfer_from)
-  [Function `burn`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_burn)
-  [Function `supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_supply)
-  [Function `maximum`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_maximum)
-  [Function `name`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_name)
-  [Function `symbol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_symbol)
-  [Function `decimals`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_decimals)
-  [Function `balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_balance_of)
-  [Function `token_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_token_address)


<pre><code><b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::token_base</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_ManagedFungibleAsset"></a>

## Resource `ManagedFungibleAsset`

Hold refs to control the minting, transfer and burning of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_ManagedFungibleAsset">ManagedFungibleAsset</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_CoinList"></a>

## Resource `CoinList`



<pre><code><b>struct</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_CoinList">CoinList</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_ENOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_ENOT_OWNER">ENOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_E_ACCOUNT_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_E_ACCOUNT_NOT_EXISTS">E_ACCOUNT_NOT_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_E_TOKEN_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_E_TOKEN_ALREADY_EXISTS">E_TOKEN_ALREADY_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_create_token"></a>

## Function `create_token`

Initialize metadata object and store the refs.


<pre><code><b>public</b> entry <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_create_token">create_token</a>(<a href="">signer</a>: &<a href="">signer</a>, maximum_supply: u128, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_assert_token_exists"></a>

## Function `assert_token_exists`



<pre><code><b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_assert_token_exists">assert_token_exists</a>(token_metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_metadata_by_symbol"></a>

## Function `get_metadata_by_symbol`

Return the address of the managed fungible asset that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_metadata_by_symbol">get_metadata_by_symbol</a>(symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_token_account_address"></a>

## Function `get_token_account_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_get_token_account_address">get_token_account_address</a>(): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_mint"></a>

## Function `mint`

Mint as the owner of metadata object.


<pre><code><b>public</b> entry <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_mint">mint</a>(admin: &<a href="">signer</a>, <b>to</b>: <b>address</b>, amount: u64, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_transfer_from"></a>

## Function `transfer_from`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_transfer_from">transfer_from</a>(from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_burn"></a>

## Function `burn`

Burn fungible assets as the owner of metadata object.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_burn">burn</a>(from: <b>address</b>, amount: u64, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_supply"></a>

## Function `supply`

Get the current supply from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_supply">supply</a>(metadata_address: <b>address</b>): <a href="_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_maximum"></a>

## Function `maximum`

Get the maximum supply from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_maximum">maximum</a>(metadata_address: <b>address</b>): <a href="_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_name"></a>

## Function `name`

Get the name of the fungible asset from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_name">name</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_symbol"></a>

## Function `symbol`

Get the symbol of the fungible asset from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_symbol">symbol</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_decimals"></a>

## Function `decimals`

Get the decimals from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_decimals">decimals</a>(metadata_address: <b>address</b>): u8
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_balance_of"></a>

## Function `balance_of`

Get the balance of a given store.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_balance_of">balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u64
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_token_address"></a>

## Function `token_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory_token_address">token_address</a>(symbol: <a href="_String">string::String</a>): <b>address</b>
</code></pre>
