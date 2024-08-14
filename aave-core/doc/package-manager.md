
<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager"></a>

# Module `0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370::package_manager`



-  [Resource `PermissionConfig`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_PermissionConfig)
-  [Function `get_signer`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_signer)
-  [Function `add_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_add_address)
-  [Function `address_exists`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_address_exists)
-  [Function `get_address`](#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_address)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::resource_account</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_PermissionConfig"></a>

## Resource `PermissionConfig`

Stores permission config such as SignerCapability for controlling the resource account.


<pre><code><b>struct</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_PermissionConfig">PermissionConfig</a> <b>has</b> key
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_signer"></a>

## Function `get_signer`

Can be called by friended modules to obtain the resource account signer.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_signer">get_signer</a>(): <a href="">signer</a>
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_add_address"></a>

## Function `add_address`

Can be called by friended modules to keep track of a system address.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_add_address">add_address</a>(name: <a href="_String">string::String</a>, <a href="">object</a>: <b>address</b>)
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_address_exists"></a>

## Function `address_exists`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_address_exists">address_exists</a>(name: <a href="_String">string::String</a>): bool
</code></pre>



<a id="0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_address"></a>

## Function `get_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="package-manager.md#0xaaeecbeff5c135e527602a0fd44e242efbed5ebec8f911e1e3f4933f62ed2370_package_manager_get_address">get_address</a>(name: <a href="_String">string::String</a>): <b>address</b>
</code></pre>
