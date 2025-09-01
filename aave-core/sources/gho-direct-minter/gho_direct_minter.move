/// @title Gho Direct Minter Module
/// @author Aave
/// @notice Implements the GHO direct minter functionality for minting/burning via the reserve entity
module aave_pool::gho_direct_minter {
    // Std imports
    use std::signer;
    use aptos_framework::dispatchable_fungible_asset;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{
        Self,
        ExtendRef as ObjExtendRef,
        Object,
        ObjectGroup,
        TransferRef as ObjectTransferRef
    };
    // Aave imports
    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_pool::a_token_factory;
    use aave_pool::collector;
    use aave_pool::pool;
    use aave_pool::supply_logic;
    use aave_pool::pool_configurator;
    use aave_pool::fungible_asset_manager;
    use gho::gho_reserve;

    // Constants
    /// @notice Name for the GHO direct minter object
    const GHO_DIRECT_MINTER_NAME: vector<u8> = b"GHO_DIRECT_MINTER";

    // Structs
    #[resource_group_member(group = ObjectGroup)]
    /// @notice On-chain state for the GHO direct minter
    /// @dev Stores the GHO token address, object refs used for actions, and the treasury (collector) address
    struct GhoDirectMinterData has key {
        gho_token_address: address,
        extend_ref: ObjExtendRef,
        transfer_ref: ObjectTransferRef,
        collector_address: address
    }

    // Module initialization
    /// @notice Initializes the GHO direct minter
    /// @dev Creates the minter object under @aave_pool
    /// @param sender The signer that initializes the module (must be @aave_pool)
    fun init_module(sender: &signer) {
        only_admin(sender);

        let state_object_constructor_ref =
            &object::create_named_object(sender, GHO_DIRECT_MINTER_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            GhoDirectMinterData {
                gho_token_address: @gho,
                transfer_ref: object::generate_transfer_ref(state_object_constructor_ref),
                extend_ref: object::generate_extend_ref(state_object_constructor_ref),
                collector_address: collector::collector_address()
            }
        );
    }

    // Public entry functions
    /// @notice Uses (mints) GHO from the reserve entity and supplies it to the protocol
    /// @dev Caller must be the GHO Guardian; the reserve entity must have Risk Admin role and a non-zero usage limit
    ///      Temporarily disables supply cap during the supply, then restores it
    /// @param account The transaction signer (must be a GHO Guardian)
    /// @param amount The amount of GHO to use and supply
    public entry fun use_and_supply(account: &signer, amount: u256) acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        // check caller is the gho guardian
        only_gho_guardian(signer::address_of(account));
        let gho_direct_minter_data =
            borrow_global<GhoDirectMinterData>(gho_direct_minter_address());
        let minter_signer =
            object::generate_signer_for_extending(&gho_direct_minter_data.extend_ref);
        let gho_reserve_entity = signer::address_of(&minter_signer);

        // check: gho_reserve_entity must have RISK ADMIN ROLE for the pool
        is_risk_admin(gho_reserve_entity);

        // check: the gho_reserve_entity must be registered as an entity with a non zero entity limit
        let (_, _) = ensure_entity_gho_usage(gho_reserve_entity);

        // use GHO from the gho reserve
        gho_reserve::use_gho(&minter_signer, amount);

        // temporarily set the supply cap to 0 to disable it while supplying
        let old_supply_cap =
            pool::get_reserve_configuration(gho_direct_minter_data.gho_token_address).get_supply_cap();
        pool_configurator::set_supply_cap_internal(
            gho_direct_minter_data.gho_token_address, 0
        );

        // supply GHO from the minter_signer to the protocol
        supply_logic::supply(
            &minter_signer,
            gho_direct_minter_data.gho_token_address,
            amount,
            signer::address_of(&minter_signer),
            0
        );

