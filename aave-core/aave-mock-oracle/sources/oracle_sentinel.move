module aave_mock_oracle::oracle_sentinel {
    use std::signer;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aave_acl::acl_manage;
    use aave_config::error as error_config;

    const E_ORACLE_NOT_ADMIN: u64 = 1;
    const E_RESOURCE_NOT_FOUND: u64 = 2;

    #[event]
    struct GracePeriodUpdated has store, drop {
        new_grace_period: u256,
    }

    struct OrcaleSentinel has key, store {
        grace_period: u256,
        is_down: bool,
        timestamp_got_up: u256,
    }

    fun only_oracle_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_mock_oracle, E_ORACLE_NOT_ADMIN);
    }

    fun only_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(acl_manage::is_pool_admin(account_address),
            error_config::get_ecaller_not_pool_admin());
    }

    fun only_risk_or_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(acl_manage::is_pool_admin(account_address) || acl_manage::is_risk_admin(
                account_address),
            error_config::get_ecaller_not_risk_or_pool_admin());
    }

    public fun init_oracle_sentinel(account: &signer) {
        move_to(account,
            OrcaleSentinel { grace_period: 0, is_down: false, timestamp_got_up: 0, })
    }

    fun exists_at(): bool {
        exists<OrcaleSentinel>(@aave_mock_oracle)
    }

    public entry fun set_answer(account: &signer, is_down: bool, timestamp: u256) acquires OrcaleSentinel {
        only_risk_or_pool_admin(account);
        assert!(exists_at(), E_RESOURCE_NOT_FOUND);
        let oracle_sentinel = borrow_global_mut<OrcaleSentinel>(@aave_mock_oracle);
        oracle_sentinel.is_down = is_down;
        oracle_sentinel.timestamp_got_up = timestamp;
    }

    #[view]
    public fun latest_round_data(): (u128, u256, u256, u256, u128) acquires OrcaleSentinel {
        assert!(exists_at(), E_RESOURCE_NOT_FOUND);
        let is_down = 0;
        let oracle_sentinel = borrow_global<OrcaleSentinel>(@aave_mock_oracle);
        if (oracle_sentinel.is_down) {
            is_down = 1;
        };
        (0, is_down, 0, oracle_sentinel.timestamp_got_up, 0)
    }

    #[view]
    public fun is_borrow_allowed(): bool acquires OrcaleSentinel {
        is_up_and_grace_period_passed()
    }

    #[view]
    public fun is_liquidation_allowed(): bool acquires OrcaleSentinel {
        is_up_and_grace_period_passed()
    }

    #[view]
    public fun is_up_and_grace_period_passed(): bool acquires OrcaleSentinel {
        let (_, answer, _, last_update_timestamp, _) = latest_round_data();
        answer == 0 && (timestamp::now_seconds() as u256) - last_update_timestamp > get_grace_period()
    }

    public entry fun set_grace_period(account: &signer, new_grace_period: u256) acquires OrcaleSentinel {
        only_risk_or_pool_admin(account);
        assert!(exists_at(), E_RESOURCE_NOT_FOUND);
        let oracle_sentinel = borrow_global_mut<OrcaleSentinel>(@aave_mock_oracle);
        oracle_sentinel.grace_period = new_grace_period;
        event::emit(GracePeriodUpdated { new_grace_period });
    }

    #[view]
    public fun get_grace_period(): u256 acquires OrcaleSentinel {
        assert!(exists_at(), E_RESOURCE_NOT_FOUND);
        let oracle_sentinel = borrow_global<OrcaleSentinel>(@aave_mock_oracle);
        oracle_sentinel.grace_period
    }
}