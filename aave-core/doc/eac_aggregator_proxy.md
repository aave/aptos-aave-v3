
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::eac_aggregator_proxy`



-  [Resource `MockEacAggregatorProxy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_MockEacAggregatorProxy)
-  [Struct `AnswerUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_AnswerUpdated)
-  [Struct `NewRound`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_NewRound)
-  [Function `decimals`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_decimals)
-  [Function `latest_answer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_latest_answer)
-  [Function `create_eac_aggregator_proxy`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_create_eac_aggregator_proxy)


<pre><code></code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_MockEacAggregatorProxy"></a>

## Resource `MockEacAggregatorProxy`



<pre><code><b>struct</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_MockEacAggregatorProxy">MockEacAggregatorProxy</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_AnswerUpdated"></a>

## Struct `AnswerUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_AnswerUpdated">AnswerUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_NewRound"></a>

## Struct `NewRound`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_NewRound">NewRound</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_decimals"></a>

## Function `decimals`



<pre><code><b>public</b> <b>fun</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_decimals">decimals</a>(): u8
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_latest_answer"></a>

## Function `latest_answer`



<pre><code><b>public</b> <b>fun</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_latest_answer">latest_answer</a>(): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_create_eac_aggregator_proxy"></a>

## Function `create_eac_aggregator_proxy`



<pre><code><b>public</b> <b>fun</b> <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_create_eac_aggregator_proxy">create_eac_aggregator_proxy</a>(): <a href="eac_aggregator_proxy.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_eac_aggregator_proxy_MockEacAggregatorProxy">eac_aggregator_proxy::MockEacAggregatorProxy</a>
</code></pre>
