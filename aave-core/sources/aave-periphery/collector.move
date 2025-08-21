/// @title Collector Module
/// @author Aave
/// @notice Implements functionality to manage collected fees in the protocol
module aave_pool::collector {
    // imports
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_pool::pool_token_logic;
    use aave_pool::a_token_factory;

    // Constants
    /// @notice Collector name for resource account creation
    const COLLECTOR_NAME: vector<u8> = b"AAVE_COLLECTOR";

    // Structs
    /// @notice Data structure to store the collector's resource account capability
    struct CollectorData has key {
        resource_account: SignerCapability
    }

    // Module initialization
    /// @notice Initializes the collector module
    /// @dev Creates a resource account and stores its capability
    /// @param sender The signer account that initializes the module (must be pool admin)
    fun init_module(sender: &signer) {
        assert!(
            signer::address_of(sender) == @aave_pool,
            error_config::get_ecaller_not_pool_admin()
        );

        let (_, resource_account) =
            account::create_resource_account(sender, COLLECTOR_NAME);
        move_to(sender, CollectorData { resource_account });
    }

    // Private functions
    /// @notice Checks if the account is a funds admin
    /// @dev Reverts if the account is not a funds admin
    /// @param account The address to check
    fun check_is_funds_admin(account: address) {
        assert!(
            is_funds_admin(account),
            error_config::get_enot_ecosystem_reserve_funds_admin()
        );
    }

    // Public view functions
    #[view]
    /// @notice Checks if an account is a funds admin
    /// @param account The address to check
    /// @return True if the account is a funds admin, false otherwise
    public fun is_funds_admin(account: address): bool {
        acl_manage::is_funds_admin(account)
    }

    #[view]
    /// @notice Returns the address of the collector
    /// @return The address of the collector resource account
    public fun collector_address(): address {
        account::create_resource_address(&@aave_pool, COLLECTOR_NAME)
    }

    #[view]
    /// @notice Gets the amount of collected fees for a specific asset
    /// @param asset The address of the asset to check
    /// @return The amount of collected fees
    public fun get_collected_fees(asset: address): u64 acquires CollectorData {
        // derive resource account signer
        let collector_data = borrow_global<CollectorData>(@aave_pool);
        let resource_address =
            account::get_signer_capability_address(&collector_data.resource_account);

        // check if the asset to withdraw is indeed AToken
        if (!a_token_factory::is_atoken(asset)) {
            return 0;
        };

        // return the balance of the primary store
        primary_fungible_store::balance(
            resource_address, object::address_to_object<Metadata>(asset)
        )
    }

    // Public functions
    /// @notice Withdraws collected fees from the collector
    /// @dev Only callable by funds admin
    /// @param sender The signer account of the caller
    /// @param asset The address of the asset to withdraw
    /// @param receiver The address that will receive the withdrawn assets
    /// @param amount The amount to withdraw
    public entry fun withdraw(
        sender: &signer,
        asset: address,
        receiver: address,
        amount: u64
    ) acquires CollectorData {
        // check sender is the fund admin
        check_is_funds_admin(signer::address_of(sender));

        // derive resource account signer
        let collector_data = borrow_global<CollectorData>(@aave_pool);
        let resource_signer =
            account::create_signer_with_capability(&collector_data.resource_account);

        // check if the asset to withdraw is indeed AToken
        assert!(
            a_token_factory::is_atoken(asset), error_config::get_ecaller_not_atoken()
        );

        // transfer the amount from the collector's primary store to the receiver
        pool_token_logic::transfer(
            &resource_signer,
            receiver,
            (amount as u256),
            asset
        );
    }

    // Test-only functions
    #[test_only]
    /// @notice Initializes the module for testing
    /// @param sender The signer account used to initialize the module
    public fun init_module_test(sender: &signer) {
        init_module(sender);
    }

    #[test_only]
    /// @notice Returns the collector name for testing
    /// @return The name of the collector
    public fun get_collector_name(): vector<u8> {
        COLLECTOR_NAME
    }

    #[test_only]
    /// @notice Returns the collector resource account signer for testing
    public fun get_collector_account_with_signer(): signer acquires CollectorData {
        // derive resource account signer
        let collector_data = borrow_global<CollectorData>(@aave_pool);
        account::create_signer_with_capability(&collector_data.resource_account)
    }
}
