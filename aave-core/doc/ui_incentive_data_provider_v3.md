
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::ui_incentive_data_provider_v3`



-  [Resource `UiIncentiveDataProviderV3Data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UiIncentiveDataProviderV3Data)
-  [Struct `AggregatedReserveIncentiveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_AggregatedReserveIncentiveData)
-  [Struct `IncentiveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_IncentiveData)
-  [Struct `RewardInfo`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_RewardInfo)
-  [Struct `UserReserveIncentiveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserReserveIncentiveData)
-  [Struct `UserIncentiveData`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserIncentiveData)
-  [Struct `UserRewardInfo`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserRewardInfo)
-  [Constants](#@Constants_0)
-  [Function `ui_incentive_data_provider_v3_data_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_address)
-  [Function `ui_incentive_data_provider_v3_data_object`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_object)
-  [Function `get_full_reserves_incentive_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_full_reserves_incentive_data)
-  [Function `get_reserves_incentives_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_reserves_incentives_data)
-  [Function `get_user_reserves_incentives_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_user_reserves_incentives_data)


<pre><code><b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::eac_aggregator_proxy</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="rewards_controller.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_rewards_controller">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::rewards_controller</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UiIncentiveDataProviderV3Data"></a>

## Resource `UiIncentiveDataProviderV3Data`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UiIncentiveDataProviderV3Data">UiIncentiveDataProviderV3Data</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_AggregatedReserveIncentiveData"></a>

## Struct `AggregatedReserveIncentiveData`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_AggregatedReserveIncentiveData">AggregatedReserveIncentiveData</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_IncentiveData"></a>

## Struct `IncentiveData`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_IncentiveData">IncentiveData</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_RewardInfo"></a>

## Struct `RewardInfo`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_RewardInfo">RewardInfo</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserReserveIncentiveData"></a>

## Struct `UserReserveIncentiveData`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserReserveIncentiveData">UserReserveIncentiveData</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserIncentiveData"></a>

## Struct `UserIncentiveData`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserIncentiveData">UserIncentiveData</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserRewardInfo"></a>

## Struct `UserRewardInfo`



<pre><code><b>struct</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserRewardInfo">UserRewardInfo</a> <b>has</b> drop, store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_EMPTY_ADDRESS"></a>



<pre><code><b>const</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_EMPTY_ADDRESS">EMPTY_ADDRESS</a>: <b>address</b> = 0x0;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UI_INCENTIVE_DATA_PROVIDER_V3_NAME"></a>



<pre><code><b>const</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UI_INCENTIVE_DATA_PROVIDER_V3_NAME">UI_INCENTIVE_DATA_PROVIDER_V3_NAME</a>: <a href="">vector</a>&lt;u8&gt; = [65, 65, 86, 69, 95, 85, 73, 95, 73, 78, 67, 69, 78, 84, 73, 86, 69, 95, 68, 65, 84, 65, 95, 80, 82, 79, 86, 73, 68, 69, 82, 95, 86, 51];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_address"></a>

## Function `ui_incentive_data_provider_v3_data_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_address">ui_incentive_data_provider_v3_data_address</a>(): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_object"></a>

## Function `ui_incentive_data_provider_v3_data_object`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_ui_incentive_data_provider_v3_data_object">ui_incentive_data_provider_v3_data_object</a>(): <a href="_Object">object::Object</a>&lt;<a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UiIncentiveDataProviderV3Data">ui_incentive_data_provider_v3::UiIncentiveDataProviderV3Data</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_full_reserves_incentive_data"></a>

## Function `get_full_reserves_incentive_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_full_reserves_incentive_data">get_full_reserves_incentive_data</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): (<a href="">vector</a>&lt;<a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_AggregatedReserveIncentiveData">ui_incentive_data_provider_v3::AggregatedReserveIncentiveData</a>&gt;, <a href="">vector</a>&lt;<a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserReserveIncentiveData">ui_incentive_data_provider_v3::UserReserveIncentiveData</a>&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_reserves_incentives_data"></a>

## Function `get_reserves_incentives_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_reserves_incentives_data">get_reserves_incentives_data</a>(): <a href="">vector</a>&lt;<a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_AggregatedReserveIncentiveData">ui_incentive_data_provider_v3::AggregatedReserveIncentiveData</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_user_reserves_incentives_data"></a>

## Function `get_user_reserves_incentives_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_get_user_reserves_incentives_data">get_user_reserves_incentives_data</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): <a href="">vector</a>&lt;<a href="ui_incentive_data_provider_v3.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_ui_incentive_data_provider_v3_UserReserveIncentiveData">ui_incentive_data_provider_v3::UserReserveIncentiveData</a>&gt;
</code></pre>
