
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::standard_token`



-  [Resource `ManagingRefs`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ManagingRefs)
-  [Struct `AaveTokenInitialized`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_AaveTokenInitialized)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_initialize)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_get_revision)
-  [Function `mint_to_primary_stores`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint_to_primary_stores)
-  [Function `mint`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint)
-  [Function `transfer_between_primary_stores`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer_between_primary_stores)
-  [Function `transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer)
-  [Function `burn_from_primary_stores`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn_from_primary_stores)
-  [Function `burn`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn)
-  [Function `set_primary_stores_frozen_status`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_primary_stores_frozen_status)
-  [Function `set_frozen_status`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_frozen_status)
-  [Function `withdraw_from_primary_stores`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw_from_primary_stores)
-  [Function `withdraw`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw)
-  [Function `deposit_to_primary_stores`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit_to_primary_stores)
-  [Function `deposit`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit)


<pre><code><b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ManagingRefs"></a>

## Resource `ManagingRefs`

Hold refs to control the minting, transfer and burning of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ManagingRefs">ManagingRefs</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_AaveTokenInitialized"></a>

## Struct `AaveTokenInitialized`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_AaveTokenInitialized">AaveTokenInitialized</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_E_NOT_A_TOKEN_ADMIN"></a>



<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_E_NOT_A_TOKEN_ADMIN">E_NOT_A_TOKEN_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_REVISION"></a>



<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_REVISION">REVISION</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_NOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_NOT_OWNER">ERR_NOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_BURN_REF"></a>

BurnRef error.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_BURN_REF">ERR_BURN_REF</a>: u64 = 6;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_INVALID_REF_FLAGS_LENGTH"></a>

The length of ref_flags is not 3.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_INVALID_REF_FLAGS_LENGTH">ERR_INVALID_REF_FLAGS_LENGTH</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_MINT_REF"></a>

MintRef error.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_MINT_REF">ERR_MINT_REF</a>: u64 = 4;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_TRANSFER_REF"></a>

TransferRef error.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_TRANSFER_REF">ERR_TRANSFER_REF</a>: u64 = 5;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_VECTORS_LENGTH_MISMATCH"></a>

The lengths of two vector do not equal.


<pre><code><b>const</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_ERR_VECTORS_LENGTH_MISMATCH">ERR_VECTORS_LENGTH_MISMATCH</a>: u64 = 3;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_initialize"></a>

## Function `initialize`

Initialize metadata object and store the refs specified by <code>ref_flags</code>.


<pre><code><b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_initialize">initialize</a>(creator: &<a href="">signer</a>, maximum_supply: u128, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, ref_flags: <a href="">vector</a>&lt;bool&gt;, underlying_asset_address: <b>address</b>, is_coin_underlying: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_get_revision"></a>

## Function `get_revision`

Return the revision of the aave token implementation


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_get_revision">get_revision</a>(): u64
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint_to_primary_stores"></a>

## Function `mint_to_primary_stores`

Mint as the owner of metadata object to the primary fungible stores of the accounts with amounts of FAs.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint_to_primary_stores">mint_to_primary_stores</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, <b>to</b>: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint"></a>

## Function `mint`

Mint as the owner of metadata object to multiple fungible stores with amounts of FAs.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_mint">mint</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer_between_primary_stores"></a>

## Function `transfer_between_primary_stores`

Transfer as the owner of metadata object ignoring <code>frozen</code> field from primary stores to primary stores of
accounts.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer_between_primary_stores">transfer_between_primary_stores</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, from: <a href="">vector</a>&lt;<b>address</b>&gt;, <b>to</b>: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer"></a>

## Function `transfer`

Transfer as the owner of metadata object ignoring <code>frozen</code> field between fungible stores.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_transfer">transfer</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, sender_stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, receiver_stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn_from_primary_stores"></a>

## Function `burn_from_primary_stores`

Burn fungible assets as the owner of metadata object from the primary stores of accounts.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn_from_primary_stores">burn_from_primary_stores</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, from: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn"></a>

## Function `burn`

Burn fungible assets as the owner of metadata object from fungible stores.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_burn">burn</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_primary_stores_frozen_status"></a>

## Function `set_primary_stores_frozen_status`

Freeze/unfreeze the primary stores of accounts so they cannot transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_primary_stores_frozen_status">set_primary_stores_frozen_status</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, accounts: <a href="">vector</a>&lt;<b>address</b>&gt;, frozen: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_frozen_status"></a>

## Function `set_frozen_status`

Freeze/unfreeze the fungible stores so they cannot transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_set_frozen_status">set_frozen_status</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, frozen: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw_from_primary_stores"></a>

## Function `withdraw_from_primary_stores`

Withdraw as the owner of metadata object ignoring <code>frozen</code> field from primary fungible stores of accounts.


<pre><code><b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw_from_primary_stores">withdraw_from_primary_stores</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, from: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u64&gt;): <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw"></a>

## Function `withdraw`

Withdraw as the owner of metadata object ignoring <code>frozen</code> field from fungible stores.
return a fungible asset <code>fa</code> where <code>fa.amount = sum(amounts)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_withdraw">withdraw</a>(admin: &<a href="">signer</a>, asset: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, amounts: <a href="">vector</a>&lt;u64&gt;): <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit_to_primary_stores"></a>

## Function `deposit_to_primary_stores`

Deposit as the owner of metadata object ignoring <code>frozen</code> field to primary fungible stores of accounts from a
single source of fungible asset.


<pre><code><b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit_to_primary_stores">deposit_to_primary_stores</a>(admin: &<a href="">signer</a>, fa: &<b>mut</b> <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>, from: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit"></a>

## Function `deposit`

Deposit as the owner of metadata object ignoring <code>frozen</code> field from fungible stores. The amount left in <code>fa</code>
is <code>fa.amount - sum(amounts)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="standard_token.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_standard_token_deposit">deposit</a>(admin: &<a href="">signer</a>, fa: &<b>mut</b> <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>, stores: <a href="">vector</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_FungibleStore">fungible_asset::FungibleStore</a>&gt;&gt;, amounts: <a href="">vector</a>&lt;u64&gt;)
</code></pre>
