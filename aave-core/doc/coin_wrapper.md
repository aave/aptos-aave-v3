
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::coin_wrapper`



-  [Struct `FungibleAssetData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_FungibleAssetData)
-  [Resource `WrapperAccount`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_WrapperAccount)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_initialize)
-  [Function `is_initialized`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_initialized)
-  [Function `wrapper_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrapper_address)
-  [Function `is_supported`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_supported)
-  [Function `is_wrapper`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_wrapper)
-  [Function `get_coin_type`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_coin_type)
-  [Function `get_wrapper`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_wrapper)
-  [Function `get_original`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_original)
-  [Function `format_fungible_asset`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_format_fungible_asset)
-  [Function `wrap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrap)
-  [Function `unwrap`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_unwrap)
-  [Function `create_fungible_asset`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_create_fungible_asset)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::aptos_account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::string_utils</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::package_manager</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_FungibleAssetData"></a>

## Struct `FungibleAssetData`

Stores the refs for a specific fungible asset wrapper for wrapping and unwrapping.


<pre><code><b>struct</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_FungibleAssetData">FungibleAssetData</a> <b>has</b> store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_WrapperAccount"></a>

## Resource `WrapperAccount`

The resource stored in the main resource account to track all the fungible asset wrappers.
This main resource account will also be the one holding all the deposited coins, each of which in a separate
CoinStore<CoinType> resource. See coin_wrapper.move in the Aptos Framework for more details.


<pre><code><b>struct</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_WrapperAccount">WrapperAccount</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_COIN_WRAPPER_NAME"></a>



<pre><code><b>const</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_COIN_WRAPPER_NAME">COIN_WRAPPER_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [67, 79, 73, 78, 95, 87, 82, 65, 80, 80, 69, 82];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_initialize"></a>

## Function `initialize`

Create the coin wrapper account to host all the deposited coins.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_initialize">initialize</a>()
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_initialized"></a>

## Function `is_initialized`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_initialized">is_initialized</a>(): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrapper_address"></a>

## Function `wrapper_address`

Return the address of the resource account that stores all deposited coins.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrapper_address">wrapper_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_supported"></a>

## Function `is_supported`

Return whether a specific CoinType has a wrapper fungible asset. This is only the case if at least one wrap()
call has been made for that CoinType.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_supported">is_supported</a>&lt;CoinType&gt;(): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_wrapper"></a>

## Function `is_wrapper`

Return true if the given fungible asset is a wrapper fungible asset.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_is_wrapper">is_wrapper</a>(metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_coin_type"></a>

## Function `get_coin_type`

Return the original CoinType for a specific wrapper fungible asset. This errors out if there's no such wrapper.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_coin_type">get_coin_type</a>(metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_wrapper"></a>

## Function `get_wrapper`

Return the wrapper fungible asset for a specific CoinType. This errors out if there's no such wrapper.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_wrapper">get_wrapper</a>&lt;CoinType&gt;(): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_original"></a>

## Function `get_original`

Return the original CoinType if the given fungible asset is a wrapper fungible asset. Otherwise, return the
given fungible asset itself, which means it's a native fungible asset (not wrapped).
The return value is a String such as "0x1::aptos_coin::AptosCoin" for an original coin or "0x12345" for a native
fungible asset.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_get_original">get_original</a>(<a href="">fungible_asset</a>: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_format_fungible_asset"></a>

## Function `format_fungible_asset`

Return the address string of a fungible asset (e.g. "0x1234").


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_format_fungible_asset">format_fungible_asset</a>(<a href="">fungible_asset</a>: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrap"></a>

## Function `wrap`

Wrap the given coins into fungible asset. This will also create the fungible asset wrapper if it doesn't exist
yet. The coins will be deposited into the main resource account.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_wrap">wrap</a>&lt;CoinType&gt;(coins: <a href="_Coin">coin::Coin</a>&lt;CoinType&gt;): <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_unwrap"></a>

## Function `unwrap`

Unwrap the given fungible asset into coins. This will burn the fungible asset and withdraw&return the coins from
the main resource account.
This errors out if the given fungible asset is not a wrapper fungible asset.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_unwrap">unwrap</a>&lt;CoinType&gt;(fa: <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>): <a href="_Coin">coin::Coin</a>&lt;CoinType&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_create_fungible_asset"></a>

## Function `create_fungible_asset`

Create the fungible asset wrapper for the given CoinType if it doesn't exist yet.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_wrapper.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_coin_wrapper_create_fungible_asset">create_fungible_asset</a>&lt;CoinType&gt;(): <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>
