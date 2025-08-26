/// @title Fee Manager Module
/// @author Aave
/// @notice A fee module to add/manage a txn fee to mitigate the rounding error of integer arithmetic
module aave_pool::pool_fee_manager {
    // imports
    use std::signer;
    use aptos_std::event;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;
    use aptos_framework::object;

    use aave_acl::acl_manage;
    use aave_config::error_config;

    // friend modules
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::flashloan_logic;
    friend aave_pool::pool_configurator;

    #[test_only]
    friend aave_pool::fee_manager_tests;

    // Constants
    /// @notice Default apt fee 0 APT
    const DEFAULT_APT_FEE: u64 = 0;

    /// @notice Maximum APT fee allowed (10 APT = 1_000_000_000 micro APT)
    const MAX_APT_FEE: u64 = 1_000_000_000;

    /// @notice Seed value used to create a deterministic resource account for fee management.
    /// This seed is passed to `account::create_resource_account` to generate a unique resource account
    /// that will be used to collect and manage transaction fees. The resource account's address is
    /// deterministically derived from this seed and the source account's address.
    const FEE_MANAGER: vector<u8> = b"FEE_MANAGER";

    // Structs
    /// @notice Metadata holding the address of the sticky object (used to access FeeConfig resource)
    struct FeeConfigMetadata has key {
        /// The address of the sticky object that holds the FeeConfig
        object_address: address
    }

    /// @notice Configuration for fee management
    struct FeeConfig has key {
        /// Mapping of asset addresses to their respective fee rates (asset => apt fee)
        asset_config: SmartTable<address, u64>,
        /// Total accumulated fees collected historically (not current balance)
        total_fees: u128,
        /// Capability used to sign on behalf of the fee collector account
        signer_cap: SignerCapability
    }

    // Events
    #[event]
    /// @notice Event emitted when the fee is updated via `set_apt_fee`
    /// @param caller Address who updated the fee
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_fee Previous fee value (micro APT)
    /// @param new_fee New fee value (micro APT)
    struct FeeChanged has store, drop {
        caller: address,
        asset: address,
        old_fee: u64,
        new_fee: u64
    }

    #[event]
    /// @notice Event emitted when APT fees are collected
    /// @param from Who initiated the transfer
    /// @param recipient Address receiving the transferred fee
    /// @param asset The address of the underlying asset of the reserve
    /// @param amount Amount transferred in micro APT
    struct FeeCollected has store, drop {
        from: address,
        recipient: address,
        asset: address,
        amount: u128
    }

    #[event]
    /// @notice Event emitted when APT fees are withdrawn
    /// @param caller Who initiated the transfer
    /// @param recipient Address receiving the transferred fee
    /// @param amount Amount transferred in micro APT
    struct FeeWithdrawn has store, drop {
        caller: address,
        recipient: address,
        amount: u128
    }

    // Public view functions
    #[view]
    /// @notice Returns the current configured APT fee (in micro APT)
    /// @param asset The address of the underlying asset of the reserve
    /// @return The fee in micro APT
    public fun get_apt_fee(asset: address): u64 acquires FeeConfig, FeeConfigMetadata {
        assert_fee_config_exists();
        let fee_config = fee_config_ref();
        *smart_table::borrow_with_default(
            &fee_config.asset_config, asset, &DEFAULT_APT_FEE
        )
    }

    #[view]
    /// @notice Returns the address of the fee collector resource account
    /// @return The address of the fee collector
    public fun get_fee_collector_address(): address acquires FeeConfig, FeeConfigMetadata {
        assert_fee_config_exists();
        let fee_config = fee_config_ref();
        account::get_signer_capability_address(&fee_config.signer_cap)
    }

    #[view]
    /// @notice Returns the current balance of APT held by the fee collection resource account
    /// @dev This represents the real-time available fees that have been collected but not yet distributed
    /// @return The balance in micro APT
    public fun get_fee_collector_apt_balance(): u64 acquires FeeConfig, FeeConfigMetadata {
        let fee_collector_address = get_fee_collector_address();
        // Query the coin balance (APT) of the fee collector resource account
        coin::balance<aptos_coin::AptosCoin>(fee_collector_address)
    }

    #[view]
    /// @notice Returns the total amount of fees collected historically
    /// @return The total fees in micro APT
    public fun get_total_fees(): u128 acquires FeeConfig, FeeConfigMetadata {
        assert_fee_config_exists();
        let fee_config = fee_config_ref();
        fee_config.total_fees
    }

    #[view]
    /// @notice Returns the address of the sticky object that stores the fee configuration
    /// @return The address of the fee config object
    public fun get_fee_config_object_address(): address acquires FeeConfigMetadata {
        assert!(
            exists<FeeConfigMetadata>(@aave_pool),
            error_config::get_eresource_not_exist()
        );
        let fee_config_object = borrow_global<FeeConfigMetadata>(@aave_pool);
        fee_config_object.object_address
    }

    // Public entry functions
    /// @notice Allows pool admin to transfer collected APT fees from the fee collector account to a target address
    /// @dev Can be used to withdraw accumulated fees to a treasury or reward distribution contract
    /// @dev Emits a FeeWithdrawn event on successful update
    /// @param from The signer of the pool admin account
    /// @param to The recipient address
    /// @param amount The amount to transfer in micro APT
    public entry fun withdraw_apt_fee(
        from: &signer, to: address, amount: u128
    ) acquires FeeConfigMetadata, FeeConfig {
        assert!(amount > 0, error_config::get_einvalid_amount());
        assert_fee_config_exists();

        let from_address = signer::address_of(from);
        // Permission check
        assert!(
            only_pool_admin(from_address), error_config::get_ecaller_not_pool_admin()
        );

        let fee_config = fee_config_ref();
        // Create signer for the resource account
        let fee_collector =
            &account::create_signer_with_capability(&fee_config.signer_cap);
        // Transfer fees
        aptos_account::transfer_coins<aptos_coin::AptosCoin>(
            fee_collector, to, (amount as u64)
        );

        event::emit(FeeWithdrawn { caller: from_address, recipient: to, amount });
    }

