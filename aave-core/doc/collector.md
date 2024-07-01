
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::collector`



-  [Resource `CollectorData`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_CollectorData)
-  [Constants](#@Constants_0)
-  [Function `check_is_funds_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_check_is_funds_admin)
-  [Function `get_revision`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_revision)
-  [Function `collector_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_address)
-  [Function `collector_object`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_object)
-  [Function `deposit`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_deposit)
-  [Function `withdraw`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_withdraw)
-  [Function `get_collected_fees`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_collected_fees)


<pre><code><b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_CollectorData"></a>

## Resource `CollectorData`



<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_CollectorData">CollectorData</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_REVISION"></a>

Contract revision


<pre><code><b>const</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_REVISION">REVISION</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_COLLECTOR_NAME"></a>

Collector name


<pre><code><b>const</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_COLLECTOR_NAME">COLLECTOR_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [65, 65, 86, 69, 95, 67, 79, 76, 76, 69, 67, 84, 79, 82];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_ERR_NOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_ERR_NOT_OWNER">ERR_NOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_check_is_funds_admin"></a>

## Function `check_is_funds_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_check_is_funds_admin">check_is_funds_admin</a>(<a href="">account</a>: <b>address</b>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_revision"></a>

## Function `get_revision`

Return the revision of the aave token implementation


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_revision">get_revision</a>(): u64
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_address"></a>

## Function `collector_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_address">collector_address</a>(): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_object"></a>

## Function `collector_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_collector_object">collector_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_CollectorData">collector::CollectorData</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_deposit"></a>

## Function `deposit`



<pre><code><b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_deposit">deposit</a>(sender: &<a href="">signer</a>, fa: <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_withdraw">withdraw</a>(sender: &<a href="">signer</a>, asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, receiver: <b>address</b>, amount: u64)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_collected_fees"></a>

## Function `get_collected_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_collector_get_collected_fees">get_collected_fees</a>(asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): u64
</code></pre>
