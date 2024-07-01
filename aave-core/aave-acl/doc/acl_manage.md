
<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage"></a>

# Module `0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753::acl_manage`



-  [Resource `Role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_Role)
-  [Constants](#@Constants_0)
-  [Function `default_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_default_admin_role)
-  [Function `get_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_role)
-  [Function `has_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_has_role)
-  [Function `grant_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_grant_role)
-  [Function `revoke_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_revoke_role)
-  [Function `add_pool_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_pool_admin)
-  [Function `remove_pool_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_pool_admin)
-  [Function `is_pool_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_pool_admin)
-  [Function `add_emergency_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emergency_admin)
-  [Function `remove_emergency_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emergency_admin)
-  [Function `is_emergency_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emergency_admin)
-  [Function `add_risk_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_risk_admin)
-  [Function `remove_risk_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_risk_admin)
-  [Function `is_risk_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_risk_admin)
-  [Function `add_flash_borrower`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_flash_borrower)
-  [Function `remove_flash_borrower`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_flash_borrower)
-  [Function `is_flash_borrower`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_flash_borrower)
-  [Function `add_bridge`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_bridge)
-  [Function `remove_bridge`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_bridge)
-  [Function `is_bridge`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_bridge)
-  [Function `add_asset_listing_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_asset_listing_admin)
-  [Function `remove_asset_listing_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_asset_listing_admin)
-  [Function `is_asset_listing_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_asset_listing_admin)
-  [Function `add_funds_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_funds_admin)
-  [Function `remove_funds_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_funds_admin)
-  [Function `is_funds_admin`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_funds_admin)
-  [Function `add_emission_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emission_admin_role)
-  [Function `remove_emission_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emission_admin_role)
-  [Function `is_emission_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emission_admin_role)
-  [Function `add_admin_controlled_ecosystem_reserve_funds_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `remove_admin_controlled_ecosystem_reserve_funds_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `is_admin_controlled_ecosystem_reserve_funds_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `add_rewards_controller_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_rewards_controller_admin_role)
-  [Function `remove_rewards_controller_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_rewards_controller_admin_role)
-  [Function `is_rewards_controller_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_rewards_controller_admin_role)
-  [Function `get_pool_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_pool_admin_role)
-  [Function `get_emergency_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emergency_admin_role)
-  [Function `get_risk_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_risk_admin_role)
-  [Function `get_flash_borrower_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_flash_borrower_role)
-  [Function `get_bridge_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_bridge_role)
-  [Function `get_asset_listing_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_asset_listing_admin_role)
-  [Function `get_funds_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_funds_admin_role)
-  [Function `get_emission_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emission_admin_role)
-  [Function `get_admin_controlled_ecosystem_reserve_funds_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `get_rewards_controller_admin_role`](#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_rewards_controller_admin_role)


<pre><code><b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_Role"></a>

## Resource `Role`



<pre><code><b>struct</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_Role">Role</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE">ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 68, 77, 73, 78, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 68, 95, 69, 67, 79, 83, 89, 83, 84, 69, 77, 95, 82, 69, 83, 69, 82, 86, 69, 95, 70, 85, 78, 68, 83, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ASSET_LISTING_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ASSET_LISTING_ADMIN_ROLE">ASSET_LISTING_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 83, 83, 69, 84, 95, 76, 73, 83, 84, 73, 78, 71, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_BRIDGE_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_BRIDGE_ROLE">BRIDGE_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [66, 82, 73, 68, 71, 69];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EMERGENCY_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EMERGENCY_ADMIN_ROLE">EMERGENCY_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 69, 82, 71, 69, 78, 67, 89, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EMISSION_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EMISSION_ADMIN_ROLE">EMISSION_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 73, 83, 83, 73, 79, 78, 95, 65, 68, 77, 73, 78, 95, 82, 79, 76, 69];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ENOT_MANAGEMENT"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_ENOT_MANAGEMENT">ENOT_MANAGEMENT</a>: u64 = 1;
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EROLE_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EROLE_ALREADY_EXISTS">EROLE_ALREADY_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EROLE_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_EROLE_NOT_EXISTS">EROLE_NOT_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_FLASH_BORROWER_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_FLASH_BORROWER_ROLE">FLASH_BORROWER_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [70, 76, 65, 83, 72, 95, 66, 79, 82, 82, 79, 87, 69, 82];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_FUNDS_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_FUNDS_ADMIN_ROLE">FUNDS_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [70, 85, 78, 68, 83, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_POOL_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_POOL_ADMIN_ROLE">POOL_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [80, 79, 79, 76, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_REWARDS_CONTROLLER_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_REWARDS_CONTROLLER_ADMIN_ROLE">REWARDS_CONTROLLER_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [82, 69, 87, 65, 82, 68, 83, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 82, 95, 65, 68, 77, 73, 78, 95, 82, 79, 76, 69];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_RISK_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_RISK_ADMIN_ROLE">RISK_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [82, 73, 83, 75, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_default_admin_role"></a>

## Function `default_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_default_admin_role">default_admin_role</a>(): <b>address</b>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_role"></a>

## Function `get_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_role">get_role</a>(role: <a href="_String">string::String</a>, user: <b>address</b>): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_has_role"></a>

## Function `has_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_has_role">has_role</a>(role: <a href="_String">string::String</a>, user: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_grant_role"></a>

## Function `grant_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_grant_role">grant_role</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_revoke_role"></a>

## Function `revoke_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_revoke_role">revoke_role</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_pool_admin"></a>

## Function `add_pool_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_pool_admin">add_pool_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_pool_admin"></a>

## Function `remove_pool_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_pool_admin">remove_pool_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_pool_admin"></a>

## Function `is_pool_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_pool_admin">is_pool_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emergency_admin"></a>

## Function `add_emergency_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emergency_admin">add_emergency_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emergency_admin"></a>

## Function `remove_emergency_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emergency_admin">remove_emergency_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emergency_admin"></a>

## Function `is_emergency_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emergency_admin">is_emergency_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_risk_admin"></a>

## Function `add_risk_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_risk_admin">add_risk_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_risk_admin"></a>

## Function `remove_risk_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_risk_admin">remove_risk_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_risk_admin"></a>

## Function `is_risk_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_risk_admin">is_risk_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_flash_borrower"></a>

## Function `add_flash_borrower`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_flash_borrower">add_flash_borrower</a>(admin: &<a href="">signer</a>, borrower: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_flash_borrower"></a>

## Function `remove_flash_borrower`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_flash_borrower">remove_flash_borrower</a>(admin: &<a href="">signer</a>, borrower: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_flash_borrower"></a>

## Function `is_flash_borrower`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_flash_borrower">is_flash_borrower</a>(borrower: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_bridge"></a>

## Function `add_bridge`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_bridge">add_bridge</a>(admin: &<a href="">signer</a>, bridge: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_bridge"></a>

## Function `remove_bridge`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_bridge">remove_bridge</a>(admin: &<a href="">signer</a>, bridge: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_bridge"></a>

## Function `is_bridge`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_bridge">is_bridge</a>(bridge: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_asset_listing_admin"></a>

## Function `add_asset_listing_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_asset_listing_admin">add_asset_listing_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_asset_listing_admin"></a>

## Function `remove_asset_listing_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_asset_listing_admin">remove_asset_listing_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_asset_listing_admin"></a>

## Function `is_asset_listing_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_asset_listing_admin">is_asset_listing_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_funds_admin"></a>

## Function `add_funds_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_funds_admin">add_funds_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_funds_admin"></a>

## Function `remove_funds_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_funds_admin">remove_funds_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_funds_admin"></a>

## Function `is_funds_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_funds_admin">is_funds_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emission_admin_role"></a>

## Function `add_emission_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_emission_admin_role">add_emission_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emission_admin_role"></a>

## Function `remove_emission_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_emission_admin_role">remove_emission_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emission_admin_role"></a>

## Function `is_emission_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_emission_admin_role">is_emission_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `add_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role">add_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `remove_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role">remove_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `is_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role">is_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_rewards_controller_admin_role"></a>

## Function `add_rewards_controller_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_add_rewards_controller_admin_role">add_rewards_controller_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_rewards_controller_admin_role"></a>

## Function `remove_rewards_controller_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_remove_rewards_controller_admin_role">remove_rewards_controller_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_rewards_controller_admin_role"></a>

## Function `is_rewards_controller_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_is_rewards_controller_admin_role">is_rewards_controller_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_pool_admin_role"></a>

## Function `get_pool_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_pool_admin_role">get_pool_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emergency_admin_role"></a>

## Function `get_emergency_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emergency_admin_role">get_emergency_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_risk_admin_role"></a>

## Function `get_risk_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_risk_admin_role">get_risk_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_flash_borrower_role"></a>

## Function `get_flash_borrower_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_flash_borrower_role">get_flash_borrower_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_bridge_role"></a>

## Function `get_bridge_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_bridge_role">get_bridge_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_asset_listing_admin_role"></a>

## Function `get_asset_listing_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_asset_listing_admin_role">get_asset_listing_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_funds_admin_role"></a>

## Function `get_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_funds_admin_role">get_funds_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emission_admin_role"></a>

## Function `get_emission_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_emission_admin_role">get_emission_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `get_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role">get_admin_controlled_ecosystem_reserve_funds_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_rewards_controller_admin_role"></a>

## Function `get_rewards_controller_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0x1c0b45bb18cf14bcb0b4caaa8e875dfb5eff6d9d8f5b181de3d3e0107f099753_acl_manage_get_rewards_controller_admin_role">get_rewards_controller_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>
