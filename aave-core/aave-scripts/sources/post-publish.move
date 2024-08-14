script {
    // std
    use std::debug::{Self};
    use std::string_utils::{Self};
    // locals
    use aave_pool::pool_addresses_provider::{Self};

    fun init_pool_addresses_provider(account: &signer) {
        pool_addresses_provider::set_acl_admin(account, @aave_acl);
        debug::print(
            &string_utils::format1(&b">>>> Acl Admin set at address: {}", @aave_acl)
        );
        pool_addresses_provider::set_acl_manager(account, @aave_acl);
        debug::print(
            &string_utils::format1(&b">>>> Acl Manager set at address: {}", @aave_acl)
        );
        pool_addresses_provider::set_pool_configurator(account, @aave_pool);
        debug::print(
            &string_utils::format1(
                &b">>>> Pool Configurator set at address: {}", @aave_pool
            )
        );
        pool_addresses_provider::set_pool_data_provider(account, @aave_pool);
        debug::print(
            &string_utils::format1(
                &b">>>> Pool Data Provider set at address: {}", @aave_pool
            )
        );
        pool_addresses_provider::set_pool_impl(account, @aave_pool);
        debug::print(
            &string_utils::format1(
                &b">>>> Pool Implementation set at address: {}", @aave_pool
            ),
        );
        pool_addresses_provider::set_price_oracle(account, @aave_mock_oracle);
        debug::print(
            &string_utils::format1(
                &b">>>> Mock Oracle set at address: {}", @aave_mock_oracle
            )
        );
        pool_addresses_provider::set_price_oracle_sentinel(account, @aave_mock_oracle);
        debug::print(
            &string_utils::format1(
                &b">>>> Mock Oracle Sentinel set at address: {}", @aave_mock_oracle
            ),
        );
    }
}
