
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::stream`



-  [Resource `Stream`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream)
-  [Constants](#@Constants_0)
-  [Function `recipient`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_recipient)
-  [Function `is_entity`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_is_entity)
-  [Function `get_stream`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_get_stream)
-  [Function `set_remaining_balance`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_set_remaining_balance)
-  [Function `create_stream`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_create_stream)


<pre><code></code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream"></a>

## Resource `Stream`



<pre><code><b>struct</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">Stream</a> <b>has</b> drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_TEST_FAILED"></a>



<pre><code><b>const</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_TEST_FAILED">TEST_FAILED</a>: u64 = 2;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_TEST_SUCCESS"></a>



<pre><code><b>const</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_TEST_SUCCESS">TEST_SUCCESS</a>: u64 = 1;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_recipient"></a>

## Function `recipient`



<pre><code><b>public</b> <b>fun</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_recipient">recipient</a>(<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream">stream</a>: &<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">stream::Stream</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_is_entity"></a>

## Function `is_entity`



<pre><code><b>public</b> <b>fun</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_is_entity">is_entity</a>(<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream">stream</a>: &<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">stream::Stream</a>): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_get_stream"></a>

## Function `get_stream`



<pre><code><b>public</b> <b>fun</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_get_stream">get_stream</a>(<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream">stream</a>: &<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">stream::Stream</a>): (<b>address</b>, <b>address</b>, u256, <b>address</b>, u256, u256, u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_set_remaining_balance"></a>

## Function `set_remaining_balance`



<pre><code><b>public</b> <b>fun</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_set_remaining_balance">set_remaining_balance</a>(<a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream">stream</a>: &<b>mut</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">stream::Stream</a>, remaining_balance: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_create_stream"></a>

## Function `create_stream`



<pre><code><b>public</b> <b>fun</b> <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_create_stream">create_stream</a>(deposit: u256, rate_per_second: u256, remaining_balance: u256, start_time: u256, stop_time: u256, recipient: <b>address</b>, sender: <b>address</b>, token_address: <b>address</b>, is_entity: bool): <a href="stream.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_stream_Stream">stream::Stream</a>
</code></pre>
