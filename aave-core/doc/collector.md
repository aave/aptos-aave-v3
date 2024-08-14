
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::collector`



-  [Resource `CollectorData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_CollectorData)
-  [Constants](#@Constants_0)
-  [Function `check_is_funds_admin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_check_is_funds_admin)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_revision)
-  [Function `collector_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_address)
-  [Function `collector_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_object)
-  [Function `deposit`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_deposit)
-  [Function `withdraw`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_withdraw)
-  [Function `get_collected_fees`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_collected_fees)


<pre><code><b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_CollectorData"></a>

## Resource `CollectorData`



<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_CollectorData">CollectorData</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_REVISION"></a>

Contract revision


<pre><code><b>const</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_REVISION">REVISION</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_COLLECTOR_NAME"></a>

Collector name


<pre><code><b>const</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_COLLECTOR_NAME">COLLECTOR_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [65, 65, 86, 69, 95, 67, 79, 76, 76, 69, 67, 84, 79, 82];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_ERR_NOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_ERR_NOT_OWNER">ERR_NOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_check_is_funds_admin"></a>

## Function `check_is_funds_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_check_is_funds_admin">check_is_funds_admin</a>(<a href="">account</a>: <b>address</b>): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_revision"></a>

## Function `get_revision`

Return the revision of the aave token implementation


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_revision">get_revision</a>(): u64
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_address"></a>

## Function `collector_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_address">collector_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_object"></a>

## Function `collector_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_collector_object">collector_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_CollectorData">collector::CollectorData</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_deposit"></a>

## Function `deposit`



<pre><code><b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_deposit">deposit</a>(sender: &<a href="">signer</a>, fa: <a href="_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_withdraw">withdraw</a>(sender: &<a href="">signer</a>, asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, receiver: <b>address</b>, amount: u64)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_collected_fees"></a>

## Function `get_collected_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="collector.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_collector_get_collected_fees">get_collected_fees</a>(asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;): u64
</code></pre>
