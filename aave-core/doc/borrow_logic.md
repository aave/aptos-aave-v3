
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::borrow_logic`



-  [Struct `Borrow`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Borrow)
-  [Struct `Repay`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Repay)
-  [Struct `IsolationModeTotalDebtUpdated`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_IsolationModeTotalDebtUpdated)
-  [Function `borrow`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_borrow)
-  [Function `internal_borrow`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_internal_borrow)
-  [Function `repay`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay)
-  [Function `repay_with_a_tokens`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay_with_a_tokens)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_reserve">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_emode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::emode_logic</a>;
<b>use</b> <a href="isolation_mode_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_isolation_mode_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::isolation_mode_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic</a>;
<b>use</b> <a href="variable_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_variable_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::variable_token_factory</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Borrow"></a>

## Struct `Borrow`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Borrow">Borrow</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Repay"></a>

## Struct `Repay`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_Repay">Repay</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_borrow"></a>

## Function `borrow`



<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_borrow">borrow</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, interest_rate_mode: u8, referral_code: u16)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_internal_borrow"></a>

## Function `internal_borrow`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_internal_borrow">internal_borrow</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, on_behalf_of: <b>address</b>, amount: u256, interest_rate_mode: u8, referral_code: u16, release_underlying: bool)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay"></a>

## Function `repay`



<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay">repay</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8, on_behalf_of: <b>address</b>)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay_with_a_tokens"></a>

## Function `repay_with_a_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic_repay_with_a_tokens">repay_with_a_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8)
</code></pre>
