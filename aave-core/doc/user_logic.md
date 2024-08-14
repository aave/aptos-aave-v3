
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_user_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::user_logic`



-  [Function `get_user_account_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_user_logic_get_user_account_data)


<pre><code><b>use</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic</a>;
<b>use</b> <a href="generic_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_generic_logic">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::generic_logic</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_user_logic_get_user_account_data"></a>

## Function `get_user_account_data`

@notice Returns the user account data across all the reserves
@param user The address of the user
@return total_collateral_base The total collateral of the user in the base currency used by the price feed
@return total_debt_base The total debt of the user in the base currency used by the price feed
@return available_borrows_base The borrowing power left of the user in the base currency used by the price feed
@return current_liquidation_threshold The liquidation threshold of the user
@return ltv The loan to value of The user
@return health_factor The current health factor of the user


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="user_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_user_logic_get_user_account_data">get_user_account_data</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): (u256, u256, u256, u256, u256, u256)
</code></pre>
