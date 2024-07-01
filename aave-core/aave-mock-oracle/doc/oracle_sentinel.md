
<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel"></a>

# Module `0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle_sentinel`



-  [Struct `GracePeriodUpdated`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_GracePeriodUpdated)
-  [Resource `OrcaleSentinel`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_OrcaleSentinel)
-  [Constants](#@Constants_0)
-  [Function `init_oracle_sentinel`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_init_oracle_sentinel)
-  [Function `set_answer`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_answer)
-  [Function `latest_round_data`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_latest_round_data)
-  [Function `is_borrow_allowed`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_borrow_allowed)
-  [Function `is_liquidation_allowed`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_liquidation_allowed)
-  [Function `is_up_and_grace_period_passed`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_up_and_grace_period_passed)
-  [Function `set_grace_period`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_grace_period)
-  [Function `get_grace_period`](#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_get_grace_period)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="../../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_GracePeriodUpdated"></a>

## Struct `GracePeriodUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_GracePeriodUpdated">GracePeriodUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_OrcaleSentinel"></a>

## Resource `OrcaleSentinel`



<pre><code><b>struct</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_OrcaleSentinel">OrcaleSentinel</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_E_ORACLE_NOT_ADMIN"></a>



<pre><code><b>const</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_E_ORACLE_NOT_ADMIN">E_ORACLE_NOT_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_E_RESOURCE_NOT_FOUND"></a>



<pre><code><b>const</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_E_RESOURCE_NOT_FOUND">E_RESOURCE_NOT_FOUND</a>: u64 = 2;
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_init_oracle_sentinel"></a>

## Function `init_oracle_sentinel`



<pre><code><b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_init_oracle_sentinel">init_oracle_sentinel</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_answer"></a>

## Function `set_answer`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_answer">set_answer</a>(<a href="">account</a>: &<a href="">signer</a>, is_down: bool, <a href="">timestamp</a>: u256)
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_latest_round_data"></a>

## Function `latest_round_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_latest_round_data">latest_round_data</a>(): (u128, u256, u256, u256, u128)
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_borrow_allowed"></a>

## Function `is_borrow_allowed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_borrow_allowed">is_borrow_allowed</a>(): bool
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_liquidation_allowed"></a>

## Function `is_liquidation_allowed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_liquidation_allowed">is_liquidation_allowed</a>(): bool
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_up_and_grace_period_passed"></a>

## Function `is_up_and_grace_period_passed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_is_up_and_grace_period_passed">is_up_and_grace_period_passed</a>(): bool
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_grace_period"></a>

## Function `set_grace_period`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_set_grace_period">set_grace_period</a>(<a href="">account</a>: &<a href="">signer</a>, new_grace_period: u256)
</code></pre>



<a id="0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_get_grace_period"></a>

## Function `get_grace_period`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle_sentinel_get_grace_period">get_grace_period</a>(): u256
</code></pre>
