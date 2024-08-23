
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::borrow_logic`

@title borrow_logic module
@author Aave
@notice Implements the base logic for all the actions related to borrowing


-  [Struct `Borrow`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Borrow)
-  [Struct `Repay`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Repay)
-  [Struct `IsolationModeTotalDebtUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_IsolationModeTotalDebtUpdated)
-  [Function `borrow`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_borrow)
-  [Function `internal_borrow`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_internal_borrow)
-  [Function `repay`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay)
-  [Function `repay_with_a_tokens`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay_with_a_tokens)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="a_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_a_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::a_token_factory</a>;
<b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="isolation_mode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::isolation_mode_logic</a>;
<b>use</b> <a href="mock_underlying_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_mock_underlying_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::mock_underlying_token_factory</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_validation_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::validation_logic</a>;
<b>use</b> <a href="variable_debt_token_factory.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_variable_debt_token_factory">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::variable_debt_token_factory</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Borrow"></a>

## Struct `Borrow`

@dev Emitted on borrow() and flashLoan() when debt needs to be opened
@param reserve The address of the underlying asset being borrowed
@param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
initiator of the transaction on flashLoan()
@param on_behalf_of The address that will be getting the debt
@param amount The amount borrowed out
@param interest_rate_mode The rate mode: 2 for Variable
@param borrow_rate The numeric rate at which the user has borrowed, expressed in ray
@param referral_code The referral code used


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Borrow">Borrow</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Repay"></a>

## Struct `Repay`

@dev Emitted on repay()
@param reserve The address of the underlying asset of the reserve
@param user The beneficiary of the repayment, getting his debt reduced
@param repayer The address of the user initiating the repay(), providing the funds
@param amount The amount repaid
@param use_a_tokens True if the repayment is done using aTokens, <code><b>false</b></code> if done with underlying asset directly


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Repay">Repay</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`

@dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
@param asset The address of the underlying asset of the reserve
@param totalDebt The total isolation mode debt for the reserve


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_borrow"></a>

## Function `borrow`

@notice Allows users to borrow a specific <code>amount</code> of the reserve underlying asset, provided that the borrower
already supplied enough collateral, or he was given enough allowance by a credit delegator on the
corresponding debt token VariableDebtToken
- E.g. User borrows 100 USDC passing as <code>on_behalf_of</code> his own address, receiving the 100 USDC in his wallet
and 100 stable/variable debt tokens, depending on the <code>interest_rate_mode</code>
@param asset The address of the underlying asset to borrow
@param amount The amount to be borrowed
@param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
@param referral_code The code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle-man
@param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
if he has been given credit delegation allowance


<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_borrow">borrow</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8, referral_code: u16, on_behalf_of: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_internal_borrow"></a>

## Function `internal_borrow`

@notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
Aave protocol proportionally to their collateralization power. For isolated positions, it also increases the
isolated debt.
@dev  Emits the <code><a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_Borrow">Borrow</a>()</code> event
@param account The signer account
@param asset The address of the underlying asset to borrow
@param amount The amount to be borrowed
@param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
@param referral_code The code used to register the integrator originating the operation, for potential rewards.
0 if the action is executed directly by the user, without any middle
@param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
if he has been given credit delegation allowance
@param release_underlying If true, the underlying asset will be transferred to the user, otherwise it will stay


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_internal_borrow">internal_borrow</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8, referral_code: u16, on_behalf_of: <b>address</b>, release_underlying: bool)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay"></a>

## Function `repay`

@notice Repays a borrowed <code>amount</code> on a specific reserve, burning the equivalent debt tokens owned
- E.g. User repays 100 USDC, burning 100 variable debt tokens of the <code>on_behalf_of</code> address
@param asset The address of the borrowed underlying asset previously borrowed
@param amount The amount to repay
- Send the value math_utils::u256_max() in order to repay the whole debt for <code>asset</code> on the specific <code>debtMode</code>
@param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
@param on_behalf_of The address of the user who will get his debt reduced/removed. Should be the address of the
user calling the function if he wants to reduce/remove his own debt, or the address of any other
other borrower whose debt should be removed


<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay">repay</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8, on_behalf_of: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay_with_a_tokens"></a>

## Function `repay_with_a_tokens`

@notice Repays a borrowed <code>amount</code> on a specific reserve using the reserve aTokens, burning the
equivalent debt tokens
- E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable debt tokens
@dev  Passing math_utils::u256_max() as amount will clean up any residual aToken dust balance, if the user aToken
balance is not enough to cover the whole debt
@param account The signer account
@param asset The address of the borrowed underlying asset previously borrowed
@param amount The amount to repay
@param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable


<pre><code><b>public</b> entry <b>fun</b> <a href="borrow_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_borrow_logic_repay_with_a_tokens">repay_with_a_tokens</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, amount: u256, interest_rate_mode: u8)
</code></pre>
