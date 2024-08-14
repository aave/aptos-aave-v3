
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::isolation_mode_logic`



-  [Struct `IsolationModeTotalDebtUpdated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_IsolationModeTotalDebtUpdated)
-  [Function `update_isolated_debt_if_isolated`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_update_isolated_debt_if_isolated)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="../aave-math/doc/math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="../aave-config/doc/reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_IsolationModeTotalDebtUpdated"></a>

## Struct `IsolationModeTotalDebtUpdated`

@dev Emitted on borrow(), repay() and liquidation_call() when using isolated assets
@param asset The address of the underlying asset of the reserve
@param total_debt The total isolation mode debt for the reserve


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="isolation_mode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_IsolationModeTotalDebtUpdated">IsolationModeTotalDebtUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_update_isolated_debt_if_isolated"></a>

## Function `update_isolated_debt_if_isolated`

@notice updated the isolated debt whenever a position collateralized by an isolated asset is repaid or liquidated
@param user_config_map The user configuration map
@param reserve_data The reserve data
@param repay_amount The amount being repaid


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="isolation_mode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_isolation_mode_logic_update_isolated_debt_if_isolated">update_isolated_debt_if_isolated</a>(user_config_map: &<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_data: &<a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_ReserveData">pool::ReserveData</a>, repay_amount: u256)
</code></pre>
