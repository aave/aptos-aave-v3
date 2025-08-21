/// @title ACLManager
/// @author Aave
/// @notice Access Control List Manager. Main registry of system roles and permissions.
///
/// Roles are referred to by their `vector<u8>` identifier. These should be exposed
/// in the external API and be unique. The best way to achieve this is by
/// using `const` hash digests:
/// ```
/// const MY_ROLE = b"MY_ROLE";
/// ```
/// Roles can be used to represent a set of permissions. To restrict access to a
/// function call, use {has_role}:
/// ```
/// public fun foo() {
///     assert!(has_role(MY_ROLE, error_code::ENOT_MANAGEMENT));
///     ...
/// }
/// ```
/// Roles can be granted and revoked dynamically via the {grant_role} and
/// {revoke_role} functions. Each role has an associated admin role, and only
/// accounts that have a role's admin role can call {grant_role} and {revoke_role}.
///
/// By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
/// that only accounts with this role will be able to grant or revoke other
/// roles. More complex role relationships can be created by using
/// {set_role_admin}.
///
/// WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
/// grant and revoke this role. Extra precautions should be taken to secure
/// accounts that have been granted it.
module aave_acl::acl_manage {
    // imports
    use std::acl;
    use std::acl::ACL;
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::object;
    use aptos_framework::object::ObjectCore;
    use aave_config::error_config;

    // Error constants

    // Global Constants
    const DEFAULT_ADMIN_ROLE: vector<u8> = b"DEFAULT_ADMIN";
    const POOL_ADMIN_ROLE: vector<u8> = b"POOL_ADMIN";
    const EMERGENCY_ADMIN_ROLE: vector<u8> = b"EMERGENCY_ADMIN";
    const RISK_ADMIN_ROLE: vector<u8> = b"RISK_ADMIN";
    const FLASH_BORROWER_ROLE: vector<u8> = b"FLASH_BORROWER";
    const ASSET_LISTING_ADMIN_ROLE: vector<u8> = b"ASSET_LISTING_ADMIN";
    const FUNDS_ADMIN_ROLE: vector<u8> = b"FUNDS_ADMIN";
    const EMISSION_ADMIN_ROLE: vector<u8> = b"EMISSION_ADMIN";
    const ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE: vector<u8> = b"ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN";
    const REWARDS_CONTROLLER_ADMIN_ROLE: vector<u8> = b"REWARDS_CONTROLLER_ADMIN";

    // Structs
    #[event]
    struct RoleAdminChanged has store, drop {
        /// The name of the role that is getting a new admin
        /// Note: DEFAULT_ADMIN_ROLE is the starting admin for all roles
        role: String,
        /// The previous admin role that is being replaced
        previous_admin_role: String,
        /// The new role that is becoming the admin
        new_admin_role: String
    }

    #[event]
    struct RoleGranted has store, drop {
        /// The name of the role being granted
        role: String,
        /// The address of the account receiving the role
        account: address,
        /// The address that originated the contract call (an admin of the role)
        sender: address
    }

    #[event]
    struct RoleRevoked has store, drop {
        /// The name of the role being revoked
        role: String,
        /// The address of the account losing the role
        /// When using renounce_role, this is the same as the sender
        account: address,
        /// The address that originated the contract call
        /// - If using revoke_role: this is the admin role bearer
        /// - If using renounce_role: this is the role bearer (same as account)
        sender: address
    }

    /// @dev Main structure for storing role data including members and admin role
    struct RoleData has store {
        members: ACL,
        admin_role: String
    }

    /// @dev Root structure holding ACL data for the module
    struct Roles has key {
        acl_instance: SmartTable<String, RoleData>
    }

