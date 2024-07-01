module aave_acl::acl_manage {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};

    const POOL_ADMIN_ROLE: vector<u8> = b"POOL_ADMIN";
    const EMERGENCY_ADMIN_ROLE: vector<u8> = b"EMERGENCY_ADMIN";
    const RISK_ADMIN_ROLE: vector<u8> = b"RISK_ADMIN";
    const FLASH_BORROWER_ROLE: vector<u8> = b"FLASH_BORROWER";
    const BRIDGE_ROLE: vector<u8> = b"BRIDGE";
    const ASSET_LISTING_ADMIN_ROLE: vector<u8> = b"ASSET_LISTING_ADMIN";
    const FUNDS_ADMIN_ROLE: vector<u8> = b"FUNDS_ADMIN";
    const EMISSION_ADMIN_ROLE: vector<u8> = b"EMISSION_ADMIN_ROLE";
    const ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE: vector<u8> = b"ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN";
    const REWARDS_CONTROLLER_ADMIN_ROLE: vector<u8> = b"REWARDS_CONTROLLER_ADMIN_ROLE";

    // You are not an administrator and cannot initialize resources.
    const ENOT_MANAGEMENT: u64 = 1;
    // Role already exists.
    const EROLE_ALREADY_EXISTS: u64 = 2;
    // Role does not exist.
    const EROLE_NOT_EXISTS: u64 = 3;

    struct Role has key, store {
        acl_instance: SmartTable<String, vector<address>>
    }

    #[test_only]
    public fun test_init_module(user: &signer) {
        init_module(user);
    }

    fun init_module(user: &signer) {
        check_super_admin(signer::address_of(user));

        move_to(user, Role { acl_instance: smart_table::new<String, vector<address>>() })
    }

    fun check_super_admin(user: address) {
        assert!(user == @aave_acl, ENOT_MANAGEMENT);
    }

    #[view]
    public fun default_admin_role(): address {
        @aave_acl
    }

    #[view]
    public fun get_role(role: String, user: address): vector<address> acquires Role {
        check_super_admin(user);
        let role_res = borrow_global<Role>(@aave_acl);

         *smart_table::borrow(&role_res.acl_instance, role)
    }

    #[view]
    public fun has_role(role: String, user: address): bool acquires Role {
        let role_res = borrow_global<Role>(@aave_acl);
        if (!smart_table::contains(&role_res.acl_instance, role)) {
            return false
        };
        let role_addr_list = smart_table::borrow(&role_res.acl_instance, role);

        vector::contains(role_addr_list, &user)
    }

    public entry fun grant_role(admin: &signer, role: String, user: address) acquires Role {
        check_super_admin(signer::address_of(admin));
        let role_res = borrow_global_mut<Role>(@aave_acl);
        if (!smart_table::contains(&mut role_res.acl_instance, role)) {
            let vector_addr_list = vector<address>[];
            vector::push_back(&mut vector_addr_list, user);
            smart_table::add(&mut role_res.acl_instance, role, vector_addr_list);
        } else {
            let role_addr_list = smart_table::borrow_mut(&mut role_res.acl_instance, role);
            assert!(!vector::contains(role_addr_list, &user), EROLE_ALREADY_EXISTS);
            let role_addr_list = smart_table::borrow_mut(&mut role_res.acl_instance, role);
            vector::push_back(role_addr_list, user);
        }
    }

    public entry fun revoke_role(admin: &signer, role: String, user: address) acquires Role {
        check_super_admin(signer::address_of(admin));
        assert!(has_role(role, user), EROLE_NOT_EXISTS);

        let role_res = borrow_global_mut<Role>(@aave_acl);
        let role_addr_list = smart_table::borrow_mut(&mut role_res.acl_instance, role);

        let _ = vector::remove_value(role_addr_list, &user);
    }

    public entry fun add_pool_admin(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_pool_admin_role(), user);
    }

    public entry fun remove_pool_admin(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_pool_admin_role(), user);
    }

    #[view]
    public fun is_pool_admin(admin: address): bool acquires Role {
        has_role(get_pool_admin_role(), admin)
    }

    public entry fun add_emergency_admin(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_emergency_admin_role(), user);
    }

    public entry fun remove_emergency_admin(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_emergency_admin_role(), user);
    }

    #[view]
    public fun is_emergency_admin(admin: address): bool acquires Role {
        has_role(get_emergency_admin_role(), admin)
    }

    public entry fun add_risk_admin(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_risk_admin_role(), user);
    }

    public entry fun remove_risk_admin(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_risk_admin_role(), user);
    }

    #[view]
    public fun is_risk_admin(admin: address): bool acquires Role {
        has_role(get_risk_admin_role(), admin)
    }

    public entry fun add_flash_borrower(admin: &signer, borrower: address) acquires Role {
        grant_role(admin, get_flash_borrower_role(), borrower);
    }

    public entry fun remove_flash_borrower(admin: &signer, borrower: address) acquires Role {
        revoke_role(admin, get_flash_borrower_role(), borrower);
    }

    #[view]
    public fun is_flash_borrower(borrower: address): bool acquires Role {
        has_role(get_flash_borrower_role(), borrower)
    }

    public entry fun add_bridge(admin: &signer, bridge: address) acquires Role {
        grant_role(admin, get_bridge_role(), bridge);
    }

    public entry fun remove_bridge(admin: &signer, bridge: address) acquires Role {
        revoke_role(admin, get_bridge_role(), bridge);
    }

    #[view]
    public fun is_bridge(bridge: address): bool acquires Role {
        has_role(get_bridge_role(), bridge)
    }

    public entry fun add_asset_listing_admin(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_asset_listing_admin_role(), user);
    }

    public entry fun remove_asset_listing_admin(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_asset_listing_admin_role(), user);
    }

    #[view]
    public fun is_asset_listing_admin(admin: address): bool acquires Role {
        has_role(get_asset_listing_admin_role(), admin)
    }

    public entry fun add_funds_admin(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_funds_admin_role(), user);
    }

    public entry fun remove_funds_admin(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_funds_admin_role(), user);
    }

    #[view]
    public fun is_funds_admin(admin: address): bool acquires Role {
        has_role(get_funds_admin_role(), admin)
    }

    public entry fun add_emission_admin_role(admin: &signer, user: address) acquires Role {
        grant_role(admin, get_emission_admin_role(), user);
    }

    public entry fun remove_emission_admin_role(admin: &signer, user: address) acquires Role {
        revoke_role(admin, get_emission_admin_role(), user);
    }

    #[view]
    public fun is_emission_admin_role(admin: address): bool acquires Role {
        has_role(get_emission_admin_role(), admin)
    }

    public entry fun add_admin_controlled_ecosystem_reserve_funds_admin_role(
        admin: &signer, user: address
    ) acquires Role {
        grant_role(admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user);
    }

    public entry fun remove_admin_controlled_ecosystem_reserve_funds_admin_role(
        admin: &signer, user: address
    ) acquires Role {
        revoke_role(admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user);
    }

    #[view]
    public fun is_admin_controlled_ecosystem_reserve_funds_admin_role(
        admin: address
    ): bool acquires Role {
        has_role(get_admin_controlled_ecosystem_reserve_funds_admin_role(), admin)
    }

    public entry fun add_rewards_controller_admin_role(
        admin: &signer, user: address
    ) acquires Role {
        grant_role(admin, get_rewards_controller_admin_role(), user);
    }

    public entry fun remove_rewards_controller_admin_role(
        admin: &signer, user: address
    ) acquires Role {
        revoke_role(admin, get_rewards_controller_admin_role(), user);
    }

    #[view]
    public fun is_rewards_controller_admin_role(admin: address): bool acquires Role {
        has_role(get_rewards_controller_admin_role(), admin)
    }

    #[view]
    public fun get_pool_admin_role(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[view]
    public fun get_emergency_admin_role(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[view]
    public fun get_risk_admin_role(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[view]
    public fun get_flash_borrower_role(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[view]
    public fun get_bridge_role(): String {
        string::utf8(BRIDGE_ROLE)
    }

    #[view]
    public fun get_asset_listing_admin_role(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }

    #[view]
    public fun get_funds_admin_role(): String {
        string::utf8(FUNDS_ADMIN_ROLE)
    }

    #[view]
    public fun get_emission_admin_role(): String {
        string::utf8(EMISSION_ADMIN_ROLE)
    }

    #[view]
    public fun get_admin_controlled_ecosystem_reserve_funds_admin_role(): String {
        string::utf8(ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE)
    }

    #[view]
    public fun get_rewards_controller_admin_role(): String {
        string::utf8(REWARDS_CONTROLLER_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_pool_admin_role_for_testing(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_emergency_admin_role_for_testing(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_risk_admin_role_for_testing(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_flash_borrower_role_for_testing(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[test_only]
    public fun get_bridge_role_for_testing(): String {
        string::utf8(BRIDGE_ROLE)
    }

    #[test_only]
    public fun get_asset_listing_admin_role_for_testing(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }
}
