
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::bridge_logic`



-  [Struct `ReserveUsedAsCollateralEnabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `MintUnbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_MintUnbacked)
-  [Struct `BackUnbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_BackUnbacked)
-  [Function `mint_unbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_mint_unbacked)
-  [Function `back_unbacked`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_back_unbacked)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_validation</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_MintUnbacked"></a>

## Struct `MintUnbacked`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_MintUnbacked">MintUnbacked</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_BackUnbacked"></a>

## Struct `BackUnbacked`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="bridge_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_BackUnbacked">BackUnbacked</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_mint_unbacked"></a>

## Function `mint_unbacked`



<pre><code><b>public</b> entry <b>fun</b> <a href="bridge_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_mint_unbacked">mint_unbacked</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_back_unbacked"></a>

## Function `back_unbacked`



<pre><code><b>public</b> entry <b>fun</b> <a href="bridge_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_bridge_logic_back_unbacked">back_unbacked</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, fee: u256, protocol_fee_bps: u256)
</code></pre>
