
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::staked_token`



-  [Resource `MockStakedToken`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken)
-  [Function `staked_token`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_staked_token)
-  [Function `stake`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_stake)
-  [Function `create_mock_staked_token`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_create_mock_staked_token)


<pre><code></code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken"></a>

## Resource `MockStakedToken`



<pre><code><b>struct</b> <a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken">MockStakedToken</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_staked_token"></a>

## Function `staked_token`



<pre><code><b>public</b> <b>fun</b> <a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token">staked_token</a>(mock_staked_token: &<a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken">staked_token::MockStakedToken</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_stake"></a>

## Function `stake`



<pre><code><b>public</b> <b>fun</b> <a href="">stake</a>(_mock_staked_token: &<a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken">staked_token::MockStakedToken</a>, _to: <b>address</b>, _amount: u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_create_mock_staked_token"></a>

## Function `create_mock_staked_token`



<pre><code><b>public</b> <b>fun</b> <a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_create_mock_staked_token">create_mock_staked_token</a>(addr: <b>address</b>): <a href="staked_token.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_staked_token_MockStakedToken">staked_token::MockStakedToken</a>
</code></pre>