    // Public view functions
    #[view]
    /// @notice Returns the default admin role string
    /// @return Default admin role as a String
    public fun default_admin_role(): String {
        string::utf8(DEFAULT_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the admin role that controls `role`
    /// @param role The role to check the admin for
    /// @return Admin role string for the specified role
    public fun get_role_admin(role: String): String acquires Roles {
        let roles = get_roles_ref();
        if (!smart_table::contains(&roles.acl_instance, role)) {
            return default_admin_role()
        };

        smart_table::borrow(&roles.acl_instance, role).admin_role
    }

    #[view]
    /// @notice Checks if `user` has been granted `role`
    /// @param role The role identifier
    /// @param user The account to check
    /// @return Boolean indicating if the user has the role
    public fun has_role(role: String, user: address): bool acquires Roles {
        let role_res = get_roles_ref();
        if (!smart_table::contains(&role_res.acl_instance, role)) {
            return false
        };
        let role_data = smart_table::borrow(&role_res.acl_instance, role);
        acl::contains(&role_data.members, user)
    }

    #[view]
    /// @notice Checks if the address is the default admin (i.e., a super-admin)
    /// @param admin Address to check
    /// @return Boolean indicating if the address is the default admin
    public fun is_default_admin(admin: address): bool acquires Roles {
        has_role(default_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is a pool admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is a pool admin
    public fun is_pool_admin(admin: address): bool acquires Roles {
        has_role(get_pool_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is an emergency admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is an emergency admin
    public fun is_emergency_admin(admin: address): bool acquires Roles {
        has_role(get_emergency_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is a risk admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is a risk admin
    public fun is_risk_admin(admin: address): bool acquires Roles {
        has_role(get_risk_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is a flash borrower
    /// @param borrower Address to check
    /// @return Boolean indicating if the address is a flash borrower
    public fun is_flash_borrower(borrower: address): bool acquires Roles {
        has_role(get_flash_borrower_role(), borrower)
    }

    #[view]
    /// @notice Checks if the address is an asset listing admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is an asset listing admin
    public fun is_asset_listing_admin(admin: address): bool acquires Roles {
        has_role(get_asset_listing_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is a funds admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is a funds admin
    public fun is_funds_admin(admin: address): bool acquires Roles {
        has_role(get_funds_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is an emission admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is an emission admin
    public fun is_emission_admin(admin: address): bool acquires Roles {
        has_role(get_emission_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is an admin controlled ecosystem reserve funds admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is an admin controlled ecosystem reserve funds admin
    public fun is_admin_controlled_ecosystem_reserve_funds_admin(
        admin: address
    ): bool acquires Roles {
        has_role(get_admin_controlled_ecosystem_reserve_funds_admin_role(), admin)
    }

    #[view]
    /// @notice Checks if the address is a rewards controller admin
    /// @param admin Address to check
    /// @return Boolean indicating if the address is a rewards controller admin
    public fun is_rewards_controller_admin(admin: address): bool acquires Roles {
        has_role(get_rewards_controller_admin_role(), admin)
    }

    #[view]
    /// @notice Returns the pool admin role string
    /// @return Pool admin role as a String
    public fun get_pool_admin_role(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the emergency admin role string
    /// @return Emergency admin role as a String
    public fun get_emergency_admin_role(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the risk admin role string
    /// @return Risk admin role as a String
    public fun get_risk_admin_role(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the flash borrower role string
    /// @return Flash borrower role as a String
    public fun get_flash_borrower_role(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[view]
    /// @notice Returns the asset listing admin role string
    /// @return Asset listing admin role as a String
    public fun get_asset_listing_admin_role(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the funds admin role string
    /// @return Funds admin role as a String
    public fun get_funds_admin_role(): String {
        string::utf8(FUNDS_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the emission admin role string
    /// @return Emission admin role as a String
    public fun get_emission_admin_role(): String {
        string::utf8(EMISSION_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the admin controlled ecosystem reserve funds admin role string
    /// @return Admin controlled ecosystem reserve funds admin role as a String
    public fun get_admin_controlled_ecosystem_reserve_funds_admin_role(): String {
        string::utf8(ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE)
    }

    #[view]
    /// @notice Returns the rewards controller admin role string
    /// @return Rewards controller admin role as a String
    public fun get_rewards_controller_admin_role(): String {
        string::utf8(REWARDS_CONTROLLER_ADMIN_ROLE)
    }

    // Public entry functions
    /// @notice Sets `admin_role` as ``role``'s admin role
    /// @param admin Signer with permissions to set role admin
    /// @param role The role to modify admin for
    /// @param admin_role The new admin role to set
    /// @dev Emits a {RoleAdminChanged} event
    public entry fun set_role_admin(
        admin: &signer, role: String, admin_role: String
    ) acquires Roles {
        only_role(default_admin_role(), signer::address_of(admin));

        let previous_admin_role = get_role_admin(role);
        let roles = get_roles_mut();

        if (!smart_table::contains(&mut roles.acl_instance, role)) {
            let members = acl::empty();
            let role_data = RoleData { members, admin_role };
            smart_table::add(&mut roles.acl_instance, role, role_data);
        } else {
            let role_data = smart_table::borrow_mut(&mut roles.acl_instance, role);
            role_data.admin_role = admin_role;
        };

        event::emit(
            RoleAdminChanged { role, previous_admin_role, new_admin_role: admin_role }
        );
    }

    /// @notice Grants `role` to `account`
    /// @param admin Signer with admin role permissions
    /// @param role The role to grant
    /// @param user Address to grant the role to
    /// @dev Errors if the 0x0 address is being used to be granted a role
    /// @dev If `account` had not been already granted `role`, emits a {RoleGranted} event
    /// @dev Requirements: the caller must have ``role``'s admin role
    public entry fun grant_role(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        assert!(user != @0x0, error_config::get_ezero_address_not_valid());
        let admin_address = signer::address_of(admin);
        only_role(get_role_admin(role), admin_address);
        grant_role_internal(admin, role, user);
    }

    /// @notice Revokes `role` from the calling account
    /// @param admin Signer revoking their own role
    /// @param role The role to renounce
    /// @dev If the calling account had been granted `role`, emits a {RoleRevoked} event
    /// @dev Requirements: the caller must be `account`
    public entry fun renounce_role(admin: &signer, role: String) acquires Roles {
        revoke_role_internal(admin, role, signer::address_of(admin));
    }

    /// @notice Revokes `role` from `account`
    /// @param admin Signer with admin role permissions
    /// @param role The role to revoke
    /// @param user Address to revoke the role from
    /// @dev If `account` had been granted `role`, emits a {RoleRevoked} event
    /// @dev Requirements: the caller must have ``role``'s admin role
    public entry fun revoke_role(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        let admin_address = signer::address_of(admin);
        only_role(get_role_admin(role), admin_address);
        revoke_role_internal(admin, role, user);
    }

    /// @notice Adds a default admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the default admin role to
    public entry fun add_default_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, default_admin_role(), user);
    }

    /// @notice Renounce the default admin role
    /// @param admin Signer with permissions to grant roles
    public entry fun renounce_default_admin(admin: &signer) acquires Roles {
        renounce_role(admin, default_admin_role());
    }

    /// @notice Adds a pool admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the pool admin role to
    public entry fun add_pool_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_pool_admin_role(), user);
    }

    /// @notice Removes the pool admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the pool admin role from
    public entry fun remove_pool_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_pool_admin_role(), user);
    }

    /// @notice Adds an emergency admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the emergency admin role to
    public entry fun add_emergency_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_emergency_admin_role(), user);
    }

    /// @notice Removes the emergency admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the emergency admin role from
    public entry fun remove_emergency_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_emergency_admin_role(), user);
    }

    /// @notice Adds a risk admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the risk admin role to
    public entry fun add_risk_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_risk_admin_role(), user);
    }

    /// @notice Removes the risk admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the risk admin role from
    public entry fun remove_risk_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_risk_admin_role(), user);
    }

    /// @notice Adds a flash borrower role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param borrower Address to grant the flash borrower role to
    public entry fun add_flash_borrower(admin: &signer, borrower: address) acquires Roles {
        grant_role(admin, get_flash_borrower_role(), borrower);
    }

    /// @notice Removes the flash borrower role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param borrower Address to revoke the flash borrower role from
    public entry fun remove_flash_borrower(
        admin: &signer, borrower: address
    ) acquires Roles {
        revoke_role(admin, get_flash_borrower_role(), borrower);
    }

    /// @notice Adds an asset listing admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the asset listing admin role to
    public entry fun add_asset_listing_admin(
        admin: &signer, user: address
    ) acquires Roles {
        grant_role(admin, get_asset_listing_admin_role(), user);
    }

    /// @notice Removes the asset listing admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the asset listing admin role from
    public entry fun remove_asset_listing_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(admin, get_asset_listing_admin_role(), user);
    }

    /// @notice Adds a funds admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the funds admin role to
    public entry fun add_funds_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_funds_admin_role(), user);
    }

    /// @notice Removes the funds admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the funds admin role from
    public entry fun remove_funds_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_funds_admin_role(), user);
    }

    /// @notice Adds an emission admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the emission admin role to
    public entry fun add_emission_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_emission_admin_role(), user);
    }

    /// @notice Removes the emission admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the emission admin role from
    public entry fun remove_emission_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_emission_admin_role(), user);
    }

    /// @notice Adds an admin controlled ecosystem reserve funds admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the admin controlled ecosystem reserve funds admin role to
    public entry fun add_admin_controlled_ecosystem_reserve_funds_admin(
        admin: &signer, user: address
    ) acquires Roles {
        grant_role(
            admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user
        );
    }

    /// @notice Removes the admin controlled ecosystem reserve funds admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the admin controlled ecosystem reserve funds admin role from
    public entry fun remove_admin_controlled_ecosystem_reserve_funds_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(
            admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user
        );
    }

    /// @notice Adds a rewards controller admin role to the specified address
    /// @param admin Signer with permissions to grant roles
    /// @param user Address to grant the rewards controller admin role to
    public entry fun add_rewards_controller_admin(
        admin: &signer, user: address
    ) acquires Roles {
        grant_role(admin, get_rewards_controller_admin_role(), user);
    }

    /// @notice Removes the rewards controller admin role from the specified address
    /// @param admin Signer with permissions to revoke roles
    /// @param user Address to revoke the rewards controller admin role from
    public entry fun remove_rewards_controller_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(admin, get_rewards_controller_admin_role(), user);
    }

