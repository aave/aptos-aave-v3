#[test_only]
module aave_mock_oracle::oracle_sentinel_tests {
    use std::signer;
    use aave_acl::acl_manage::{test_init_module, add_pool_admin, add_asset_listing_admin};
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aptos_framework::timestamp::{fast_forward_seconds};
    use aave_mock_oracle::oracle::test_init_oracle;
    use aave_mock_oracle::oracle_sentinel::{
        is_liquidation_allowed,
        is_borrow_allowed,
        get_grace_period,
        is_up_and_grace_period_passed,
        set_answer,
        set_grace_period,
        latest_round_data
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(aptos_framework = @0x1, super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_sentinel_functionalities(
        aptos_framework: &signer,
        super_admin: &signer,
        oracle_admin: &signer,
        aave_mock_oracle: &signer
    ) {
        // init the acl module
        test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle module incl. the sentinel
        test_init_oracle(aave_mock_oracle);

        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // check initial grace period and latest round data
        assert!(get_grace_period() == 0, TEST_SUCCESS);
        let (_, is_down, _, last_update_timestamp, _) = latest_round_data();
        assert!(is_down == 0, TEST_SUCCESS);
        assert!(last_update_timestamp == 0, TEST_SUCCESS);

        assert!(!is_up_and_grace_period_passed(), TEST_SUCCESS);
        assert!(!is_borrow_allowed(), TEST_SUCCESS);
        assert!(!is_liquidation_allowed(), TEST_SUCCESS);

        // set new grace period
        let grace_period = 1000;

        set_grace_period(oracle_admin, grace_period);

        // assert set grace period
        assert!(get_grace_period() == 1000, TEST_SUCCESS);

        // fast forward grace_period
        fast_forward_seconds(((grace_period + 5) as u64));

        // assert borrow and liquidation are not allowed now
        assert!(is_up_and_grace_period_passed(), TEST_SUCCESS);
        assert!(is_borrow_allowed(), TEST_SUCCESS);
        assert!(is_liquidation_allowed(), TEST_SUCCESS);

        // now mark the oracle as down
        set_answer(oracle_admin, true, 0);
        let (_, is_down, _, _last_update_timestamp, _) = latest_round_data();
        assert!(is_down == 1, TEST_SUCCESS);

        // assert that nothing is currently allowed
        assert!(!is_up_and_grace_period_passed(), TEST_SUCCESS);
        assert!(!is_borrow_allowed(), TEST_SUCCESS);
        assert!(!is_liquidation_allowed(), TEST_SUCCESS);
    }
}
