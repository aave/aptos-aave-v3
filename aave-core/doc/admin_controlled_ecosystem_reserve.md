
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::admin_controlled_ecosystem_reserve`



-  [Struct `NewFundsAdmin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_NewFundsAdmin)
-  [Resource `AdminControlledEcosystemReserveData`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_initialize)
-  [Function `check_is_funds_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_check_is_funds_admin)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_revision)
-  [Function `get_funds_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_funds_admin)
-  [Function `admin_controlled_ecosystem_reserve_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address)
-  [Function `admin_controlled_ecosystem_reserve_object`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object)
-  [Function `transfer_out`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_transfer_out)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_NewFundsAdmin"></a>

## Struct `NewFundsAdmin`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_NewFundsAdmin">NewFundsAdmin</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData"></a>

## Resource `AdminControlledEcosystemReserveData`



<pre><code><b>struct</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData">AdminControlledEcosystemReserveData</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE">ADMIN_CONTROLLED_ECOSYSTEM_RESERVE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 68, 77, 73, 78, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 68, 95, 69, 67, 79, 83, 89, 83, 84, 69, 77, 95, 82, 69, 83, 69, 82, 86, 69];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_ONLY_BY_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_ONLY_BY_FUNDS_ADMIN">ONLY_BY_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_REVISION"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_REVISION">REVISION</a>: u256 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_TEST_FAILED"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_TEST_FAILED">TEST_FAILED</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_TEST_SUCCESS"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_TEST_SUCCESS">TEST_SUCCESS</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_initialize"></a>

## Function `initialize`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_initialize">initialize</a>(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_check_is_funds_admin"></a>

## Function `check_is_funds_admin`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_check_is_funds_admin">check_is_funds_admin</a>(<a href="">account</a>: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_revision"></a>

## Function `get_revision`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_funds_admin"></a>

## Function `get_funds_admin`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_get_funds_admin">get_funds_admin</a>(): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address"></a>

## Function `admin_controlled_ecosystem_reserve_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address">admin_controlled_ecosystem_reserve_address</a>(): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object"></a>

## Function `admin_controlled_ecosystem_reserve_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object">admin_controlled_ecosystem_reserve_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData">admin_controlled_ecosystem_reserve::AdminControlledEcosystemReserveData</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_transfer_out"></a>

## Function `transfer_out`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve_transfer_out">transfer_out</a>(sender: &<a href="">signer</a>, asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, receiver: <b>address</b>, amount: u64)
</code></pre>
