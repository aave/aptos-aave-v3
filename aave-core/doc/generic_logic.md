
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::generic_logic`



-  [Struct `CalculateUserAccountDataVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_CalculateUserAccountDataVars)
-  [Function `calculate_user_account_data`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_user_account_data)
-  [Function `calculate_available_borrows`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_available_borrows)


<pre><code><b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae_oracle">0x70fe84cb8ecce35131a3c36c2592864bf9da740ffd6d2ceb8bd8f773978fa2ae::oracle</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_CalculateUserAccountDataVars"></a>

## Struct `CalculateUserAccountDataVars`



<pre><code><b>struct</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_CalculateUserAccountDataVars">CalculateUserAccountDataVars</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_user_account_data"></a>

## Function `calculate_user_account_data`



<pre><code><b>public</b> <b>fun</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_user_account_data">calculate_user_account_data</a>(reserves_count: u256, user_config_map: &<a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user_UserConfigurationMap">user::UserConfigurationMap</a>, <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">user</a>: <b>address</b>, user_emode_category: u8, emode_ltv: u256, emode_liq_threshold: u256, emode_asset_price: u256): (u256, u256, u256, u256, u256, bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_available_borrows"></a>

## Function `calculate_available_borrows`



<pre><code><b>public</b> <b>fun</b> <a href="generic_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_generic_logic_calculate_available_borrows">calculate_available_borrows</a>(total_collateral_in_base_currency: u256, total_debt_in_base_currency: u256, ltv: u256): u256
</code></pre>
