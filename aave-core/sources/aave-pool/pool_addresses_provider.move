module aave_pool::pool_addresses_provider {
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;

    const POOL: vector<u8> = b"POOL";
    const POOL_CONFIGURATOR: vector<u8> = b"POOL_CONFIGURATOR";
    const PRICE_ORACLE: vector<u8> = b"PRICE_ORACLE";
    const ACL_MANAGER: vector<u8> = b"ACL_MANAGER";
    const ACL_ADMIN: vector<u8> = b"ACL_ADMIN";
    const PRICE_ORACLE_SENTINEL: vector<u8> = b"PRICE_ORACLE_SENTINEL";
    const DATA_PROVIDER: vector<u8> = b"DATA_PROVIDER";

    // You are not an administrator and cannot change resources.
    const ENOT_MANAGEMENT: u64 = 1;
    // Id already exists.
    const EID_ALREADY_EXISTS: u64 = 2;
    // Id does not exist.
    const EID_NOT_EXISTS: u64 = 3;

    #[event]
    struct MarketIdSet has store, drop {
        old_market_id: Option<String>,
        new_market_id: String,
    }

    #[event]
    struct PoolUpdated has store, drop {
        old_pool_impl: Option<address>,
        new_pool_impl: address,
    }

    #[event]
    struct PoolConfiguratorUpdated has store, drop {
        old_pool_configurator_impl: Option<address>,
        new_pool_configurator_impl: address,
    }

    #[event]
    struct PriceOracleUpdated has store, drop {
        old_price_oracle_impl: Option<address>,
        new_price_oracle_impl: address,
    }

    #[event]
    struct ACLManagerUpdated has store, drop {
        old_acl_manager_impl: Option<address>,
        new_acl_manager_impl: address,
    }

    #[event]
    struct ACLAdminUpdated has store, drop {
        old_acl_admin_impl: Option<address>,
        new_acl_admin_impl: address,
    }

    #[event]
    struct PriceOracleSentinelUpdated has store, drop {
        old_price_oracle_sentinel_impl: Option<address>,
        new_price_oracle_sentinel_impl: address,
    }

    #[event]
    struct PoolDataProviderUpdated has store, drop {
        old_pool_data_provider_impl: Option<address>,
        new_pool_data_provider_impl: address,
    }

    struct Provider has key, store {
        market_id: Option<String>,
        addresses: SmartTable<String, address>
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        init_module(account)
    }

    fun init_module(account: &signer) {
        assert!(signer::address_of(account) == @aave_pool, ENOT_MANAGEMENT);
        move_to(
            account,
            Provider {
                market_id: option::none(),
                addresses: smart_table::new<String, address>()
            },
        )
    }

    fun check_admin(account: address) {
        assert!(account == @aave_acl, ENOT_MANAGEMENT);
    }

    fun update_impl(id: String, new_pool_impl: address) acquires Provider {
        let provider = borrow_global_mut<Provider>(@aave_pool);
        smart_table::upsert(&mut provider.addresses, id, new_pool_impl);
    }

    #[view]
    public fun has_id_mapped_account(id: String): bool acquires Provider {
        let provider = borrow_global_mut<Provider>(@aave_pool);
        if (!smart_table::contains(&provider.addresses, id)) {
            return false
        };
        true
    }

    #[view]
    public fun get_market_id(): Option<String> acquires Provider {
        let provider = borrow_global<Provider>(@aave_pool);
        provider.market_id
    }

    public entry fun set_market_id(account: &signer, new_market_id: String) acquires Provider {
        check_admin(signer::address_of(account));
        let provider = borrow_global_mut<Provider>(@aave_pool);
        let old_market_id = provider.market_id;
        provider.market_id = option::some(new_market_id);
        event::emit(MarketIdSet { old_market_id, new_market_id, });
    }

    #[view]
    public fun get_address(id: String): Option<address> acquires Provider {
        if (!has_id_mapped_account(id)) {
            return option::none<address>()
        };
        let provider = borrow_global_mut<Provider>(@aave_pool);
        let address = smart_table::borrow(&mut provider.addresses, id);
        option::some(*address)
    }

    public entry fun set_address(
        account: &signer, id: String, addr: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let provider = borrow_global_mut<Provider>(@aave_pool);
        smart_table::upsert(&mut provider.addresses, id, addr);
    }

    #[view]
    public fun get_pool(): Option<address> acquires Provider {
        get_address(string::utf8(POOL))
    }

    public entry fun set_pool_impl(
        account: &signer, new_pool_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_pool_impl = get_address(string::utf8(POOL));
        update_impl(string::utf8(POOL), new_pool_impl);
        event::emit(PoolUpdated { old_pool_impl, new_pool_impl });
    }

    #[view]
    public fun get_pool_configurator(): Option<address> acquires Provider {
        get_address(string::utf8(POOL_CONFIGURATOR))
    }

    public entry fun set_pool_configurator(
        account: &signer, new_pool_configurator_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_pool_configurator_impl = get_address(string::utf8(POOL_CONFIGURATOR));
        update_impl(string::utf8(POOL_CONFIGURATOR), new_pool_configurator_impl);
        event::emit(
            PoolConfiguratorUpdated {
                old_pool_configurator_impl,
                new_pool_configurator_impl
            },
        );
    }

    #[view]
    public fun get_price_oracle(): Option<address> acquires Provider {
        get_address(string::utf8(PRICE_ORACLE))
    }

    public entry fun set_price_oracle(
        account: &signer, new_price_oracle_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_price_oracle_impl = get_address(string::utf8(PRICE_ORACLE));
        update_impl(string::utf8(PRICE_ORACLE), new_price_oracle_impl);
        event::emit(PriceOracleUpdated { old_price_oracle_impl, new_price_oracle_impl });
    }

    #[view]
    public fun get_acl_manager(): Option<address> acquires Provider {
        get_address(string::utf8(ACL_MANAGER))
    }

    public entry fun set_acl_manager(
        account: &signer, new_acl_manager_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_acl_manager_impl = get_address(string::utf8(ACL_MANAGER));
        update_impl(string::utf8(ACL_MANAGER), new_acl_manager_impl);
        event::emit(ACLManagerUpdated { old_acl_manager_impl, new_acl_manager_impl });
    }

    #[view]
    public fun get_acl_admin(): Option<address> acquires Provider {
        get_address(string::utf8(ACL_ADMIN))
    }

    public entry fun set_acl_admin(
        account: &signer, new_acl_admin_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_acl_admin_impl = get_address(string::utf8(ACL_ADMIN));
        update_impl(string::utf8(ACL_ADMIN), new_acl_admin_impl);
        event::emit(ACLAdminUpdated { old_acl_admin_impl, new_acl_admin_impl });
    }

    #[view]
    public fun get_price_oracle_sentinel(): Option<address> acquires Provider {
        get_address(string::utf8(PRICE_ORACLE_SENTINEL))
    }

    public entry fun set_price_oracle_sentinel(
        account: &signer, new_price_oracle_sentinel_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_price_oracle_sentinel_impl =
            get_address(string::utf8(PRICE_ORACLE_SENTINEL));
        update_impl(string::utf8(PRICE_ORACLE_SENTINEL), new_price_oracle_sentinel_impl);
        event::emit(
            PriceOracleSentinelUpdated {
                old_price_oracle_sentinel_impl,
                new_price_oracle_sentinel_impl
            },
        );
    }

    #[view]
    public fun get_pool_data_provider(): Option<address> acquires Provider {
        get_address(string::utf8(DATA_PROVIDER))
    }

    public entry fun set_pool_data_provider(
        account: &signer, new_pool_data_provider_impl: address
    ) acquires Provider {
        check_admin(signer::address_of(account));
        let old_pool_data_provider_impl = get_address(string::utf8(DATA_PROVIDER));
        update_impl(string::utf8(DATA_PROVIDER), new_pool_data_provider_impl);
        event::emit(
            PoolDataProviderUpdated {
                old_pool_data_provider_impl,
                new_pool_data_provider_impl
            },
        );
    }
}