    // Friend functions
    /// @notice Updates the global APT fee rate (in micro APT units)
    /// @dev Only callable by pool_configurator module
    /// @dev The new apt fee must be less than or equal to MAX_APT_FEE (10 APT)
    /// @dev Emits a FeeChanged event on successful update
    /// @param caller The signer of the pool admin or risk admin account
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_apt_fee The new fee value in micro APT
    public(friend) fun set_apt_fee(
        caller: &signer, asset: address, new_apt_fee: u64
    ) acquires FeeConfig, FeeConfigMetadata {
        assert_fee_config_exists();
        assert!(new_apt_fee <= MAX_APT_FEE, error_config::get_einvalid_max_apt_fee());

        let fee_config = borrow_global_mut<FeeConfig>(get_fee_config_object_address());
        let old_fee = DEFAULT_APT_FEE;
        if (smart_table::contains(&fee_config.asset_config, asset)) {
            old_fee = *smart_table::borrow(&fee_config.asset_config, asset);
        };
        smart_table::upsert(&mut fee_config.asset_config, asset, new_apt_fee);

        // Record detailed event
        event::emit(
            FeeChanged {
                caller: signer::address_of(caller),
                asset,
                old_fee,
                new_fee: new_apt_fee
            }
        );
    }

    /// @notice Charges the configured APT fee from the caller and transfers it to the fee collector account
    /// @dev Only callable by internal `supply_logic`, `borrow_logic` and flashloan_logic modules
    /// @dev Emits a FeeCollected event on successful update
    /// @dev Accumulates the fee into `total_fees` for historical auditing
    /// @param from The signer of the account paying the fee
    /// @param asset The address of the underlying asset of the reserve
    public(friend) fun collect_apt_fee(
        from: &signer, asset: address
    ) acquires FeeConfig, FeeConfigMetadata {
        let apt_fee = get_apt_fee(asset);
        if (apt_fee != 0) {
            let fee_config = fee_config_mut_ref();
            // Transfer fee to the fee collector resource account
            let fee_collector_address =
                account::get_signer_capability_address(&fee_config.signer_cap);
            aptos_account::transfer_coins<aptos_coin::AptosCoin>(
                from, fee_collector_address, apt_fee
            );

            // Update total fees collected
            fee_config.total_fees +=(apt_fee as u128);

            // Record event
            event::emit(
                FeeCollected {
                    from: signer::address_of(from),
                    recipient: fee_collector_address,
                    asset,
                    amount: (apt_fee as u128)
                }
            );
        }
    }

    // Private functions
    /// @notice Initializes the fee manager module by creating a sticky object and fee configuration resource
    /// @dev This function is only intended to be invoked once during module deployment
    /// @param account The signer of the pool owner account
    fun init_module(account: &signer) {
        let signer_addr = signer::address_of(account);
        assert!(
            signer_addr == @aave_pool,
            error_config::get_enot_pool_owner()
        );

        // Create a new sticky object for fee configuration storage
        let constructor_ref = object::create_sticky_object(signer_addr);
        let object_address = object::address_from_constructor_ref(&constructor_ref);

        // Store the sticky object address in metadata
        move_to(account, FeeConfigMetadata { object_address });

        // Create the resource account associated with this object for fee collection
        let object_signer = &object::generate_signer(&constructor_ref);
        // Create a resource account for fee collection
        let (_resource_signer, signer_cap) =
            account::create_resource_account(object_signer, FEE_MANAGER);

        // Initialize fee configuration with default values
        move_to(
            object_signer,
            FeeConfig { asset_config: smart_table::new(), total_fees: 0, signer_cap }
        );
    }

    /// @notice Verifies that the fee configuration exists in the sticky object
    /// @dev Aborts if the fee configuration is not found
    fun assert_fee_config_exists() acquires FeeConfigMetadata {
        let object_address = get_fee_config_object_address();
        assert!(
            exists<FeeConfig>(object_address),
            error_config::get_eresource_not_exist()
        );
    }

    /// @notice Checks if an account has pool admin privileges
    /// @param account The address to check
    /// @return True if the account is a pool admin, false otherwise
    fun only_pool_admin(account: address): bool {
        acl_manage::is_pool_admin(account)
    }

    /// @notice Returns a mutable reference to the FeeConfig resource
    /// @return A mutable reference to the FeeConfig resource
    inline fun fee_config_mut_ref(): &mut FeeConfig {
        borrow_global_mut<FeeConfig>(get_fee_config_object_address())
    }

    /// @notice Returns an immutable reference to the FeeConfig resource
    /// @return An immutable reference to the FeeConfig resource
    inline fun fee_config_ref(): &FeeConfig {
        borrow_global<FeeConfig>(get_fee_config_object_address())
    }

    // Test only functions
    #[test_only]
    /// @notice Initializes the fee manager module for testing
    /// @param account The signer of the pool owner account
    public fun init_module_for_testing(account: &signer) {
        init_module(account)
    }

    #[test_only]
    /// @notice Asserts that the fee configuration exists for testing
    public fun assert_fee_config_exists_for_testing() acquires FeeConfigMetadata {
        assert_fee_config_exists()
    }
}
