module aave_pool::package_manager {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::resource_account;
    use aptos_std::smart_table::{Self, SmartTable};
    use std::string::String;

    friend aave_pool::coin_wrapper;

    /// Stores permission config such as SignerCapability for controlling the resource account.
    struct PermissionConfig has key {
        /// Required to obtain the resource account signer.
        signer_cap: SignerCapability,
        /// Track the addresses created by the modules in this package.
        addresses: SmartTable<String, address>,
    }

    /// Initialize PermissionConfig to establish control over the resource account.
    /// This function is invoked only when this package is deployed the first time.
    fun initialize(sender: &signer) {
        let signer_cap =
            resource_account::retrieve_resource_account_cap(sender, @deployer_pm);
        initialize_helper(sender, signer_cap);
    }

    fun initialize_helper(sender: &signer, signer_cap: SignerCapability) {
        move_to(
            sender,
            PermissionConfig { addresses: smart_table::new<String, address>(), signer_cap, },
        );
    }

    /// Can be called by friended modules to obtain the resource account signer.
    public(friend) fun get_signer(): signer acquires PermissionConfig {
        let signer_cap = &borrow_global<PermissionConfig>(@resource_pm).signer_cap;
        account::create_signer_with_capability(signer_cap)
    }

    #[test_only]
    public fun get_signer_test(): signer acquires PermissionConfig {
        get_signer()
    }

    /// Can be called by friended modules to keep track of a system address.
    public(friend) fun add_address(name: String, object: address) acquires PermissionConfig {
        let addresses = &mut borrow_global_mut<PermissionConfig>(@resource_pm).addresses;
        smart_table::add(addresses, name, object);
    }

    #[test_only]
    public fun add_address_test(name: String, object: address) acquires PermissionConfig {
        add_address(name, object)
    }

    public(friend) fun address_exists(name: String): bool acquires PermissionConfig {
        smart_table::contains(&safe_permission_config().addresses, name)
    }

    public(friend) fun get_address(name: String): address acquires PermissionConfig {
        let addresses = &borrow_global<PermissionConfig>(@resource_pm).addresses;
        *smart_table::borrow(addresses, name)
    }

    #[test_only]
    public fun get_address_test(name: String): address acquires PermissionConfig {
        get_address(name)
    }

    inline fun safe_permission_config(): &PermissionConfig acquires PermissionConfig {
        borrow_global<PermissionConfig>(@resource_pm)
    }

    #[test_only]
    public fun initialize_for_test(deployer: &signer) {
        let deployer_addr = std::signer::address_of(deployer);
        if (!exists<PermissionConfig>(deployer_addr)) {
            aptos_framework::timestamp::set_time_has_started_for_testing(
                &account::create_signer_for_test(@0x1)
            );

            account::create_account_for_test(deployer_addr);
            initialize_helper(deployer, account::create_test_signer_cap(deployer_addr));
        };
    }
}
