#[test_only]
module aave_acl::acl_manage_tests {
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;

    use aave_acl::acl_manage::{
        add_admin_controlled_ecosystem_reserve_funds_admin,
        add_asset_listing_admin,
        add_emergency_admin,
        add_emission_admin,
        add_flash_borrower,
        add_funds_admin,
        add_pool_admin,
        add_rewards_controller_admin,
        add_risk_admin,
        get_admin_controlled_ecosystem_reserve_funds_admin_role,
        get_admin_controlled_ecosystem_reserve_funds_admin_role_for_testing,
        get_asset_listing_admin_role,
        get_asset_listing_admin_role_for_testing,
        get_emergency_admin_role,
        get_emergency_admin_role_for_testing,
        get_emission_admin_role,
        get_emissions_admin_role_for_testing,
        get_flash_borrower_role,
        get_flash_borrower_role_for_testing,
        get_funds_admin_role,
        get_funds_admin_role_for_testing,
        get_pool_admin_role,
        get_pool_admin_role_for_testing,
        get_rewards_controller_admin_role,
        get_rewards_controller_admin_role_for_testing,
        get_risk_admin_role,
        get_risk_admin_role_for_testing,
        get_gho_guardian_role,
        get_gho_guardian_role_for_testing,
        grant_role,
        has_role,
        is_admin_controlled_ecosystem_reserve_funds_admin,
        is_asset_listing_admin,
        is_emergency_admin,
        is_emission_admin,
        is_flash_borrower,
        is_funds_admin,
        is_pool_admin,
        is_rewards_controller_admin,
        is_risk_admin,
        remove_admin_controlled_ecosystem_reserve_funds_admin,
        remove_asset_listing_admin,
        remove_emergency_admin,
        remove_emission_admin,
        remove_flash_borrower,
        remove_funds_admin,
        remove_pool_admin,
        remove_rewards_controller_admin,
        remove_risk_admin,
        revoke_role,
        set_role_admin,
        test_init_module,
        RoleAdminChanged,
        RoleGranted,
        RoleRevoked,
        assert_roles_initialized_for_testing,
        default_admin_role,
        get_role_admin,
        renounce_role
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(account = @0x41)]
    #[expected_failure(abort_code = 1001, location = aave_acl::acl_manage)]
    fun test_init_module_with_non_acl_owner(account: &signer) {
        test_init_module(account);
    }