    // Private/Internal functions
    /// @dev Initializes the module and grants the default admin role to the admin signer
    /// @param admin Signer that will be granted the default admin role
    fun init_module(admin: &signer) {
        let admin_address = signer::address_of(admin);
        assert!(admin_address == @aave_acl, error_config::get_enot_acl_owner());

        let owner =
            if (object::is_object(admin_address)) {
                // add the object owner as super_admin if we deploy on an object model
                object::owner(object::address_to_object<ObjectCore>(admin_address))
            } else {
                // add the account address as super admin if we deploy on an account model
                admin_address
            };

        let members = acl::empty();
        acl::add(&mut members, owner);
        let role_data = RoleData { members, admin_role: default_admin_role() };

        let roles = Roles { acl_instance: smart_table::new() };
        smart_table::add(&mut roles.acl_instance, default_admin_role(), role_data);

        move_to(admin, roles);
    }

    /// @dev Checks if the user has the specified role and aborts if not
    /// @param role The role to check
    /// @param user Address to check for the role
    fun only_role(role: String, user: address) acquires Roles {
        assert!(has_role(role, user), error_config::get_erole_mismatch());
    }

    /// @dev Internal function to grant a role to a user
    /// @param admin Signer granting the role
    /// @param role Role to grant
    /// @param user Address to grant the role to
    fun grant_role_internal(admin: &signer, role: String, user: address) acquires Roles {
        assert!(user != @0x0, error_config::get_ezero_address_not_valid());
        if (!has_role(role, user)) {
            let role_res = get_roles_mut();
            if (!smart_table::contains(&role_res.acl_instance, role)) {
                let members = acl::empty();
                acl::add(&mut members, user);
                let role_data = RoleData { members, admin_role: default_admin_role() };
                smart_table::add(&mut role_res.acl_instance, role, role_data);
            } else {
                let role_data = smart_table::borrow_mut(&mut role_res.acl_instance, role);
                acl::add(&mut role_data.members, user);
            };

            event::emit(
                RoleGranted { role, account: user, sender: signer::address_of(admin) }
            );
        }
    }

