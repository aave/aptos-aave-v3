
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::isolation_mode_logic`



-  [Struct `IsolationModeTotalDebtUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_IsolationModeTotalDebtUpdated)
-  [Function `update_isolated_debt_if_isolated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_update_isolated_debt_if_isolated)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="isolation_mode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_update_isolated_debt_if_isolated"></a>

## Function `update_isolated_debt_if_isolated`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="isolation_mode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic_update_isolated_debt_if_isolated">update_isolated_debt_if_isolated</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_data: &<a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_ReserveData">pool::ReserveData</a>, repay_amount: u256)
</code></pre>
