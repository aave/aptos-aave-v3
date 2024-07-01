
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::ecosystem_reserve_v2`



-  [Resource `EcosystemReserveV2Data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EcosystemReserveV2Data)
-  [Struct `CreateStream`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CreateStream)
-  [Struct `WithdrawFromStream`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_WithdrawFromStream)
-  [Struct `CancelStream`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CancelStream)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_initialize)
-  [Function `ecosystem_reserve_v2_data_address`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_address)
-  [Function `ecosystem_reserve_v2_data_object`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_object)
-  [Function `delta_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_delta_of)
-  [Function `balance_of`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_balance_of)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="admin_controlled_ecosystem_reserve.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_admin_controlled_ecosystem_reserve">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::admin_controlled_ecosystem_reserve</a>;
<b>use</b> <a href="stream.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_stream">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::stream</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EcosystemReserveV2Data"></a>

## Resource `EcosystemReserveV2Data`



<pre><code><b>struct</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EcosystemReserveV2Data">EcosystemReserveV2Data</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CreateStream"></a>

## Struct `CreateStream`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CreateStream">CreateStream</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_WithdrawFromStream"></a>

## Struct `WithdrawFromStream`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_WithdrawFromStream">WithdrawFromStream</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CancelStream"></a>

## Struct `CancelStream`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_CancelStream">CancelStream</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EROLE_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EROLE_NOT_EXISTS">EROLE_NOT_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_TEST_FAILED"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_TEST_FAILED">TEST_FAILED</a>: u64 = 2;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_TEST_SUCCESS"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_TEST_SUCCESS">TEST_SUCCESS</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE">EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EAMOUNT_IS_ZERO"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EAMOUNT_IS_ZERO">EAMOUNT_IS_ZERO</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ECOSYSTEM_RESERVE_V2_NAME"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ECOSYSTEM_RESERVE_V2_NAME">ECOSYSTEM_RESERVE_V2_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [65, 65, 86, 69, 95, 69, 67, 79, 83, 89, 83, 84, 69, 77, 95, 82, 69, 83, 69, 82, 86, 69, 95, 86, 50];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_IS_ZERO"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_IS_ZERO">EDEPOSIT_IS_ZERO</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA">EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_SMALLER_THAN_TIME_DELTA"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EDEPOSIT_SMALLER_THAN_TIME_DELTA">EDEPOSIT_SMALLER_THAN_TIME_DELTA</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTART_TIME_BEFORE_BLOCK_TIMESTAMP"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTART_TIME_BEFORE_BLOCK_TIMESTAMP">ESTART_TIME_BEFORE_BLOCK_TIMESTAMP</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTOP_TIME_BEFORE_THE_START_TIME"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTOP_TIME_BEFORE_THE_START_TIME">ESTOP_TIME_BEFORE_THE_START_TIME</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_NOT_EXISTS">ESTREAM_NOT_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_TO_THE_CALLER"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_TO_THE_CALLER">ESTREAM_TO_THE_CALLER</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_TO_THE_CONTRACT_ITSELF"></a>



<pre><code><b>const</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ESTREAM_TO_THE_CONTRACT_ITSELF">ESTREAM_TO_THE_CONTRACT_ITSELF</a>: u64 = 1;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_initialize"></a>

## Function `initialize`



<pre><code><b>public</b> <b>fun</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_initialize">initialize</a>(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_address"></a>

## Function `ecosystem_reserve_v2_data_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_address">ecosystem_reserve_v2_data_address</a>(): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_object"></a>

## Function `ecosystem_reserve_v2_data_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_ecosystem_reserve_v2_data_object">ecosystem_reserve_v2_data_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_EcosystemReserveV2Data">ecosystem_reserve_v2::EcosystemReserveV2Data</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_delta_of"></a>

## Function `delta_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_delta_of">delta_of</a>(stream_id: u256): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_balance_of"></a>

## Function `balance_of`



<pre><code><b>public</b> <b>fun</b> <a href="ecosystem_reserve_v2.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_ecosystem_reserve_v2_balance_of">balance_of</a>(stream_id: u256, who: <b>address</b>): u256
</code></pre>
