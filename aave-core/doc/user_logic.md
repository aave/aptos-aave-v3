
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_user_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::user_logic`



-  [Function `get_user_account_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_user_logic_get_user_account_data)


<pre><code><b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::generic_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_user_logic_get_user_account_data"></a>

## Function `get_user_account_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="user_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_user_logic_get_user_account_data">get_user_account_data</a>(<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>): (u256, u256, u256, u256, u256, u256)
</code></pre>
