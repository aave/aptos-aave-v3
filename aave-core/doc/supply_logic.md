
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::supply_logic`



-  [Struct `Supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Supply)
-  [Struct `Withdraw`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Withdraw)
-  [Struct `ReserveUsedAsCollateralEnabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralEnabled)
-  [Struct `ReserveUsedAsCollateralDisabled`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralDisabled)
-  [Function `supply`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_supply)
-  [Function `withdraw`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_withdraw)
-  [Function `finalize_transfer`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_finalize_transfer)
-  [Function `set_user_use_reserve_as_collateral`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_set_user_use_reserve_as_collateral)
-  [Function `deposit`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_deposit)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool_validation">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool_validation</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Supply"></a>

## Struct `Supply`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Supply">Supply</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Withdraw"></a>

## Struct `Withdraw`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_Withdraw">Withdraw</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralEnabled"></a>

## Struct `ReserveUsedAsCollateralEnabled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralEnabled">ReserveUsedAsCollateralEnabled</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralDisabled"></a>

## Struct `ReserveUsedAsCollateralDisabled`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_ReserveUsedAsCollateralDisabled">ReserveUsedAsCollateralDisabled</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_supply"></a>

## Function `supply`



<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_supply">supply</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_withdraw">withdraw</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, <b>to</b>: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_finalize_transfer"></a>

## Function `finalize_transfer`



<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_finalize_transfer">finalize_transfer</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u256, balance_from_before: u256, balance_to_before: u256)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_set_user_use_reserve_as_collateral"></a>

## Function `set_user_use_reserve_as_collateral`



<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_set_user_use_reserve_as_collateral">set_user_use_reserve_as_collateral</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, use_as_collateral: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_deposit"></a>

## Function `deposit`



<pre><code><b>public</b> entry <b>fun</b> <a href="supply_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_supply_logic_deposit">deposit</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>