    // ========== TEST: BASIC GETTERS ============
    #[test]
    fun test_asset_listing_admin_role() {
        assert!(
            get_asset_listing_admin_role()
                == get_asset_listing_admin_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_flash_borrower_role() {
        assert!(
            get_flash_borrower_role() == get_flash_borrower_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_risk_admin_role() {
        assert!(get_risk_admin_role() == get_risk_admin_role_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_get_gho_guardian_role() {
        assert!(
            get_gho_guardian_role() == get_gho_guardian_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_emergency_admin_role() {
        assert!(
            get_emergency_admin_role() == get_emergency_admin_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_pool_admin_role() {
        assert!(get_pool_admin_role() == get_pool_admin_role_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_funds_admin_role() {
        assert!(
            get_funds_admin_role() == get_funds_admin_role_for_testing(), TEST_SUCCESS
        );
    }

    #[test]
    fun test_emission_admin_role() {
        assert!(
            get_emission_admin_role() == get_emissions_admin_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_admin_controlled_ecosystem_reserve_funds_admin_role() {
        assert!(
            get_admin_controlled_ecosystem_reserve_funds_admin_role()
                == get_admin_controlled_ecosystem_reserve_funds_admin_role_for_testing(),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_rewards_controller_admin_role() {
        assert!(
            get_rewards_controller_admin_role()
                == get_rewards_controller_admin_role_for_testing(),
            TEST_SUCCESS
        );
    }

    // ========== TEST: TEST OWNER HOLDERS ============

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_asset_listing_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_asset_listing_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_asset_listing_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_flash_borrower(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_flash_borrower_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_flash_borrower(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_risk_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_risk_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_risk_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_emergency_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_emergency_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_emergency_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_pool_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_funds_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_funds_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_funds_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_emission_admin(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_emissions_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_emission_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_admin_controlled_ecosystem_reserve_funds_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_admin_controlled_ecosystem_reserve_funds_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(
            is_admin_controlled_ecosystem_reserve_funds_admin(
                signer::address_of(test_addr)
            ),
            TEST_SUCCESS
        );
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_is_rewards_controller_admin(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_rewards_controller_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(
            is_rewards_controller_admin(signer::address_of(test_addr)),
            TEST_SUCCESS
        );
    }

    // ========== TEST: GRANT ROLE + HAS ROLE ============
    #[test(super_admin = @aave_acl, test_addr = @0x01, other_addr = @0x02)]
    fun test_grant_role(
        super_admin: &signer, test_addr: &signer, other_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);

        // 1. Test the role already exists
        // set role admin
        let role_admin = utf8(b"role_admin");
        set_role_admin(super_admin, get_risk_admin_role_for_testing(), role_admin);

        // check emitted events
        let emitted_events = emitted_events<RoleAdminChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        grant_role(super_admin, role_admin, signer::address_of(super_admin));

        // check emitted events
        let emitted_events = emitted_events<RoleGranted>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // check the address has the role assigned
        assert!(
            has_role(role_admin, signer::address_of(super_admin)),
            TEST_SUCCESS
        );

        // 2. Test the role not exist
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );

        // check emitted events
        let emitted_events = emitted_events<RoleGranted>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        // Re-authorize the user role already exists
        grant_role(
            super_admin,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );

        // check emitted events
        let emitted_events = emitted_events<RoleGranted>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        // check the address has the role assigned
        assert!(
            has_role(get_pool_admin_role_for_testing(), signer::address_of(test_addr)),
            TEST_SUCCESS
        );
        // check the address has no longer the role assigned
        assert!(
            !has_role(
                get_pool_admin_role_for_testing(), signer::address_of(other_addr)
            ),
            TEST_SUCCESS
        );
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01, other_addr = @0x02)]
    fun test_has_role(
        super_admin: &signer, test_addr: &signer, other_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has no longer the role assigned
        assert!(
            !has_role(
                get_pool_admin_role_for_testing(), signer::address_of(other_addr)
            ),
            TEST_SUCCESS
        );
    }

    // ========== TEST: REVOKE + HAS ROLE ============
    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_revoke_role(super_admin: &signer, test_addr: &signer) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        grant_role(
            super_admin,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(is_pool_admin(signer::address_of(test_addr)), TEST_SUCCESS);

        let role_admin = utf8(b"role_admin");
        // set role admin
        set_role_admin(super_admin, get_pool_admin_role_for_testing(), role_admin);
        // add the asset listing role to some address
        grant_role(super_admin, role_admin, signer::address_of(test_addr));

        // now remove the role by other user and test_addr should have the role
        revoke_role(test_addr, get_pool_admin_role_for_testing(), @0x41);

        // check emitted events
        let emitted_events = emitted_events<RoleRevoked>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 0, TEST_SUCCESS);

        // now remove the role
        revoke_role(
            test_addr,
            get_pool_admin_role_for_testing(),
            signer::address_of(test_addr)
        );

        // check emitted events
        let emitted_events = emitted_events<RoleRevoked>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // check the address has no longer the role assigned
        assert!(
            !has_role(get_pool_admin_role_for_testing(), signer::address_of(test_addr)),
            TEST_SUCCESS
        );
    }

    // ============== SPECIAL FUNCTIONS ============ //
    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_pool_admin(
        super_admin: &signer, test_addr: &signer
    ) {
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
    fun test_add_remove_risk_admin(
        super_admin: &signer, test_addr: &signer
    ) {
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
    fun test_add_remove_funds_admin(
        super_admin: &signer, test_addr: &signer
    ) {
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
        add_emission_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(is_emission_admin(signer::address_of(test_addr)), TEST_SUCCESS);
        // remove pool admin
        remove_emission_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(!is_emission_admin(signer::address_of(test_addr)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_admin_controlled_ecosystem_reserve_funds_admin_role(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_admin_controlled_ecosystem_reserve_funds_admin(
            super_admin, signer::address_of(test_addr)
        );
        // check the address has the role assigned
        assert!(
            is_admin_controlled_ecosystem_reserve_funds_admin(
                signer::address_of(test_addr)
            ),
            TEST_SUCCESS
        );
        // remove pool admin
        remove_admin_controlled_ecosystem_reserve_funds_admin(
            super_admin, signer::address_of(test_addr)
        );
        // check the address has no longer the role assigned
        assert!(
            !is_admin_controlled_ecosystem_reserve_funds_admin(
                signer::address_of(test_addr)
            ),
            TEST_SUCCESS
        );

        let acl_fund_admin = @0x33;
        // set fund admin
        add_admin_controlled_ecosystem_reserve_funds_admin(super_admin, acl_fund_admin);
        // check the address has the role assigned
        assert!(
            is_admin_controlled_ecosystem_reserve_funds_admin(acl_fund_admin),
            TEST_SUCCESS
        );
    }

    #[test(super_admin = @aave_acl, test_addr = @0x01)]
    fun test_add_remove_rewards_controller_admin_role(
        super_admin: &signer, test_addr: &signer
    ) {
        // init the module
        test_init_module(super_admin);
        // add the asset listing role to some address
        add_rewards_controller_admin(super_admin, signer::address_of(test_addr));
        // check the address has the role assigned
        assert!(
            is_rewards_controller_admin(signer::address_of(test_addr)),
            TEST_SUCCESS
        );
        // remove pool admin
        remove_rewards_controller_admin(super_admin, signer::address_of(test_addr));
        // check the address has no longer the role assigned
        assert!(
            !is_rewards_controller_admin(signer::address_of(test_addr)),
            TEST_SUCCESS
        );
    }

    #[test(super_admin = @aave_acl)]
    fun test_roles_initialized(super_admin: &signer) {
        test_init_module(super_admin);
        assert_roles_initialized_for_testing()
    }

    #[test]
    #[expected_failure(abort_code = 1004, location = aave_acl::acl_manage)]
    fun test_roles_not_initialized_expected_failure() {
        assert_roles_initialized_for_testing();
    }

    #[test]
    fun test_default_admin_role() {
        assert!(default_admin_role() == utf8(b"DEFAULT_ADMIN"), TEST_SUCCESS)
    }

    #[test(super_admin = @aave_acl)]
    fun test_get_role_admin(super_admin: &signer) {
        test_init_module(super_admin);
        assert!(
            get_role_admin(get_pool_admin_role_for_testing()) == default_admin_role(),
            TEST_SUCCESS
        );

        let role_admin = utf8(b"role_admin");
        // add role admin
        set_role_admin(super_admin, get_pool_admin_role_for_testing(), role_admin);
        assert!(
            get_role_admin(get_pool_admin_role_for_testing()) == role_admin,
            TEST_SUCCESS
        );
        // update role admin
        set_role_admin(super_admin, get_pool_admin_role_for_testing(), role_admin);
        assert!(
            get_role_admin(get_pool_admin_role_for_testing()) == role_admin,
            TEST_SUCCESS
        )
    }

    #[test(super_admin = @aave_acl, user = @0x01)]
    fun test_renounce_role(super_admin: &signer, user: &signer) {
        test_init_module(super_admin);
        // Define the role as a string
        let role = utf8(b"admin_role");

        // 1. Grant the role to the user account
        grant_role(super_admin, role, signer::address_of(user));
        assert!(has_role(role, signer::address_of(user)), TEST_SUCCESS);

        // 2. Attempt to renounce the role by the correct user
        renounce_role(user, role);

        // check emitted events
        let emitted_events = emitted_events<RoleRevoked>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        assert!(!has_role(role, signer::address_of(user)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, user = @0x01)]
    fun test_renounce_role_not_granted(
        super_admin: &signer, user: &signer
    ) {
        test_init_module(super_admin);
        // Define the role as a string
        let role = utf8(b"admin_role");

        // 1. Grant the role to the user account
        grant_role(super_admin, role, signer::address_of(user));
        assert!(has_role(role, signer::address_of(user)), TEST_SUCCESS);

        // 2. Attempt to renounce a role that is not granted to the caller
        renounce_role(super_admin, role);
        assert!(has_role(role, signer::address_of(user)), TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, user = @0x01)]
    #[expected_failure(abort_code = 1002, location = aave_acl::acl_manage)]
    fun test_only_role_expected_failure(
        super_admin: &signer, user: &signer
    ) {
        test_init_module(super_admin);
        // Define the role as a string
        let role = utf8(b"role");
        let admin_role = utf8(b"admin_role");

        let user_address = signer::address_of(user);
        // 1. Set role admin
        set_role_admin(super_admin, role, admin_role);

        // 2. When super_admin is not set as a role administrator, directly authorize other users
        grant_role(super_admin, role, user_address);
    }

    #[test(super_admin = @aave_acl)]
    fun test_default_admin_role_is_granted_on_module_init(
        super_admin: &signer
    ) {
        test_init_module(super_admin);
        assert!(
            has_role(default_admin_role(), signer::address_of(super_admin)),
            TEST_SUCCESS
        );
    }

    #[test(super_admin = @aave_acl)]
    #[expected_failure(abort_code = 77, location = aave_acl::acl_manage)]
    fun test_grant_role_to_zero_address(super_admin: &signer) {
        // Initialize the module
        test_init_module(super_admin);

        // Create a test role
        let test_role = utf8(b"TEST_ROLE");

        // Try to grant role to zero address (0x0) - revert expected
        grant_role(super_admin, test_role, @0x0);
    }
}
