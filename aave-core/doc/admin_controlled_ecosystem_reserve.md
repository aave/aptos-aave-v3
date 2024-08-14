
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::admin_controlled_ecosystem_reserve`



-  [Struct `NewFundsAdmin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_NewFundsAdmin)
-  [Resource `AdminControlledEcosystemReserveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_initialize)
-  [Function `check_is_funds_admin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_check_is_funds_admin)
-  [Function `get_revision`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_revision)
-  [Function `get_funds_admin`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_funds_admin)
-  [Function `admin_controlled_ecosystem_reserve_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address)
-  [Function `admin_controlled_ecosystem_reserve_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object)
-  [Function `transfer_out`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_transfer_out)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::fungible_asset</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::primary_fungible_store</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_NewFundsAdmin"></a>

## Struct `NewFundsAdmin`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_NewFundsAdmin">NewFundsAdmin</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData"></a>

## Resource `AdminControlledEcosystemReserveData`



<pre><code><b>struct</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData">AdminControlledEcosystemReserveData</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE">ADMIN_CONTROLLED_ECOSYSTEM_RESERVE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 68, 77, 73, 78, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 68, 95, 69, 67, 79, 83, 89, 83, 84, 69, 77, 95, 82, 69, 83, 69, 82, 86, 69];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_ONLY_BY_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_ONLY_BY_FUNDS_ADMIN">ONLY_BY_FUNDS_ADMIN</a>: u64 = 3;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_REVISION"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_REVISION">REVISION</a>: u256 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_TEST_FAILED"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_TEST_FAILED">TEST_FAILED</a>: u64 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_TEST_SUCCESS"></a>



<pre><code><b>const</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_TEST_SUCCESS">TEST_SUCCESS</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_initialize"></a>

## Function `initialize`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_initialize">initialize</a>(sender: &<a href="">signer</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_check_is_funds_admin"></a>

## Function `check_is_funds_admin`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_check_is_funds_admin">check_is_funds_admin</a>(<a href="">account</a>: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_revision"></a>

## Function `get_revision`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_revision">get_revision</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_funds_admin"></a>

## Function `get_funds_admin`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_get_funds_admin">get_funds_admin</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address"></a>

## Function `admin_controlled_ecosystem_reserve_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_address">admin_controlled_ecosystem_reserve_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object"></a>

## Function `admin_controlled_ecosystem_reserve_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_admin_controlled_ecosystem_reserve_object">admin_controlled_ecosystem_reserve_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_AdminControlledEcosystemReserveData">admin_controlled_ecosystem_reserve::AdminControlledEcosystemReserveData</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_transfer_out"></a>

## Function `transfer_out`



<pre><code><b>public</b> <b>fun</b> <a href="admin_controlled_ecosystem_reserve.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_admin_controlled_ecosystem_reserve_transfer_out">transfer_out</a>(sender: &<a href="">signer</a>, asset_metadata: <a href="_Object">object::Object</a>&lt;<a href="_Metadata">fungible_asset::Metadata</a>&gt;, receiver: <b>address</b>, amount: u64)
</code></pre>
