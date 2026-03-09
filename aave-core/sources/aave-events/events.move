/// @title Events module
/// @author Aave
/// @notice Implements the common events for different submodules
module aave_pool::events {
    // imports
    use aptos_framework::event;

    // Module friends
    friend aave_pool::borrow_logic;
    friend aave_pool::isolation_mode_logic;
    friend aave_pool::pool;
    friend aave_pool::pool_token_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::a_token_factory;

    // Event definitions
    #[event]
    /// @notice Emitted when the total debt in isolation mode is updated
    /// @dev Emitted on borrow(), repay() and liquidation_call() when using isolated assets
    /// @param asset The address of the underlying asset of the reserve
    /// @param total_debt The total isolation mode debt for the reserve
    struct IsolationModeTotalDebtUpdated has store, drop {
        /// @dev The address of the underlying asset
        asset: address,
        /// @dev The updated total debt
        total_debt: u256
    }

    #[event]
    /// @notice Emitted when a reserve is enabled as collateral for a user
    /// @dev Emitted on supply(), set_user_use_reserve_as_collateral()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user enabling the usage as collateral
    struct ReserveUsedAsCollateralEnabled has store, drop {
        /// @dev The address of the reserve
        reserve: address,
        /// @dev The address of the user
        user: address
    }

    #[event]
    /// @notice Emitted when a reserve is disabled as collateral for a user
    /// @dev Emitted on finalize_transfer()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user disabling the usage as collateral
    struct ReserveUsedAsCollateralDisabled has store, drop {
        /// @dev The address of the reserve
        reserve: address,
        /// @dev The address of the user
        user: address
    }

    #[event]
    /// @notice Emitted when a balance transfer occurs
    /// @dev Emitted during the transfer action
    /// @param from The user whose tokens are being transferred
    /// @param to The recipient
    /// @param value The scaled amount being transferred
    /// @param index The next liquidity index of the reserve
    /// @param a_token_address The address of the aToken
    struct BalanceTransfer has store, drop {
        /// @dev The source address
        from: address,
        /// @dev The destination address
        to: address,
        /// @dev The amount being transferred (scaled)
        value: u256,
        /// @dev The liquidity index
        index: u256,
        /// @dev The address of the corresponding aToken
        a_token_address: address
    }

    // Event emitter functions
    /// @notice Emits an event when isolation mode total debt is updated
    /// @param asset The address of the underlying asset
    /// @param total_debt The updated total debt amount
    friend fun emit_isolated_mode_total_debt_updated(
        asset: address, total_debt: u256
    ) {
        event::emit(IsolationModeTotalDebtUpdated { asset, total_debt })
    }

    /// @notice Emits an event when a reserve is enabled as collateral
    /// @param reserve The address of the reserve
    /// @param user The address of the user
    friend fun emit_reserve_used_as_collateral_enabled(
        reserve: address, user: address
    ) {
        event::emit(ReserveUsedAsCollateralEnabled { reserve, user })
    }

    /// @notice Emits an event when a reserve is disabled as collateral
    /// @param reserve The address of the reserve
    /// @param user The address of the user
    friend fun emit_reserve_used_as_collateral_disabled(
        reserve: address, user: address
    ) {
        event::emit(ReserveUsedAsCollateralDisabled { reserve, user })
    }

    /// @notice Emits an event when a balance transfer occurs
    /// @param from The source address
    /// @param to The destination address
    /// @param value The amount being transferred (scaled)
    /// @param index The liquidity index
    /// @param a_token_address The address of the aToken
    friend fun emit_balance_transfer(
        from: address,
        to: address,
        value: u256,
        index: u256,
        a_token_address: address
    ) {
        event::emit(
            BalanceTransfer { from, to, value, index, a_token_address }
        )
    }
}