        // reset the supply cap
        pool_configurator::set_supply_cap_internal(
            gho_direct_minter_data.gho_token_address, old_supply_cap
        );
    }

    /// @notice Withdraws GHO from the protocol back to the reserve entity and restores it (burns against usage)
    /// @dev Caller must be the GHO Guardian; the reserve entity must have Risk Admin role and a non-zero usage limit
    /// @param account The transaction signer (must be a GHO Guardian)
    /// @param amount The amount of GHO to withdraw and restore
    public entry fun withdraw_and_restore(account: &signer, amount: u256) acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        // check caller is gho guardian
        only_gho_guardian(signer::address_of(account));
        let gho_direct_minter_data =
            borrow_global<GhoDirectMinterData>(gho_direct_minter_address());
        let minter_signer =
            object::generate_signer_for_extending(&gho_direct_minter_data.extend_ref);
        let gho_reserve_entity = signer::address_of(&minter_signer);

        // check: gho_reserve_entity must have RISK ADMIN ROLE for the pool
        is_risk_admin(gho_reserve_entity);

        // check: the gho_reserve_entity must be registered as a Facilitator with a non zero bucket capacity
        let (_, _) = ensure_entity_gho_usage(gho_reserve_entity);

        // withdraw GHO underlying asset i.e. burn Atokens and send back the underlying to the primary store of the gho_reserve_entity
        supply_logic::withdraw(
            &minter_signer,
            gho_direct_minter_data.gho_token_address,
            amount,
            signer::address_of(&minter_signer)
        );

        // restore the gho amount back to the gho reserve (i.e. the burning)
        gho_reserve::restore(&minter_signer, amount);
    }

    /// @notice Transfers any excess GHO (over current usage) from the reserve entity to the treasury
    /// @dev Computes excess = aToken balance − used; if zero, no-ops. Uses dispatchable FA transfer
    public entry fun transfer_excess_to_treasury() acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        let gho_direct_minter_data =
            borrow_global_mut<GhoDirectMinterData>(gho_direct_minter_address());
        let minter_signer =
            object::generate_signer_for_extending(&gho_direct_minter_data.extend_ref);
        let gho_reserve_entity = signer::address_of(&minter_signer);

        // get the GHO atoken data
        let gho_token_reserve_data =
            pool::get_reserve_data(gho_direct_minter_data.gho_token_address);
        let a_token_address = pool::get_reserve_a_token_address(gho_token_reserve_data);
        assert!(
            a_token_factory::is_atoken(a_token_address),
            error_config::get_ecaller_not_atoken()
        );

        // extract the entity level
        let (_, used) = ensure_entity_gho_usage(gho_reserve_entity);
        let atoken_balance =
            a_token_factory::balance_of(gho_reserve_entity, a_token_address);
        // compute the excess level
        let excess_level =
            if (atoken_balance > used) {
                atoken_balance - used
            } else { 0 };

        if (excess_level == 0) {
            return;
        };

        // transfer the excess to the treasury
        let a_token_metadata = object::address_to_object<Metadata>(a_token_address);
        let store_from =
            primary_fungible_store::primary_store(gho_reserve_entity, a_token_metadata);
        let store_to =
            primary_fungible_store::ensure_primary_store_exists(
                gho_direct_minter_data.collector_address, a_token_metadata
            );

        dispatchable_fungible_asset::transfer(
            &minter_signer,
            store_from,
            store_to,
            (excess_level as u64)
        );
    }

    /// @notice Sets the GHO token address used by the minter
    /// @dev Only callable by @aave_pool admin; asserts the token exists
    /// @param account The signer of the caller (must be @aave_pool)
    /// @param gho_address The new GHO token address
    public entry fun set_gho_address(
        account: &signer, gho_address: address
    ) acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        only_admin(account);
        assert!(gho_address != @0x0, error_config::get_ezero_address_not_valid());
        fungible_asset_manager::assert_token_exists(gho_address);
        let gho_direct_minter_data =
            borrow_global_mut<GhoDirectMinterData>(gho_direct_minter_address());
        gho_direct_minter_data.gho_token_address = gho_address;
    }

    // Public view functions
    #[view]
    /// @notice Address of the GHO direct minter object
    /// @return The object address derived from @aave_pool and the name seed
    public fun gho_direct_minter_address(): address {
        object::create_object_address(&@aave_pool, GHO_DIRECT_MINTER_NAME)
    }

    #[view]
    /// @notice Returns the GHO direct minter object handle
    /// @return The object for accessing `GhoDirectMinterData`
    public fun gho_direct_minter_object(): Object<GhoDirectMinterData> {
        object::address_to_object<GhoDirectMinterData>(gho_direct_minter_address())
    }

    #[view]
    /// @notice Gets the configured GHO token address
    /// @return The address of the GHO token used by the minter
    public fun get_gho_token_address(): address acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        let gho_direct_minter_data =
            borrow_global<GhoDirectMinterData>(gho_direct_minter_address());
        gho_direct_minter_data.gho_token_address
    }

    #[view]
    /// @notice Gets the treasury (collector) address
    /// @return The address of the protocol collector
    public fun get_collector_address(): address acquires GhoDirectMinterData {
        assert_gho_reserve_exists();
        let gho_direct_minter_data =
            borrow_global<GhoDirectMinterData>(gho_direct_minter_address());
        gho_direct_minter_data.collector_address
    }

    #[view]
    /// @notice Returns whether an address has the Risk Admin role in the pool
    /// @param account The address to check
    /// @return True if the address is a Risk Admin, false otherwise
    public fun is_risk_admin(account: address): bool {
        acl_manage::is_risk_admin(account)
    }

    #[view]
    /// @notice Returns whether an address is a GHO Guardian
    /// @param account The address to check
    /// @return True if the address is a GHO Guardian, false otherwise
    public fun is_gho_guardian(account: address): bool {
        acl_manage::is_gho_guardian(account)
    }

    #[view]
    /// @notice Returns the address represented by the direct minter signer
    /// @return The address of the signer generated for the minter object
    public fun get_direct_minter_signer_address(): address acquires GhoDirectMinterData {
        signer::address_of(&get_direct_minter_signer())
    }

    // Private functions
    /// @notice Checks if the caller is the pool admin
    /// @dev Reverts if the caller is not @aave_pool
    /// @param account The signer account to check
    fun only_admin(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_pool,
            error_config::get_ecaller_must_be_pool()
        );
    }

    /// @dev Asserts that the GHO direct minter resource exists
    inline fun assert_gho_reserve_exists() {
        assert!(
            exists<GhoDirectMinterData>(gho_direct_minter_address()),
            error_config::get_eresource_not_exist()
        );
    }

    /// @notice Checks if an address has the GHO Guardian role
    /// @dev Reverts if not a GHO Guardian
    /// @param account The address to check
    fun only_gho_guardian(account: address) {
        assert!(
            is_gho_guardian(account),
            error_config::get_ecaller_not_gho_guardian()
        );
    }

    /// @notice Ensures the caller is either the pool owner or the GHO Guardian
    /// @dev Reverts otherwise
    /// @param account The signer to check
    fun only_owner_or_guardian(account: &signer) {
        let caller = signer::address_of(account);
        assert!(
            caller == @aave_pool || is_gho_guardian(caller),
            error_config::get_ecaller_not_gho_guardian()
        );
    }

    /// @notice Ensures the entity has a non-zero GHO usage limit and returns (limit, used)
    /// @dev Reverts if the entity limit is zero
    /// @param entity The reserve entity address
    /// @return (limit, used) usage tuple
    fun ensure_entity_gho_usage(entity: address): (u256, u256) {
        let (limit, used) = gho_reserve::get_usage(entity);
        assert!(
            limit > 0,
            error_config::get_ezero_entity_limit()
        );
        (limit, used)
    }

    /// @notice Returns a signer capable of operating the GHO direct minter object
    /// @return The generated signer for extending the minter object
    fun get_direct_minter_signer(): signer acquires GhoDirectMinterData {
        let gho_direct_minter_data =
            borrow_global<GhoDirectMinterData>(gho_direct_minter_address());
        object::generate_signer_for_extending(&gho_direct_minter_data.extend_ref)
    }

    // Test-only functions
    #[test_only]
    /// @notice Initializes the module for testing
    /// @param account The signer account for testing
    public fun init_module_for_testing(account: &signer) {
        init_module(account);
    }
}
