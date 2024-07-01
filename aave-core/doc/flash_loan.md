
<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic"></a>

# Module `0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::flashloan_logic`



-  [Struct `FlashLoan`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoan)
-  [Struct `FlashLoanLocalVars`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanLocalVars)
-  [Struct `SimpleFlashLoansReceipt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_SimpleFlashLoansReceipt)
-  [Struct `ComplexFlashLoansReceipt`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_ComplexFlashLoansReceipt)
-  [Struct `FlashLoanRepaymentParams`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanRepaymentParams)
-  [Function `flashloan`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flashloan)
-  [Function `flash_loan_simple`](#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flash_loan_simple)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage">0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_error">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::error</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2_user">0x2b375fc8da759f1f7c198ffa5a0bf4466a5eb25564272115a1fa2c30b22657a2::user</a>;
<b>use</b> <a href="a_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_a_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::a_token_factory</a>;
<b>use</b> <a href="borrow_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_borrow_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::borrow_logic</a>;
<b>use</b> <a href="pool.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_pool">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::pool</a>;
<b>use</b> <a href="underlying_token_factory.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_underlying_token_factory">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::underlying_token_factory</a>;
<b>use</b> <a href="validation_logic.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_validation_logic">0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529::validation_logic</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_math_utils">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77_wad_ray_math">0x6b73dc9e557f4e984e7777685602c2e15559a5f4ec06293a5855206490ac9b77::wad_ray_math</a>;
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoan"></a>

## Struct `FlashLoan`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoan">FlashLoan</a> <b>has</b> drop, store
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanLocalVars"></a>

## Struct `FlashLoanLocalVars`



<pre><code><b>struct</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanLocalVars">FlashLoanLocalVars</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_SimpleFlashLoansReceipt"></a>

## Struct `SimpleFlashLoansReceipt`



<pre><code><b>struct</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_SimpleFlashLoansReceipt">SimpleFlashLoansReceipt</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_ComplexFlashLoansReceipt"></a>

## Struct `ComplexFlashLoansReceipt`



<pre><code><b>struct</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_ComplexFlashLoansReceipt">ComplexFlashLoansReceipt</a>
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanRepaymentParams"></a>

## Struct `FlashLoanRepaymentParams`



<pre><code><b>struct</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_FlashLoanRepaymentParams">FlashLoanRepaymentParams</a> <b>has</b> drop
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flashloan"></a>

## Function `flashloan`



<pre><code><b>public</b> entry <b>fun</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flashloan">flashloan</a>(<a href="">account</a>: &<a href="">signer</a>, receiver_address: <b>address</b>, assets: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u256&gt;, interest_rate_modes: <a href="">vector</a>&lt;u8&gt;, on_behalf_of: <b>address</b>, referral_code: u16)
</code></pre>



<a id="0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flash_loan_simple"></a>

## Function `flash_loan_simple`



<pre><code><b>public</b> entry <b>fun</b> <a href="flash_loan.md#0x671a571aefb734eac5263967388f8611f2b11f603b0f9c90bc77851d18928529_flashloan_logic_flash_loan_simple">flash_loan_simple</a>(<a href="">account</a>: &<a href="">signer</a>, receiver_address: <b>address</b>, asset: <b>address</b>, amount: u256, referral_code: u16)
</code></pre>
