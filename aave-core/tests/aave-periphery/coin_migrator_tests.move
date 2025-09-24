#[test_only]
module aave_pool::coin_migrator_tests {
    use std::signer;
    use std::option;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::account::{Self};
    use aptos_framework::coin::{Self};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::dispatchable_fungible_asset::Self;
    use aptos_framework::aggregator_factory::initialize_aggregator_factory_for_test;
    use aptos_framework::event::emitted_events;
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use aave_pool::coin_migrator::{Self, CoinToFaConvertion};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    struct GenericAptosCoin {}

    struct GenericAptosCoinRefs has key {
        burn_ref: coin::BurnCapability<GenericAptosCoin>,
        freeze_ref: coin::FreezeCapability<GenericAptosCoin>,
        mint_ref: coin::MintCapability<GenericAptosCoin>
    }

    public fun initialize_aptos_coin(
        framework: &signer,
        coin_creator: &signer,
        decimals: u8,
        monitor_supply: bool,
        coin_name: String,
        coin_symbol: String
    ) {
        initialize_aggregator_factory_for_test(framework);

        let (burn_ref, freeze_ref, mint_ref) =
            coin::initialize<GenericAptosCoin>(
                coin_creator,
                coin_name,
                coin_symbol,
                decimals,
                monitor_supply
            );
        move_to(
            coin_creator,
            GenericAptosCoinRefs { burn_ref, freeze_ref, mint_ref }
        );
    }

    inline fun get_coin_refs(account: &signer): &GenericAptosCoinRefs {
        borrow_global<GenericAptosCoinRefs>(signer::address_of(account))
    }

