#[test_only]
module aave_pool::fee_manager_tests {
    use std::signer;
    use std::vector;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::aptos_coin_tests;
    use aptos_framework::coin;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_pool::pool_fee_manager;

    /// Default apt fee 0 APT
    const DEFAULT_APT_FEE: u64 = 0;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(account = @0x33)]
    #[expected_failure(abort_code = 1401, location = aave_pool::pool_fee_manager)]
    fun test_init_module(account: &signer) {
        pool_fee_manager::init_module_for_testing(account);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    fun test_set_apt_fee(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);
        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);
        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);

        // Set the pool admin for the aave_pool
        acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));

        // Set a new fee
        let new_apt_fee = 10_000_000;
        pool_fee_manager::set_apt_fee(aave_pool, underlying_token, new_apt_fee);

        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == new_apt_fee, TEST_SUCCESS);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    fun test_collect_apt_fee(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);

        // Set the pool admin for the aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::add_pool_admin(aave_acl, aave_pool_address);

        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);
        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);
        let fee_collector_apt_balance = pool_fee_manager::get_fee_collector_apt_balance();
        assert!(fee_collector_apt_balance == 0, TEST_SUCCESS);

        // Case-1: For the first fee collection, test whether the resource account receives a certain amount of APT.
        // Mint 1 APT coins to the aave_pool
        let mint_amount = 100000000;
        aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            aave_pool_address, mint_amount
        );
        // Check if the aave_pool has the minted coins
        assert!(coin::balance<AptosCoin>(aave_pool_address) == mint_amount, TEST_SUCCESS);
        // Get the resource account address
        let resource_acc_addr = pool_fee_manager::get_fee_collector_address();
        // Check if the resource account has 0 APT coins
        assert!(coin::balance<AptosCoin>(resource_acc_addr) == 0, TEST_SUCCESS);

        // Set apt fee is 0.02 APT
        let new_apt_fee = 2_000_000; // 0.02 APT
        pool_fee_manager::set_apt_fee(aave_pool, underlying_token, new_apt_fee);

        // First Collect fees
        pool_fee_manager::collect_apt_fee(aave_pool, underlying_token);

        // Check if the aave_pool_address has the APT fee is mint_amount - new_apt_fee
        assert!(
            coin::balance<AptosCoin>(aave_pool_address) == mint_amount - new_apt_fee,
            TEST_SUCCESS
        );
        // Check if the resource account has the APT fee
        assert!(coin::balance<AptosCoin>(resource_acc_addr) == new_apt_fee, TEST_SUCCESS);

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == (new_apt_fee as u128), TEST_SUCCESS);

        // Case-2: For the second fee collection, test whether total fees are accumulated.
        // Second Collect fees
        pool_fee_manager::collect_apt_fee(aave_pool, underlying_token);
        // Check if the aave_pool_address has the APT fee is mint_amount - 2 * new_apt_fee
        assert!(
            coin::balance<AptosCoin>(aave_pool_address)
                == mint_amount - 2 * new_apt_fee,
            TEST_SUCCESS
        );
        // Check if the resource account has the APT fee
        assert!(
            coin::balance<AptosCoin>(resource_acc_addr) == 2 * new_apt_fee,
            TEST_SUCCESS
        );
        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(
            apt_total_fee == (2 * new_apt_fee as u128), TEST_SUCCESS
        );

        // Case-3: The third charge tests whether the total fees decrease after the charged resource account is transferred
        // Transfer apt fee
        let aave_acl_address = signer::address_of(aave_acl);
        let transfer_amount = 2_000_000; // 0.02 APT
        pool_fee_manager::withdraw_apt_fee(
            aave_pool, aave_acl_address, (transfer_amount as u128)
        );

        // Check if the aave_pool_address has the APT fee is mint_amount - 2 * new_apt_fee
        assert!(
            coin::balance<AptosCoin>(aave_pool_address)
                == mint_amount - 2 * new_apt_fee,
            TEST_SUCCESS
        );
        // Check if the resource account has the APT fee
        assert!(
            coin::balance<AptosCoin>(resource_acc_addr)
                == 2 * new_apt_fee - transfer_amount,
            TEST_SUCCESS
        );

        // Check if the aave_acl_address has the APT fee
        assert!(
            coin::balance<AptosCoin>(aave_acl_address) == transfer_amount,
            TEST_SUCCESS
        );

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(
            apt_total_fee == (2 * new_apt_fee as u128), TEST_SUCCESS
        );

        // Set apt fee is 0.01 APT again
        let new_apt_fee = 1_000_000; // 0.01 APT
        pool_fee_manager::set_apt_fee(aave_pool, underlying_token, new_apt_fee);
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == new_apt_fee, TEST_SUCCESS);

        // check emitted events
        let emitted_events = emitted_events<pool_fee_manager::FeeChanged>();
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    fun test_withdraw_apt_fee(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);

        let aave_pool_address = signer::address_of(aave_pool);
        // Set the pool admin for the aave_pool
        acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));

        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);

        let (burn_cap, mint_cap) =
            aptos_framework::aptos_coin::initialize_for_test(aave_std);
        let resource_acc_addr = pool_fee_manager::get_fee_collector_address();

        let mint_amount = 10000000;
        aptos_account::deposit_coins(
            resource_acc_addr, coin::mint(mint_amount, &mint_cap)
        );
        assert!(
            coin::is_account_registered<AptosCoin>(resource_acc_addr),
            TEST_SUCCESS
        );

        // transfer apt fee
        pool_fee_manager::withdraw_apt_fee(
            aave_pool, aave_pool_address, ((mint_amount - 2000) as u128)
        );

        assert!(coin::balance<AptosCoin>(resource_acc_addr) == 2000, TEST_SUCCESS);
        assert!(
            coin::balance<AptosCoin>(aave_pool_address) == mint_amount - 2000,
            TEST_SUCCESS
        );

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    // -------------------------------- Test exceptions --------------------------------
    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 1503, location = aave_pool::pool_fee_manager)]
    fun test_set_apt_fee_with_fee_config_not_initialized(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        let underlying_token = @0x33;
        // Set a new fee
        let new_apt_fee = 1000000;
        pool_fee_manager::set_apt_fee(aave_pool, underlying_token, new_apt_fee);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 1410, location = aave_pool::pool_fee_manager)]
    fun test_set_apt_fee_with_invalid_max_apt_fee(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);
        // Set the pool admin for the aave_pool
        acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));

        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);

        // Set a new fee 11 APT
        let new_apt_fee = 1100000000;
        pool_fee_manager::set_apt_fee(aave_pool, underlying_token, new_apt_fee);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 1503, location = aave_pool::pool_fee_manager)]
    fun test_collect_apt_fee_with_fee_config_not_initialized(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);

        pool_fee_manager::collect_apt_fee(aave_pool, @0x32);
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 1503, location = aave_pool::pool_fee_manager)]
    fun test_withdraw_apt_fee_with_fee_config_not_initialized(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);

        // Set a new fee
        let new_apt_fee = 1000000;
        pool_fee_manager::withdraw_apt_fee(
            aave_pool, signer::address_of(aave_acl), new_apt_fee
        );
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 1, location = aave_pool::pool_fee_manager)]
    fun test_withdraw_apt_fee_with_caller_not_pool_admin(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);

        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);

        // Set a new fee
        let new_apt_fee = 10_000_000;
        pool_fee_manager::withdraw_apt_fee(
            aave_pool, signer::address_of(aave_acl), new_apt_fee
        );
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl, aave_std = @std)]
    #[expected_failure(abort_code = 26, location = aave_pool::pool_fee_manager)]
    fun test_withdraw_apt_fee_with_invalid_amount(
        aave_pool: &signer, aave_acl: &signer, aave_std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init acl
        acl_manage::test_init_module(aave_acl);
        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);
        // Set the pool admin for the aave_pool
        acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));

        let underlying_token = @0x33;
        let apt_fee = pool_fee_manager::get_apt_fee(underlying_token);
        assert!(apt_fee == DEFAULT_APT_FEE, TEST_SUCCESS);

        let apt_total_fee = pool_fee_manager::get_total_fees();
        assert!(apt_total_fee == 0, TEST_SUCCESS);

        // Set a new fee
        let new_apt_fee = 0;
        pool_fee_manager::withdraw_apt_fee(
            aave_pool, signer::address_of(aave_acl), new_apt_fee
        );
    }

    #[test]
    #[expected_failure(abort_code = 1503, location = aave_pool::pool_fee_manager)]
    fun test_assert_fee_config_exists_with_fee_config_not_initialized() {
        pool_fee_manager::assert_fee_config_exists_for_testing();
    }
}
