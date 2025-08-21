/// @title Revision library
/// @author Aave
/// @notice Implements revision versioning for the protocol
module aave_config::revision {
    // imports
    use std::string::String;
    use aptos_std::string_utils;

    // Global Constants
    /// @notice Major version number
    const MAJOR_REVISION: u256 = 1;
    /// @notice Minor version number
    const MINOR_REVISION: u256 = 1;
    /// @notice Patch version number
    const PATCH_REVISION: u256 = 0;

    // Public view functions
    #[view]
    /// @notice Returns the full version string in the format "major.minor.patch"
    /// @return The version string
    public fun get_revision(): String {
        string_utils::format3(
            &b"{}.{}.{}",
            MAJOR_REVISION,
            MINOR_REVISION,
            PATCH_REVISION
        )
    }

    // Test-only functions
    #[test_only]
    /// @dev Returns the major revision number for testing
    /// @return The major revision number
    public fun get_major_revision(): u256 {
        MAJOR_REVISION
    }

    #[test_only]
    /// @dev Returns the minor revision number for testing
    /// @return The minor revision number
    public fun get_minor_revision(): u256 {
        MINOR_REVISION
    }

    #[test_only]
    /// @dev Returns the patch revision number for testing
    /// @return The patch revision number
    public fun get_patch_revision(): u256 {
        PATCH_REVISION
    }
}
