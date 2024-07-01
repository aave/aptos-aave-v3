
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory`



-  [Struct `Initialized`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_Initialized)
-  [Struct `BalanceTransfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_BalanceTransfer)
-  [Constants](#@Constants_0)
-  [Function `create_token`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_create_token)
-  [Function `rescue_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_rescue_tokens)
-  [Function `mint`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint)
-  [Function `burn`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_burn)
-  [Function `mint_to_treasury`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint_to_treasury)
-  [Function `transfer_underlying_to`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_underlying_to)
-  [Function `transfer_on_liquidation`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_on_liquidation)
-  [Function `handle_repayment`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_handle_repayment)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_revision)
-  [Function `get_token_account_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_token_account_address)
-  [Function `get_metadata_by_symbol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_metadata_by_symbol)
-  [Function `token_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_token_address)
-  [Function `asset_metadata`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_asset_metadata)
-  [Function `get_reserve_treasury_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_reserve_treasury_address)
-  [Function `get_underlying_asset_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_underlying_asset_address)
-  [Function `get_previous_index`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_previous_index)
-  [Function `get_scaled_user_balance_and_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_scaled_user_balance_and_supply)
-  [Function `scale_balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_balance_of)
-  [Function `balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_balance_of)
-  [Function `scale_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_total_supply)
-  [Function `supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_supply)
-  [Function `maximum`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_maximum)
-  [Function `name`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_name)
-  [Function `symbol`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_symbol)
-  [Function `decimals`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_decimals)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::aptos_account</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::resource_account</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="token_base.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_token_base">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::token_base</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_Initialized"></a>

## Struct `Initialized`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_Initialized">Initialized</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_BalanceTransfer"></a>

## Struct `BalanceTransfer`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_BalanceTransfer">BalanceTransfer</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_ATOKEN_REVISION"></a>



<pre><code><b>const</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_ATOKEN_REVISION">ATOKEN_REVISION</a>: u256 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_E_NOT_A_TOKEN_ADMIN"></a>



<pre><code><b>const</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_E_NOT_A_TOKEN_ADMIN">E_NOT_A_TOKEN_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_create_token"></a>

## Function `create_token`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_create_token">create_token</a>(<a href="">signer</a>: &<a href="">signer</a>, name: <a href="_String">string::String</a>, symbol: <a href="_String">string::String</a>, decimals: u8, icon_uri: <a href="_String">string::String</a>, project_uri: <a href="_String">string::String</a>, underlying_asset: <b>address</b>, treasury: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_rescue_tokens"></a>

## Function `rescue_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_rescue_tokens">rescue_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, token: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint"></a>

## Function `mint`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint">mint</a>(caller: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_burn"></a>

## Function `burn`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_burn">burn</a>(from: <b>address</b>, receiver_of_underlying: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint_to_treasury"></a>

## Function `mint_to_treasury`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_mint_to_treasury">mint_to_treasury</a>(amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_underlying_to"></a>

## Function `transfer_underlying_to`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_underlying_to">transfer_underlying_to</a>(<b>to</b>: <b>address</b>, amount: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_on_liquidation"></a>

## Function `transfer_on_liquidation`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_transfer_on_liquidation">transfer_on_liquidation</a>(from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256, index: u256, metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_handle_repayment"></a>

## Function `handle_repayment`



<pre><code><b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_handle_repayment">handle_repayment</a>(_user: <b>address</b>, _onBehalfOf: <b>address</b>, _amount: u256, _metadata_address: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_revision"></a>

## Function `get_revision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_token_account_address"></a>

## Function `get_token_account_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_token_account_address">get_token_account_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_metadata_by_symbol"></a>

## Function `get_metadata_by_symbol`

Return the address of the managed fungible asset that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_metadata_by_symbol">get_metadata_by_symbol</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_token_address"></a>

## Function `token_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_token_address">token_address</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_asset_metadata"></a>

## Function `asset_metadata`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_asset_metadata">asset_metadata</a>(owner: <b>address</b>, symbol: <a href="_String">string::String</a>): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_reserve_treasury_address"></a>

## Function `get_reserve_treasury_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_reserve_treasury_address">get_reserve_treasury_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_underlying_asset_address"></a>

## Function `get_underlying_asset_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_underlying_asset_address">get_underlying_asset_address</a>(metadata_address: <b>address</b>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_previous_index"></a>

## Function `get_previous_index`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_previous_index">get_previous_index</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_scaled_user_balance_and_supply"></a>

## Function `get_scaled_user_balance_and_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_get_scaled_user_balance_and_supply">get_scaled_user_balance_and_supply</a>(owner: <b>address</b>, metadata_address: <b>address</b>): (u256, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_balance_of"></a>

## Function `scale_balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_balance_of">scale_balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_balance_of"></a>

## Function `balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_balance_of">balance_of</a>(owner: <b>address</b>, metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_total_supply"></a>

## Function `scale_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_scale_total_supply">scale_total_supply</a>(metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_supply"></a>

## Function `supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_supply">supply</a>(metadata_address: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_maximum"></a>

## Function `maximum`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_maximum">maximum</a>(metadata_address: <b>address</b>): <a href="_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_name"></a>

## Function `name`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_name">name</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_symbol"></a>

## Function `symbol`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_symbol">symbol</a>(metadata_address: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_decimals"></a>

## Function `decimals`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory_decimals">decimals</a>(metadata_address: <b>address</b>): u8
</code></pre>
