#[test_only]
module aave_acl::acl_manage_tests {
    use std::signer;
    use aave_acl::acl_manage::{
        test_init_module,
        add_pool_admin,
        add_asset_listing_admin,
        has_role,
        grant_role,
        is_pool_admin,
        is_asset_listing_admin,
        remove_risk_admin,
        is_risk_admin,
        add_risk_admin,
        remove_flash_borrower,
        is_flash_borrower,
        add_flash_borrower,
        is_emergency_admin,
        remove_emergency_admin,
        add_emergency_admin,
        is_bridge,
        remove_bridge,
        add_bridge,
        remove_asset_listing_admin,
        revoke_role,
        get_asset_listing_admin_role,
        get_bridge_role,
        get_emergency_admin_role,
        get_flash_borrower_role,
        get_pool_admin_role,
        get_risk_admin_role,
        remove_pool_admin,
        get_pool_admin_role_for_testing,
        get_emergency_admin_role_for_testing,
        get_risk_admin_role_for_testing,
        get_flash_borrower_role_for_testing,
        get_bridge_role_for_testing,
        get_asset_listing_admin_role_for_testing,
        add_funds_admin,
        remove_funds_admin,
        is_funds_admin,
        add_emission_admin_role,
        remove_emission_admin_role,
        is_emission_admin_role,
        add_admin_controlled_ecosystem_reserve_funds_admin_role,
        remove_admin_controlled_ecosystem_reserve_funds_admin_role,
        is_admin_controlled_ecosystem_reserve_funds_admin_role,
        add_rewards_controller_admin_role,
        remove_rewards_controller_admin_role,
        is_rewards_controller_admin_role
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // ========== TEST: BASIC GETTERS ============
    #[test]
    fun test_asset_listing_admin_role() {
        assert!(get_asset_listing_admin_role() == get_asset_listing_admin_role_for_testing(),
            TEST_SUCCESS);
    }

    #[test]
    fun test_get_bridge_role() {
        assert!(get_bridge_role() == get_bridge_role_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_get_flash_borrower_role() {
        assert!(get_flash_borrower_role() == get_flash_borrower_role_for_testing(),
            TEST_SUCCESS);
    }

    #[test]
    fun test_get_risk_admin_role() {
        assert!(get_risk_admin_role() == get_risk_admin_role_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_get_emergency_admin_role() {
        assert!(get_emergency_admin_role() == get_emergency_admin_role_for_testing(),
            TEST_SUCCESS);
    }

    #[test]
    fun test_get_pool_admin_role() {
        assert!(get_pool_admin_role() == get_pool_admin_role_for_testing(), TEST_SUCCESS);
    }

    // ========== TEST: TEST OWNER HOLDERS ============

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_asset_listing_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_asset_listing_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_asset_listing_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_bridge(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_bridge_role_for_testing(), signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_bridge(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_flash_borrower(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_flash_borrower_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_flash_borrower(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_risk_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_risk_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_risk_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_emergency_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_emergency_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_emergency_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_pool_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_pool_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    // ========== TEST: GRANT ROLE + HAS ROLE ============
    #[test(super_admin = @aave_acl, test_addr = @0x01, other_addr = @0x02)]
    fun test_has_role(
        super_admin: &signer, test_addr: &signer, other_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_pool_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!has_role(get_pool_admin_role_for_testing(), signer::address_of(other_addr)),
            TEST_SUCCESS);
    }

    // ========== TEST: REVOKE + HAS ROLE ============
    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_revoke_role(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(super_admin, get_pool_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // now remove the role
        revoke_role(super_admin, get_pool_admin_role_for_testing(),
            signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!has_role(get_pool_admin_role_for_testing(), signer::address_of(test_addr)),
            TEST_SUCCESS);
    }

    // ============== SPECIAL FUNCTIONS ============ //
    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_pool_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_pool_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_pool_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_asset_listing_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_asset_listing_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_asset_listing_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_asset_listing_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_asset_listing_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_bridge_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_bridge(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_bridge(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_bridge(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_bridge(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_emergency_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_emergency_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_emergency_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_emergency_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_emergency_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_flash_borrower_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_flash_borrower(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_flash_borrower(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_flash_borrower(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_flash_borrower(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_risk_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_risk_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_risk_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_risk_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_risk_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_funds_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_funds_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_funds_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_funds_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_funds_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_emission_admin_role(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_emission_admin_role(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_emission_admin_role(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_emission_admin_role(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_emission_admin_role(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_admin_controlled_ecosystem_reserve_funds_admin_role(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_admin_controlled_ecosystem_reserve_funds_admin_role(super_admin,
            signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_admin_controlled_ecosystem_reserve_funds_admin_role(signer::address_of(
                    test_addr)),
            TEST_SUCCESS);
        // remove pool admin
        remove_admin_controlled_ecosystem_reserve_funds_admin_role(super_admin,
            signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_admin_controlled_ecosystem_reserve_funds_admin_role(signer::address_of(
                    test_addr)),
            TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_rewards_controller_admin_role(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_rewards_controller_admin_role(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_rewards_controller_admin_role(signer::address_of(test_addr)),
            TEST_SUCCESS);
        // remove pool admin
        remove_rewards_controller_admin_role(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_rewards_controller_admin_role(signer::address_of(test_addr)),
            TEST_SUCCESS);
    }
}