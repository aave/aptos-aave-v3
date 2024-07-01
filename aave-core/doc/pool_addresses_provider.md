
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_addresses_provider`



-  [Struct `MarketIdSet`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_MarketIdSet)
-  [Struct `PoolUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolUpdated)
-  [Struct `PoolConfiguratorUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolConfiguratorUpdated)
-  [Struct `PriceOracleUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleUpdated)
-  [Struct `ACLManagerUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLManagerUpdated)
-  [Struct `ACLAdminUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLAdminUpdated)
-  [Struct `PriceOracleSentinelUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleSentinelUpdated)
-  [Struct `PoolDataProviderUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolDataProviderUpdated)
-  [Resource `Provider`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_Provider)
-  [Constants](#@Constants_0)
-  [Function `has_id_mapped_account`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_has_id_mapped_account)
-  [Function `get_market_id`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_market_id)
-  [Function `set_market_id`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_market_id)
-  [Function `get_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_address)
-  [Function `set_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_address)
-  [Function `get_pool`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool)
-  [Function `set_pool_impl`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_impl)
-  [Function `get_pool_configurator`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_configurator)
-  [Function `set_pool_configurator`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_configurator)
-  [Function `get_price_oracle`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle)
-  [Function `set_price_oracle`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle)
-  [Function `get_acl_manager`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_manager)
-  [Function `set_acl_manager`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_manager)
-  [Function `get_acl_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_admin)
-  [Function `set_acl_admin`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_admin)
-  [Function `get_price_oracle_sentinel`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle_sentinel)
-  [Function `set_price_oracle_sentinel`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle_sentinel)
-  [Function `get_pool_data_provider`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_data_provider)
-  [Function `set_pool_data_provider`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_data_provider)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_MarketIdSet"></a>

## Struct `MarketIdSet`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_MarketIdSet">MarketIdSet</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolUpdated"></a>

## Struct `PoolUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolUpdated">PoolUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolConfiguratorUpdated"></a>

## Struct `PoolConfiguratorUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolConfiguratorUpdated">PoolConfiguratorUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleUpdated"></a>

## Struct `PriceOracleUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleUpdated">PriceOracleUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLManagerUpdated"></a>

## Struct `ACLManagerUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLManagerUpdated">ACLManagerUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLAdminUpdated"></a>

## Struct `ACLAdminUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACLAdminUpdated">ACLAdminUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleSentinelUpdated"></a>

## Struct `PriceOracleSentinelUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PriceOracleSentinelUpdated">PriceOracleSentinelUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolDataProviderUpdated"></a>

## Struct `PoolDataProviderUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PoolDataProviderUpdated">PoolDataProviderUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_Provider"></a>

## Resource `Provider`



<pre><code><b>struct</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_Provider">Provider</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ENOT_MANAGEMENT"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ENOT_MANAGEMENT">ENOT_MANAGEMENT</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACL_ADMIN"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACL_ADMIN">ACL_ADMIN</a>: <a href="">vector</a>&lt;u8&gt; = [65, 67, 76, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACL_MANAGER"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_ACL_MANAGER">ACL_MANAGER</a>: <a href="">vector</a>&lt;u8&gt; = [65, 67, 76, 95, 77, 65, 78, 65, 71, 69, 82];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_DATA_PROVIDER"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_DATA_PROVIDER">DATA_PROVIDER</a>: <a href="">vector</a>&lt;u8&gt; = [68, 65, 84, 65, 95, 80, 82, 79, 86, 73, 68, 69, 82];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_EID_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_EID_ALREADY_EXISTS">EID_ALREADY_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_EID_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_EID_NOT_EXISTS">EID_NOT_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_POOL"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_POOL">POOL</a>: <a href="">vector</a>&lt;u8&gt; = [80, 79, 79, 76];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_POOL_CONFIGURATOR"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_POOL_CONFIGURATOR">POOL_CONFIGURATOR</a>: <a href="">vector</a>&lt;u8&gt; = [80, 79, 79, 76, 95, 67, 79, 78, 70, 73, 71, 85, 82, 65, 84, 79, 82];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PRICE_ORACLE"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PRICE_ORACLE">PRICE_ORACLE</a>: <a href="">vector</a>&lt;u8&gt; = [80, 82, 73, 67, 69, 95, 79, 82, 65, 67, 76, 69];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PRICE_ORACLE_SENTINEL"></a>



<pre><code><b>const</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_PRICE_ORACLE_SENTINEL">PRICE_ORACLE_SENTINEL</a>: <a href="">vector</a>&lt;u8&gt; = [80, 82, 73, 67, 69, 95, 79, 82, 65, 67, 76, 69, 95, 83, 69, 78, 84, 73, 78, 69, 76];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_has_id_mapped_account"></a>

## Function `has_id_mapped_account`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_has_id_mapped_account">has_id_mapped_account</a>(id: <a href="_String">string::String</a>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_market_id"></a>

## Function `get_market_id`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_market_id">get_market_id</a>(): <a href="_Option">option::Option</a>&lt;<a href="_String">string::String</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_market_id"></a>

## Function `set_market_id`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_market_id">set_market_id</a>(<a href="">account</a>: &<a href="">signer</a>, new_market_id: <a href="_String">string::String</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_address"></a>

## Function `get_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_address">get_address</a>(id: <a href="_String">string::String</a>): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_address"></a>

## Function `set_address`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_address">set_address</a>(<a href="">account</a>: &<a href="">signer</a>, id: <a href="_String">string::String</a>, addr: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool"></a>

## Function `get_pool`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool">get_pool</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_impl"></a>

## Function `set_pool_impl`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_impl">set_pool_impl</a>(<a href="">account</a>: &<a href="">signer</a>, new_pool_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_configurator"></a>

## Function `get_pool_configurator`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_configurator">get_pool_configurator</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_configurator"></a>

## Function `set_pool_configurator`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_configurator">set_pool_configurator</a>(<a href="">account</a>: &<a href="">signer</a>, new_pool_configurator_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle"></a>

## Function `get_price_oracle`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle">get_price_oracle</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle"></a>

## Function `set_price_oracle`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle">set_price_oracle</a>(<a href="">account</a>: &<a href="">signer</a>, new_price_oracle_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_manager"></a>

## Function `get_acl_manager`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_manager">get_acl_manager</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_manager"></a>

## Function `set_acl_manager`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_manager">set_acl_manager</a>(<a href="">account</a>: &<a href="">signer</a>, new_acl_manager_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_admin"></a>

## Function `get_acl_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_acl_admin">get_acl_admin</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_admin"></a>

## Function `set_acl_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_acl_admin">set_acl_admin</a>(<a href="">account</a>: &<a href="">signer</a>, new_acl_admin_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle_sentinel"></a>

## Function `get_price_oracle_sentinel`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_price_oracle_sentinel">get_price_oracle_sentinel</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle_sentinel"></a>

## Function `set_price_oracle_sentinel`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_price_oracle_sentinel">set_price_oracle_sentinel</a>(<a href="">account</a>: &<a href="">signer</a>, new_price_oracle_sentinel_impl: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_data_provider"></a>

## Function `get_pool_data_provider`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_get_pool_data_provider">get_pool_data_provider</a>(): <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_data_provider"></a>

## Function `set_pool_data_provider`



<pre><code><b>public</b> entry <b>fun</b> <a href="pool_addresses_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_addresses_provider_set_pool_data_provider">set_pool_data_provider</a>(<a href="">account</a>: &<a href="">signer</a>, new_pool_data_provider_impl: <b>address</b>)
</code></pre>
