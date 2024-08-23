
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::emode_logic`

@title emode_logic module
@author Aave
@notice Implements the base logic for all the actions related to the eMode


-  [Struct `UserEModeSet`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UserEModeSet)
-  [Struct `EModeCategory`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory)
-  [Resource `EModeCategoryList`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategoryList)
-  [Resource `UsersEmodeCategory`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UsersEmodeCategory)
-  [Constants](#@Constants_0)
-  [Function `init_emode`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_init_emode)
-  [Function `set_user_emode`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_set_user_emode)
-  [Function `get_user_emode`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_user_emode)
-  [Function `get_emode_e_mode_price_source`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_price_source)
-  [Function `get_emode_configuration`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_configuration)
-  [Function `get_emode_e_mode_label`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_label)
-  [Function `get_emode_e_mode_liquidation_bonus`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_liquidation_bonus)
-  [Function `configure_emode_category`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_configure_emode_category)
-  [Function `is_in_emode_category`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_is_in_emode_category)
-  [Function `get_emode_category_data`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_data)
-  [Function `get_emode_category_ltv`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_ltv)
-  [Function `get_emode_category_liquidation_threshold`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_threshold)
-  [Function `get_emode_category_liquidation_bonus`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_bonus)
-  [Function `get_emode_category_price_source`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_price_source)
-  [Function `get_emode_category_label`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_label)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="pool.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool</a>;
<b>use</b> <a href="validation_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_pool_validation">0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::pool_validation</a>;
<b>use</b> <a href="../aave-mock-oracle/doc/oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle</a>;
<b>use</b> <a href="../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UserEModeSet"></a>

## Struct `UserEModeSet`

@dev Emitted when the user selects a certain asset category for eMode
@param user The address of the user
@param category_id The category id


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UserEModeSet">UserEModeSet</a> <b>has</b> drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory"></a>

## Struct `EModeCategory`



<pre><code><b>struct</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">EModeCategory</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategoryList"></a>

## Resource `EModeCategoryList`

List of eMode categories as a map (emode_category_id => EModeCategory).


<pre><code><b>struct</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategoryList">EModeCategoryList</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UsersEmodeCategory"></a>

## Resource `UsersEmodeCategory`

Map of users address and their eMode category (user_address => emode_category_id)


<pre><code><b>struct</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UsersEmodeCategory">UsersEmodeCategory</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EMPTY_STRING"></a>



<pre><code><b>const</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EMPTY_STRING">EMPTY_STRING</a>: <a href="">vector</a>&lt;u8&gt; = [];
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_init_emode"></a>

## Function `init_emode`

@notice Initializes the eMode


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_init_emode">init_emode</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_set_user_emode"></a>

## Function `set_user_emode`

@notice Updates the user efficiency mode category
@dev Will revert if user is borrowing non-compatible asset or change will drop HF < HEALTH_FACTOR_LIQUIDATION_THRESHOLD
@dev Emits the <code><a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_UserEModeSet">UserEModeSet</a></code> event
@param category_id The state of all users efficiency mode category


<pre><code><b>public</b> entry <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_set_user_emode">set_user_emode</a>(<a href="">account</a>: &<a href="">signer</a>, category_id: u8)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_user_emode"></a>

## Function `get_user_emode`

@notice Returns the eMode the user is using
@param user The address of the user
@return The eMode id


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_user_emode">get_user_emode</a>(<a href="../aave-config/doc/user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user">user</a>: <b>address</b>): u256
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_price_source"></a>

## Function `get_emode_e_mode_price_source`

@notice Get the price source of the eMode category
@param user_emode_category The user eMode category
@return The price source of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_price_source">get_emode_e_mode_price_source</a>(user_emode_category: u8): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_configuration"></a>

## Function `get_emode_configuration`

@notice Gets the eMode configuration and calculates the eMode asset price if a custom oracle is configured
@dev The eMode asset price returned is 0 if no oracle is specified
@param category The user eMode category
@return The eMode ltv
@return The eMode liquidation threshold
@return The eMode asset price


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_configuration">get_emode_configuration</a>(user_emode_category: u8): (u256, u256, u256)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_label"></a>

## Function `get_emode_e_mode_label`

@notice Gets the eMode category label
@param user_emode_category The user eMode category
@return The label of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_label">get_emode_e_mode_label</a>(user_emode_category: u8): <a href="_String">string::String</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_liquidation_bonus"></a>

## Function `get_emode_e_mode_liquidation_bonus`

@notice Gets the eMode category liquidation_bonus
@param user_emode_category The user eMode category
@return The liquidation bonus of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_e_mode_liquidation_bonus">get_emode_e_mode_liquidation_bonus</a>(user_emode_category: u8): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_configure_emode_category"></a>

## Function `configure_emode_category`

@notice Configures a new category for the eMode.
@dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
The category 0 is reserved as it's the default for volatile assets
@param id The id of the category
@param ltv The loan to value ratio
@param liquidation_threshold The liquidation threshold
@param liquidation_bonus The liquidation bonus
@param price_source The address of the oracle to override the individual assets price oracles
@param label The label of the category


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_configure_emode_category">configure_emode_category</a>(id: u8, ltv: u16, liquidation_threshold: u16, liquidation_bonus: u16, price_source: <b>address</b>, label: <a href="_String">string::String</a>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_is_in_emode_category"></a>

## Function `is_in_emode_category`

@notice Checks if eMode is active for a user and if yes, if the asset belongs to the eMode category chosen
@param emode_user_category The user eMode category
@param emode_asset_category The asset eMode category
@return True if eMode is active and the asset belongs to the eMode category chosen by the user, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_is_in_emode_category">is_in_emode_category</a>(emode_user_category: u256, emode_assert_category: u256): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_data"></a>

## Function `get_emode_category_data`

@notice Returns the data of an eMode category
@param id The id of the category
@return The configuration data of the category


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_data">get_emode_category_data</a>(id: u8): <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_ltv"></a>

## Function `get_emode_category_ltv`

@notice Get the ltv of the eMode category
@param emode_category The eMode category
@return The ltv of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_ltv">get_emode_category_ltv</a>(emode_category: &<a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_threshold"></a>

## Function `get_emode_category_liquidation_threshold`

@notice Get the liquidation threshold of the eMode category
@param emode_category The eMode category
@return The liquidation threshold of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_threshold">get_emode_category_liquidation_threshold</a>(emode_category: &<a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_bonus"></a>

## Function `get_emode_category_liquidation_bonus`

@notice Get the liquidation bonus of the eMode category
@param emode_category The eMode category
@return The liquidation bonus of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_liquidation_bonus">get_emode_category_liquidation_bonus</a>(emode_category: &<a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): u16
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_price_source"></a>

## Function `get_emode_category_price_source`

@notice Get the price source of the eMode category
@param emode_category The eMode category
@return The price source of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_price_source">get_emode_category_price_source</a>(emode_category: &<a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): <b>address</b>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_label"></a>

## Function `get_emode_category_label`

@notice Get the label of the eMode category
@param emode_category The eMode category
@return The label of the eMode category


<pre><code><b>public</b> <b>fun</b> <a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_get_emode_category_label">get_emode_category_label</a>(emode_category: &<a href="emode_logic.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_emode_logic_EModeCategory">emode_logic::EModeCategory</a>): <a href="_String">string::String</a>
</code></pre>
