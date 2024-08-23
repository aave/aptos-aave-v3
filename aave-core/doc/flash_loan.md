
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::flashloan_logic`

@title flashloan_logic module
@author Aave
@notice Implements the logic for the flash loans


-  [Struct `FlashLoan`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoan)
-  [Struct `FlashLoanLocalVars`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanLocalVars)
-  [Struct `SimpleFlashLoansReceipt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_SimpleFlashLoansReceipt)
-  [Struct `ComplexFlashLoansReceipt`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_ComplexFlashLoansReceipt)
-  [Struct `FlashLoanRepaymentParams`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanRepaymentParams)
-  [Function `flashloan`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flashloan)
-  [Function `pay_flash_loan_complex`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_complex)
-  [Function `flash_loan_simple`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flash_loan_simple)
-  [Function `pay_flash_loan_simple`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_simple)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="../aave-math/doc/wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::borrow_logic</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic</a>;
<b>use</b> <a href="../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoan"></a>

## Struct `FlashLoan`

@dev Emitted on flashLoan()
@param target The address of the flash loan receiver contract
@param initiator The address initiating the flash loan
@param asset The address of the asset being flash borrowed
@param amount The amount flash borrowed
@param interest_rate_mode The flashloan mode: 0 for regular flashloan, 2 for Variable debt
@param premium The fee flash borrowed
@param referral_code The referral code used


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoan">FlashLoan</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanLocalVars"></a>

## Struct `FlashLoanLocalVars`

Helper struct for internal variables used in the <code>executeFlashLoan</code> function


<pre><code><b>struct</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanLocalVars">FlashLoanLocalVars</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_SimpleFlashLoansReceipt"></a>

## Struct `SimpleFlashLoansReceipt`



<pre><code><b>struct</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_SimpleFlashLoansReceipt">SimpleFlashLoansReceipt</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_ComplexFlashLoansReceipt"></a>

## Struct `ComplexFlashLoansReceipt`



<pre><code><b>struct</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_ComplexFlashLoansReceipt">ComplexFlashLoansReceipt</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanRepaymentParams"></a>

## Struct `FlashLoanRepaymentParams`



<pre><code><b>struct</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_FlashLoanRepaymentParams">FlashLoanRepaymentParams</a> <b>has</b> drop
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flashloan"></a>

## Function `flashloan`

@notice Allows smartcontracts to access the liquidity of the pool within one transaction,
as long as the amount taken plus a fee is returned.
@dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
into consideration. For further details please visit https://docs.aave.com/developers/
@param receiver_address The address of the contract receiving the funds
@param assets The addresses of the assets being flash-borrowed
@param amounts The amounts of the assets being flash-borrowed
@param interest_rate_modes Types of the debt to open if the flash loan is not returned:
0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
2 -> Open debt at variable rate for the value of the amount flash-borrowed to the <code>onBehalfOf</code> address
@param on_behalf_of The address  that will receive the debt in the case of using on <code>modes</code> 2
@param referral_code The code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle-man


<pre><code><b>public</b> <b>fun</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flashloan">flashloan</a>(<a href="">account</a>: &<a href="">signer</a>, receiver_address: <b>address</b>, assets: <a href="">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="">vector</a>&lt;u256&gt;, interest_rate_modes: <a href="">vector</a>&lt;u8&gt;, on_behalf_of: <b>address</b>, referral_code: u16): <a href="">vector</a>&lt;<a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_ComplexFlashLoansReceipt">flashloan_logic::ComplexFlashLoansReceipt</a>&gt;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_complex"></a>

## Function `pay_flash_loan_complex`



<pre><code><b>public</b> <b>fun</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_complex">pay_flash_loan_complex</a>(<a href="">account</a>: &<a href="">signer</a>, flashloan_receipts: <a href="">vector</a>&lt;<a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_ComplexFlashLoansReceipt">flashloan_logic::ComplexFlashLoansReceipt</a>&gt;)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flash_loan_simple"></a>

## Function `flash_loan_simple`

@notice Allows smartcontracts to access the liquidity of the pool within one transaction,
as long as the amount taken plus a fee is returned.
@dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
into consideration. For further details please visit https://docs.aave.com/developers/
@param receiver_address The address of the contract receiving the funds
@param asset The address of the asset being flash-borrowed
@param amount The amount of the asset being flash-borrowed
@param referral_code The code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle-man


<pre><code><b>public</b> <b>fun</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_flash_loan_simple">flash_loan_simple</a>(<a href="">account</a>: &<a href="">signer</a>, receiver_address: <b>address</b>, asset: <b>address</b>, amount: u256, referral_code: u16): <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_SimpleFlashLoansReceipt">flashloan_logic::SimpleFlashLoansReceipt</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_simple"></a>

## Function `pay_flash_loan_simple`



<pre><code><b>public</b> <b>fun</b> <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_pay_flash_loan_simple">pay_flash_loan_simple</a>(<a href="">account</a>: &<a href="">signer</a>, flashloan_receipt: <a href="flash_loan.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_flashloan_logic_SimpleFlashLoansReceipt">flashloan_logic::SimpleFlashLoansReceipt</a>)
</code></pre>