    #[
        test(
            framework = @aptos_framework,
            aave_pool = @aave_pool,
            alice = @0x123,
            bob = @0x234
        )
    ]
    fun test_coin_fa_conversion(
        framework: &signer,
        aave_pool: &signer,
        alice: &signer,
        bob: &signer
    ) acquires GenericAptosCoinRefs {
        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        // create test accounts
        account::create_account_for_test(signer::address_of(alice));
        account::create_account_for_test(signer::address_of(bob));

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 2;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // register the alice and bob
        coin::register<GenericAptosCoin>(alice);
        coin::register<GenericAptosCoin>(bob);

        // mint some coins
        let alice_init_balance = 100;
        let coins_minted =
            coin::mint<GenericAptosCoin>(
                alice_init_balance, &get_coin_refs(aave_pool).mint_ref
            );

        // deposit to alice
        coin::deposit(signer::address_of(alice), coins_minted);

        // now alice withdraws
        let withdrawn_amount = 10;
        let coin_to_wrap = coin::withdraw<GenericAptosCoin>(alice, withdrawn_amount);
        assert!(coin::value(&coin_to_wrap) == withdrawn_amount, TEST_SUCCESS);
        // assert Alice balance: before we have converted the coins to fa, the coins balance is correctly displayed
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(alice))
                == alice_init_balance - withdrawn_amount,
            TEST_SUCCESS
        );

        // ...and converts the coins into a fa
        let wrapped_fa = coin::coin_to_fungible_asset<GenericAptosCoin>(coin_to_wrap);
        assert!(fungible_asset::amount(&wrapped_fa) == withdrawn_amount, TEST_SUCCESS);

        // get the metadata needed for the new fa, do assertions
        let wrapped_fa_meta =
            option::destroy_some(coin::paired_metadata<GenericAptosCoin>());
        let wrapped_fa_meta2 = fungible_asset::metadata_from_asset(&wrapped_fa);
        assert!(wrapped_fa_meta == wrapped_fa_meta2, TEST_SUCCESS);
        let fa_supply = fungible_asset::supply(wrapped_fa_meta);
        let fa_decimals = fungible_asset::decimals(wrapped_fa_meta);
        let fa_symbol = fungible_asset::symbol(wrapped_fa_meta);
        let fa_name = fungible_asset::name(wrapped_fa_meta);
        assert!(fa_supply == option::some((alice_init_balance as u128)), TEST_SUCCESS); // fa and coin are the same

        assert!(fa_decimals == coin_decimals, TEST_SUCCESS);
        assert!(fa_symbol == coin_symbol, TEST_SUCCESS);
        assert!(fa_name == coin_name, TEST_SUCCESS);

        // get data for alice and bob wallet for the FungibleAsset
        let alice_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(alice), wrapped_fa_meta
            );
        let bob_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(bob), wrapped_fa_meta
            );

        // deposit the wrapped FungibleAsset into Alice wallet
        dispatchable_fungible_asset::deposit(alice_wallet, wrapped_fa);

        // assert alice has both equal balances of coins and the converted fas as they are the same
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(alice))
                == alice_init_balance,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(alice_wallet)
                == alice_init_balance,
            TEST_SUCCESS
        );

        // move 1 fa from Alice to bob wallet
        let transfer_amount = 1;
        fungible_asset::transfer(
            alice,
            alice_wallet,
            bob_wallet,
            transfer_amount
        );

        // assert alice has both 99 coins and 9 fa
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(alice))
                == alice_init_balance - transfer_amount,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(alice_wallet)
                == alice_init_balance - transfer_amount,
            TEST_SUCCESS
        );

        // assert bob has both 1 coin and 1 fa as they are the same here
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(bob)) == transfer_amount,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(bob_wallet) == transfer_amount,
            TEST_SUCCESS
        );

        // now bob transfers his 1 fa
        fungible_asset::transfer(bob, bob_wallet, alice_wallet, 1);
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(bob)) == 0,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(bob_wallet) == 0, TEST_SUCCESS
        );
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(alice))
                == alice_init_balance,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(alice_wallet)
                == alice_init_balance,
            TEST_SUCCESS
        );
    }

    #[
        test(
            framework = @aptos_framework,
            aave_pool = @aave_pool,
            alice = @0x123,
            bob = @0x234
        )
    ]
    fun test_coin_migrator(
        framework: &signer,
        aave_pool: &signer,
        alice: &signer,
        bob: &signer
    ) acquires GenericAptosCoinRefs {

        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        // create test accounts
        account::create_account_for_test(signer::address_of(alice));
        account::create_account_for_test(signer::address_of(bob));

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 2;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // register the alice and bob
        coin::register<GenericAptosCoin>(alice);
        coin::register<GenericAptosCoin>(bob);

        // mint some coins
        let alice_init_balance = 100;
        let coins_minted =
            coin::mint<GenericAptosCoin>(
                alice_init_balance, &get_coin_refs(aave_pool).mint_ref
            );

        // deposit to alice
        coin::deposit(signer::address_of(alice), coins_minted);

        // Alice converts her coins for fas
        coin_migrator::coin_to_fa<GenericAptosCoin>(alice, alice_init_balance / 2);
        coin_migrator::coin_to_fa<GenericAptosCoin>(alice, alice_init_balance / 2);

        // check CointToFaConvertion emitted events
        let emitted_events = emitted_events<CoinToFaConvertion>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        // use coin migrator to obtain the fa address
        let fa_address = coin_migrator::get_fa_address<GenericAptosCoin>();

        // get metadata and alice fung. asset store
        let wrapped_fa_meta = object::address_to_object<Metadata>(fa_address);
        let alice_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(alice), wrapped_fa_meta
            );

        // assert
        assert!(
            coin::balance<GenericAptosCoin>(signer::address_of(alice))
                == alice_init_balance,
            TEST_SUCCESS
        );
        assert!(
            dispatchable_fungible_asset::derived_balance(alice_wallet)
                == alice_init_balance,
            TEST_SUCCESS
        );
    }

    #[
        test(
            framework = @aptos_framework,
            aave_pool = @aave_pool,
            alice = @0x123,
            bob = @0x234
        )
    ]
    #[expected_failure(abort_code = 1415, location = aave_pool::coin_migrator)]
    fun test_coin_to_fa_when_insufficient_coins_to_wrap(
        framework: &signer,
        aave_pool: &signer,
        alice: &signer,
        bob: &signer
    ) acquires GenericAptosCoinRefs {
        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        // create test accounts
        account::create_account_for_test(signer::address_of(alice));
        account::create_account_for_test(signer::address_of(bob));

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 2;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // register the alice and bob
        coin::register<GenericAptosCoin>(alice);
        coin::register<GenericAptosCoin>(bob);

        // mint some coins
        let alice_init_balance = 100;
        let coins_minted =
            coin::mint<GenericAptosCoin>(
                alice_init_balance, &get_coin_refs(aave_pool).mint_ref
            );

        // deposit to alice
        coin::deposit(signer::address_of(alice), coins_minted);

        // Alice tries to convert more coins than she has
        coin_migrator::coin_to_fa<GenericAptosCoin>(alice, alice_init_balance + 1);
    }

    #[test(framework = @aptos_framework, aave_pool = @aave_pool, alice = @0x123)]
    #[expected_failure(abort_code = 1415, location = aave_pool::coin_migrator)]
    fun test_coin_to_fa_when_coin_balance_is_zero_to_wrap(
        framework: &signer, aave_pool: &signer, alice: &signer
    ) {
        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        let alice_address = signer::address_of(alice);
        // create test accounts
        account::create_account_for_test(alice_address);

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 4;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // register the alice
        coin::register<GenericAptosCoin>(alice);

        // no mint
        let alice_balance = coin::balance<GenericAptosCoin>(alice_address);
        assert!(alice_balance == 0, TEST_SUCCESS);

        // Alice tries to convert coins
        let alice_init_balance = 100;
        coin_migrator::coin_to_fa<GenericAptosCoin>(alice, alice_init_balance);
    }

    #[test(framework = @aptos_framework, aave_pool = @aave_pool, alice = @0x123)]
    fun test_fa_to_coin_migration(
        framework: &signer, aave_pool: &signer, alice: &signer
    ) acquires GenericAptosCoinRefs {
        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        let alice_address = signer::address_of(alice);
        // create test accounts
        account::create_account_for_test(alice_address);

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 4;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // register the alice
        coin::register<GenericAptosCoin>(alice);

        // mint some coins
        let alice_init_balance = 100;
        let coins_minted =
            coin::mint<GenericAptosCoin>(
                alice_init_balance, &get_coin_refs(aave_pool).mint_ref
            );

        // deposit to alice
        coin::deposit(alice_address, coins_minted);

        // Alice converts her coins for fas
        coin_migrator::coin_to_fa<GenericAptosCoin>(alice, alice_init_balance);

        // use coin migrator to obtain the fa address
        let fa_address = coin_migrator::get_fa_address<GenericAptosCoin>();

        // get metadata and alice fung. asset store
        let wrapped_fa_meta = object::address_to_object<Metadata>(fa_address);
        let alice_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                alice_address, wrapped_fa_meta
            );
        let alice_fa_balance = dispatchable_fungible_asset::derived_balance(alice_wallet);
        assert!(alice_fa_balance == alice_init_balance, TEST_SUCCESS);
    }

    #[test(framework = @aptos_framework, aave_pool = @aave_pool, alice = @0x123)]
    #[expected_failure(abort_code = 1417, location = aave_pool::coin_migrator)]
    fun test_get_fa_address_when_unmapped_coin_to_fa(
        framework: &signer, aave_pool: &signer, alice: &signer
    ) {
        // init a coin conversion map
        coin::create_coin_conversion_map(framework);

        let alice_address = signer::address_of(alice);
        // create test accounts
        account::create_account_for_test(alice_address);

        // initialize old-style aptos coin
        let coin_name = string::utf8(b"Generic Coin");
        let coin_symbol = string::utf8(b"GCC");
        let coin_decimals = 6;

        initialize_aptos_coin(
            framework,
            aave_pool,
            coin_decimals,
            true,
            coin_name,
            coin_symbol
        );

        // Alice tries to get the fa address for an unmapped coin
        coin_migrator::get_fa_address<GenericAptosCoin>();
    }
}
