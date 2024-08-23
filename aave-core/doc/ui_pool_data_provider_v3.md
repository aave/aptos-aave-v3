
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::ui_pool_data_provider_v3`



-  [Resource `UiPoolDataProviderV3Data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UiPoolDataProviderV3Data)
-  [Resource `AggregatedReserveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_AggregatedReserveData)
-  [Resource `UserReserveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UserReserveData)
-  [Resource `BaseCurrencyInfo`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_BaseCurrencyInfo)
-  [Constants](#@Constants_0)
-  [Function `ui_pool_data_provider_v3_data_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_address)
-  [Function `ui_pool_data_provider_v3_data_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_object)
-  [Function `get_reserves_list`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_list)
-  [Function `get_reserves_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_data)
-  [Function `get_user_reserves_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_user_reserves_data)


<pre><code><b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="default_reserve_interest_rate_strategy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_default_reserve_interest_rate_strategy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::default_reserve_interest_rate_strategy</a>;
<b>use</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::eac_aggregator_proxy</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="token_base.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_token_base">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::token_base</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UiPoolDataProviderV3Data"></a>

## Resource `UiPoolDataProviderV3Data`



<pre><code><b>struct</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UiPoolDataProviderV3Data">UiPoolDataProviderV3Data</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_AggregatedReserveData"></a>

## Resource `AggregatedReserveData`



<pre><code><b>struct</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_AggregatedReserveData">AggregatedReserveData</a> <b>has</b> drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UserReserveData"></a>

## Resource `UserReserveData`



<pre><code><b>struct</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UserReserveData">UserReserveData</a> <b>has</b> drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_BaseCurrencyInfo"></a>

## Resource `BaseCurrencyInfo`



<pre><code><b>struct</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_BaseCurrencyInfo">BaseCurrencyInfo</a> <b>has</b> drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EROLE_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EROLE_NOT_EXISTS">EROLE_NOT_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_NOT_FUNDS_ADMIN"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_NOT_FUNDS_ADMIN">NOT_FUNDS_ADMIN</a>: u64 = 3;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE">EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE</a>: u64 = 12;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EAMOUNT_IS_ZERO"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EAMOUNT_IS_ZERO">EAMOUNT_IS_ZERO</a>: u64 = 11;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_IS_ZERO"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_IS_ZERO">EDEPOSIT_IS_ZERO</a>: u64 = 6;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA">EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA</a>: u64 = 10;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_SMALLER_THAN_TIME_DELTA"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EDEPOSIT_SMALLER_THAN_TIME_DELTA">EDEPOSIT_SMALLER_THAN_TIME_DELTA</a>: u64 = 9;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTART_TIME_BEFORE_BLOCK_TIMESTAMP"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTART_TIME_BEFORE_BLOCK_TIMESTAMP">ESTART_TIME_BEFORE_BLOCK_TIMESTAMP</a>: u64 = 7;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTOP_TIME_BEFORE_THE_START_TIME"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTOP_TIME_BEFORE_THE_START_TIME">ESTOP_TIME_BEFORE_THE_START_TIME</a>: u64 = 8;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_NOT_EXISTS">ESTREAM_NOT_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_TO_THE_CALLER"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_TO_THE_CALLER">ESTREAM_TO_THE_CALLER</a>: u64 = 5;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_TO_THE_CONTRACT_ITSELF"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ESTREAM_TO_THE_CONTRACT_ITSELF">ESTREAM_TO_THE_CONTRACT_ITSELF</a>: u64 = 4;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EMPTY_ADDRESS"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_EMPTY_ADDRESS">EMPTY_ADDRESS</a>: <b>address</b> = 0x0;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ETH_CURRENCY_UNIT"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ETH_CURRENCY_UNIT">ETH_CURRENCY_UNIT</a>: u256 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UI_POOL_DATA_PROVIDER_V3_NAME"></a>



<pre><code><b>const</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UI_POOL_DATA_PROVIDER_V3_NAME">UI_POOL_DATA_PROVIDER_V3_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [65, 65, 86, 69, 95, 85, 73, 95, 80, 79, 79, 76, 95, 68, 65, 84, 65, 95, 80, 82, 79, 86, 73, 68, 69, 82, 95, 86, 51];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_address"></a>

## Function `ui_pool_data_provider_v3_data_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_address">ui_pool_data_provider_v3_data_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_object"></a>

## Function `ui_pool_data_provider_v3_data_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_ui_pool_data_provider_v3_data_object">ui_pool_data_provider_v3_data_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UiPoolDataProviderV3Data">ui_pool_data_provider_v3::UiPoolDataProviderV3Data</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_list"></a>

## Function `get_reserves_list`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_list">get_reserves_list</a>(): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_data"></a>

## Function `get_reserves_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_reserves_data">get_reserves_data</a>(): (<a href="">vector</a>&lt;<a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_AggregatedReserveData">ui_pool_data_provider_v3::AggregatedReserveData</a>&gt;, <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_BaseCurrencyInfo">ui_pool_data_provider_v3::BaseCurrencyInfo</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_user_reserves_data"></a>

## Function `get_user_reserves_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_get_user_reserves_data">get_user_reserves_data</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): (<a href="">vector</a>&lt;<a href="ui_pool_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_pool_data_provider_v3_UserReserveData">ui_pool_data_provider_v3::UserReserveData</a>&gt;, u8)
</code></pre>
