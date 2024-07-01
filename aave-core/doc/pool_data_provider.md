
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_data_provider`



-  [Struct `TokenData`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData)
-  [Function `get_all_reserves_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_reserves_tokens)
-  [Function `get_all_a_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_a_tokens)
-  [Function `get_all_var_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_var_tokens)
-  [Function `get_reserve_configuration_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_configuration_data)
-  [Function `get_reserve_emode_category`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_emode_category)
-  [Function `get_reserve_caps`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_caps)
-  [Function `get_paused`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_paused)
-  [Function `get_siloed_borrowing`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_siloed_borrowing)
-  [Function `get_liquidation_protocol_fee`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_liquidation_protocol_fee)
-  [Function `get_unbacked_mint_cap`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_unbacked_mint_cap)
-  [Function `get_debt_ceiling`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling)
-  [Function `get_debt_ceiling_decimals`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling_decimals)
-  [Function `get_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_data)
-  [Function `get_a_token_total_supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_a_token_total_supply)
-  [Function `get_total_debt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_total_debt)
-  [Function `get_user_reserve_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_user_reserve_data)
-  [Function `get_reserve_tokens_addresses`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_tokens_addresses)
-  [Function `get_flash_loan_enabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_flash_loan_enabled)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData"></a>

## Struct `TokenData`



<pre><code><b>struct</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData">TokenData</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_reserves_tokens"></a>

## Function `get_all_reserves_tokens`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_reserves_tokens">get_all_reserves_tokens</a>(): <a href="">vector</a>&lt;<a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData">pool_data_provider::TokenData</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_a_tokens"></a>

## Function `get_all_a_tokens`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_a_tokens">get_all_a_tokens</a>(): <a href="">vector</a>&lt;<a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData">pool_data_provider::TokenData</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_var_tokens"></a>

## Function `get_all_var_tokens`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_all_var_tokens">get_all_var_tokens</a>(): <a href="">vector</a>&lt;<a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_TokenData">pool_data_provider::TokenData</a>&gt;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_configuration_data"></a>

## Function `get_reserve_configuration_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_configuration_data">get_reserve_configuration_data</a>(asset: <b>address</b>): (u256, u256, u256, u256, u256, bool, bool, bool, bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_emode_category"></a>

## Function `get_reserve_emode_category`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_emode_category">get_reserve_emode_category</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_caps"></a>

## Function `get_reserve_caps`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_caps">get_reserve_caps</a>(asset: <b>address</b>): (u256, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_paused"></a>

## Function `get_paused`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_paused">get_paused</a>(asset: <b>address</b>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_siloed_borrowing"></a>

## Function `get_siloed_borrowing`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_siloed_borrowing">get_siloed_borrowing</a>(asset: <b>address</b>): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_liquidation_protocol_fee"></a>

## Function `get_liquidation_protocol_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_liquidation_protocol_fee">get_liquidation_protocol_fee</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_unbacked_mint_cap"></a>

## Function `get_unbacked_mint_cap`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_unbacked_mint_cap">get_unbacked_mint_cap</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling"></a>

## Function `get_debt_ceiling`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling">get_debt_ceiling</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling_decimals"></a>

## Function `get_debt_ceiling_decimals`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_debt_ceiling_decimals">get_debt_ceiling_decimals</a>(): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_data"></a>

## Function `get_reserve_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_data">get_reserve_data</a>(asset: <b>address</b>): (u256, u256, u256, u256, u256, u256, u256, u256, u64)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_a_token_total_supply"></a>

## Function `get_a_token_total_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_a_token_total_supply">get_a_token_total_supply</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_total_debt"></a>

## Function `get_total_debt`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_total_debt">get_total_debt</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_user_reserve_data"></a>

## Function `get_user_reserve_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_user_reserve_data">get_user_reserve_data</a>(asset: <b>address</b>, <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>): (u256, u256, u256, u256, bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_tokens_addresses"></a>

## Function `get_reserve_tokens_addresses`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_reserve_tokens_addresses">get_reserve_tokens_addresses</a>(asset: <b>address</b>): (<b>address</b>, <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_flash_loan_enabled"></a>

## Function `get_flash_loan_enabled`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pool_data_provider.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_data_provider_get_flash_loan_enabled">get_flash_loan_enabled</a>(asset: <b>address</b>): bool
</code></pre>