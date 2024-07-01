
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic`



-  [Struct `UserEModeSet`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UserEModeSet)
-  [Struct `EModeCategory`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory)
-  [Resource `EModeCategoryList`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategoryList)
-  [Resource `UsersEmodeCategory`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UsersEmodeCategory)
-  [Constants](#@Constants_0)
-  [Function `init_emode`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_init_emode)
-  [Function `set_user_emode`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_set_user_emode)
-  [Function `get_user_emode`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_user_emode)
-  [Function `get_emode_e_mode_price_source`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_price_source)
-  [Function `get_emode_configuration`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_configuration)
-  [Function `get_emode_e_mode_label`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_label)
-  [Function `get_emode_e_mode_liquidation_bonus`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_liquidation_bonus)
-  [Function `configure_emode_category`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_configure_emode_category)
-  [Function `is_in_emode_category`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_is_in_emode_category)
-  [Function `get_emode_category_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_data)
-  [Function `get_emode_category_ltv`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_ltv)
-  [Function `get_emode_category_liquidation_threshold`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_threshold)
-  [Function `get_emode_category_liquidation_bonus`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_bonus)
-  [Function `get_emode_category_price_source`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_price_source)
-  [Function `get_emode_category_label`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_label)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_validation</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UserEModeSet"></a>

## Struct `UserEModeSet`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UserEModeSet">UserEModeSet</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory"></a>

## Struct `EModeCategory`



<pre><code><b>struct</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">EModeCategory</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategoryList"></a>

## Resource `EModeCategoryList`



<pre><code><b>struct</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategoryList">EModeCategoryList</a> <b>has</b> key
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UsersEmodeCategory"></a>

## Resource `UsersEmodeCategory`



<pre><code><b>struct</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_UsersEmodeCategory">UsersEmodeCategory</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EMPTY_STRING"></a>



<pre><code><b>const</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EMPTY_STRING">EMPTY_STRING</a>: <a href="">vector</a>&lt;u8&gt; = [];
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_init_emode"></a>

## Function `init_emode`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_init_emode">init_emode</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_set_user_emode"></a>

## Function `set_user_emode`



<pre><code><b>public</b> entry <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_set_user_emode">set_user_emode</a>(<a href="">account</a>: &<a href="">signer</a>, category_id: u8)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_user_emode"></a>

## Function `get_user_emode`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_user_emode">get_user_emode</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>): u256
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_price_source"></a>

## Function `get_emode_e_mode_price_source`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_price_source">get_emode_e_mode_price_source</a>(user_emode_category: u8): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_configuration"></a>

## Function `get_emode_configuration`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_configuration">get_emode_configuration</a>(user_emode_category: u8): (u256, u256, u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_label"></a>

## Function `get_emode_e_mode_label`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_label">get_emode_e_mode_label</a>(user_emode_category: u8): <a href="_String">string::String</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_liquidation_bonus"></a>

## Function `get_emode_e_mode_liquidation_bonus`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_e_mode_liquidation_bonus">get_emode_e_mode_liquidation_bonus</a>(user_emode_category: u8): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_configure_emode_category"></a>

## Function `configure_emode_category`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_configure_emode_category">configure_emode_category</a>(id: u8, ltv: u16, liquidation_threshold: u16, liquidation_bonus: u16, price_source: <b>address</b>, label: <a href="_String">string::String</a>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_is_in_emode_category"></a>

## Function `is_in_emode_category`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_is_in_emode_category">is_in_emode_category</a>(emode_user_category: u256, emode_assert_category: u256): bool
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_data"></a>

## Function `get_emode_category_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_data">get_emode_category_data</a>(id: u8): <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_ltv"></a>

## Function `get_emode_category_ltv`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_ltv">get_emode_category_ltv</a>(emode_category: &<a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_threshold"></a>

## Function `get_emode_category_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_threshold">get_emode_category_liquidation_threshold</a>(emode_category: &<a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_bonus"></a>

## Function `get_emode_category_liquidation_bonus`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_liquidation_bonus">get_emode_category_liquidation_bonus</a>(emode_category: &<a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_price_source"></a>

## Function `get_emode_category_price_source`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_price_source">get_emode_category_price_source</a>(emode_category: &<a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): <b>address</b>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_label"></a>

## Function `get_emode_category_label`



<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_get_emode_category_label">get_emode_category_label</a>(emode_category: &<a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): <a href="_String">string::String</a>
</code></pre>