    /// @dev Internal function to revoke a role from a user
    /// @param admin Signer revoking the role
    /// @param role Role to revoke
    /// @param user Address to revoke the role from
    fun revoke_role_internal(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        if (has_role(role, user)) {
            let role_res = get_roles_mut();
            let role_data = smart_table::borrow_mut(&mut role_res.acl_instance, role);
            acl::remove(&mut role_data.members, user);

            event::emit(
                RoleRevoked { role, account: user, sender: signer::address_of(admin) }
            );
        }
    }

    /// @dev Asserts that the roles resource is initialized
    fun assert_roles_initialized() {
        assert!(
            exists<Roles>(@aave_acl),
            error_config::get_eroles_not_initialized()
        );
    }

    /// @dev Returns a reference to the roles resource
    /// @return Reference to the Roles resource
    inline fun get_roles_ref(): &Roles {
        assert_roles_initialized();
        borrow_global<Roles>(@aave_acl)
    }

    /// @dev Returns a mutable reference to the roles resource
    /// @return Mutable reference to the Roles resource
    inline fun get_roles_mut(): &mut Roles {
        assert_roles_initialized();
        borrow_global_mut<Roles>(@aave_acl)
    }

    // Test-only functions
    #[test_only]
    /// @dev Initializes the module for testing
    /// @param admin Signer that will be granted the default admin role
    public fun test_init_module(admin: &signer) {
        init_module(admin);
    }

