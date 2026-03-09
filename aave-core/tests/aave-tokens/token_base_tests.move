#[test_only]
module aave_pool::token_base_tests {
    use std::signer;
    use aave_math::wad_ray_math;
    use aave_pool::token_base;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::token_base)]
    fun test_init_module_with_not_pool_owner(user1: &signer) {
        token_base::test_init_module(user1);
    }

    #[test(aave_pool = @aave_pool, caller = @0x41, on_behalf_of = @0x42)]
    #[expected_failure(abort_code = 24, location = aave_pool::token_base)]
    fun test_mint_scaled_when_amount_scaled_equal_zero(
        aave_pool: &signer, caller: &signer, on_behalf_of: &signer
    ) {
        // init token_base module
        token_base::test_init_module(aave_pool);

        let amount_to_mint = 0;
        let a_token_address = @0x11;
        token_base::mint_scaled(
            signer::address_of(caller),
            signer::address_of(on_behalf_of),
            amount_to_mint,
            wad_ray_math::ray(),
            a_token_address,
            false
        );
    }

    #[test(aave_pool = @aave_pool, user = @0x41, target = @0x42)]
    #[expected_failure(abort_code = 25, location = aave_pool::token_base)]
    fun test_burn_scaled_when_amount_scaled_equal_zero(
        aave_pool: &signer, user: &signer, target: &signer
    ) {
        // init token_base module
        token_base::test_init_module(aave_pool);

        let amount_to_burn = 0;
        let a_token_address = @0x11;
        token_base::burn_scaled(
            signer::address_of(user),
            signer::address_of(target),
            amount_to_burn,
            wad_ray_math::ray(),
            a_token_address,
            true
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::token_base)]
    fun test_drop_token_when_token_not_exist(aave_pool: &signer) {
        // init token_base module
        token_base::test_init_module(aave_pool);

        let token_address = @0x11;
        token_base::drop_token(token_address);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::token_base)]
    fun test_assert_managed_fa_exists_when_token_not_exist(
        aave_pool: &signer
    ) {
        // init token_base module
        token_base::test_init_module(aave_pool);

        let token_address = @0x11;
        token_base::assert_managed_fa_exists_for_testing(token_address);
    }
}
