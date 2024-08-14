module aave_mock_oracle::oracle {

    use std::signer;
    use std::vector;
    use std::option::{Self, Option};
    use aptos_std::simple_map;
    use aptos_framework::event;
    use aave_mock_oracle::oracle_sentinel;

    const E_ORACLE_NOT_ADMIN: u64 = 1;
    const E_ASSET_ALREADY_EXISTS: u64 = 2;
    const E_ASSET_NOT_EXISTS: u64 = 3;

    #[event]
    struct OracleEvent has store, drop {
        asset: address,
        price: u256,
    }

    struct AssetPriceList has key {
        value: simple_map::SimpleMap<address, u256>,
    }

    struct RewardOracle has key, store, drop, copy {
        id: u256,
    }

    public fun create_reward_oracle(id: u256): RewardOracle {
        // TODO
        RewardOracle { id }
    }

    public fun decimals(_reward_oracle: RewardOracle): u8 {
        // TODO
        0
    }

    public fun latest_answer(_reward_oracle: RewardOracle): u256 {
        1
    }

    public fun latest_timestamp(_reward_oracle: RewardOracle): u256 {
        // TODO
        0
    }

    public fun latest_round(_reward_oracle: RewardOracle): u256 {
        // TODO
        0
    }

    public fun get_answer(_reward_oracle: RewardOracle, _round_id: u256): u256 {
        // TODO
        0
    }

    public fun get_timestamp(
        _reward_oracle: RewardOracle, _round_id: u256
    ): u256 {
        // TODO
        0
    }

    public fun base_currency_unit(
        _reward_oracle: RewardOracle, _round_id: u256
    ): u64 {
        // TODO
        0
    }

    fun only_oracle_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_mock_oracle, E_ORACLE_NOT_ADMIN);
    }

    #[test_only]
    public fun test_init_oracle(account: &signer) {
        init_module(account);
    }

    fun init_module(account: &signer) {
        only_oracle_admin(account);
        oracle_sentinel::init_oracle_sentinel(account);
        move_to(account, AssetPriceList { value: simple_map::new() })
    }

    #[view]
    public fun get_asset_price(asset: address): u256 acquires AssetPriceList {
        let asset_price_list = borrow_global<AssetPriceList>(@aave_mock_oracle);
        if (!simple_map::contains_key(&asset_price_list.value, &asset)) {
            return 0
        };
        *simple_map::borrow(&asset_price_list.value, &asset)
    }

    public fun get_base_currency_unit(): Option<u256> {
        option::none()
    }

    public entry fun set_asset_price(
        account: &signer, asset: address, price: u256
    ) acquires AssetPriceList {
        only_oracle_admin(account);
        let asset_price_list = borrow_global_mut<AssetPriceList>(@aave_mock_oracle);
        simple_map::upsert(&mut asset_price_list.value, asset, price);
        event::emit(OracleEvent { asset, price })
    }

    public entry fun batch_set_asset_price(
        account: &signer, assets: vector<address>, prices: vector<u256>
    ) acquires AssetPriceList {
        only_oracle_admin(account);
        let asset_price_list = borrow_global_mut<AssetPriceList>(@aave_mock_oracle);
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let price = *vector::borrow(&prices, i);
            simple_map::upsert(&mut asset_price_list.value, asset, price);
            event::emit(OracleEvent { asset, price });
        };
    }

    public entry fun update_asset_price(
        account: &signer, asset: address, price: u256
    ) acquires AssetPriceList {
        only_oracle_admin(account);
        let asset_price_list = borrow_global_mut<AssetPriceList>(@aave_mock_oracle);
        assert!(
            simple_map::contains_key(&asset_price_list.value, &asset), E_ASSET_NOT_EXISTS
        );
        simple_map::upsert(&mut asset_price_list.value, asset, price);
        event::emit(OracleEvent { asset, price })
    }

    public entry fun remove_asset_price(account: &signer, asset: address) acquires AssetPriceList {
        only_oracle_admin(account);
        let asset_price_list = borrow_global_mut<AssetPriceList>(@aave_mock_oracle);
        assert!(
            simple_map::contains_key(&asset_price_list.value, &asset), E_ASSET_NOT_EXISTS
        );
        let price = *simple_map::borrow(&asset_price_list.value, &asset);
        simple_map::remove(&mut asset_price_list.value, &asset);
        event::emit(OracleEvent { asset, price })
    }
}