    #[test_only]
    /// @dev Asserts that roles are initialized for testing
    public fun assert_roles_initialized_for_testing() {
        assert_roles_initialized()
    }

    #[test_only]
    /// @dev Returns the pool admin role string for testing
    /// @return Pool admin role as a String
    public fun get_pool_admin_role_for_testing(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the emergency admin role string for testing
    /// @return Emergency admin role as a String
    public fun get_emergency_admin_role_for_testing(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the risk admin role string for testing
    /// @return Risk admin role as a String
    public fun get_risk_admin_role_for_testing(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the flash borrower role string for testing
    /// @return Flash borrower role as a String
    public fun get_flash_borrower_role_for_testing(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[test_only]
    /// @dev Returns the asset listing admin role string for testing
    /// @return Asset listing admin role as a String
    public fun get_asset_listing_admin_role_for_testing(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the funds admin role string for testing
    /// @return Funds admin role as a String
    public fun get_funds_admin_role_for_testing(): String {
        string::utf8(FUNDS_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the emissions admin role string for testing
    /// @return Emissions admin role as a String
    public fun get_emissions_admin_role_for_testing(): String {
        string::utf8(EMISSION_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the admin controlled ecosystem reserve funds admin role string for testing
    /// @return Admin controlled ecosystem reserve funds admin role as a String
    public fun get_admin_controlled_ecosystem_reserve_funds_admin_role_for_testing(): String {
        string::utf8(ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE)
    }

    #[test_only]
    /// @dev Returns the rewards controller admin role string for testing
    /// @return Rewards controller admin role as a String
    public fun get_rewards_controller_admin_role_for_testing(): String {
        string::utf8(REWARDS_CONTROLLER_ADMIN_ROLE)
    }
}
