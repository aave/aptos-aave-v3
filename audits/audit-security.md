# AAVE v3 Aptos - Internal Code Review

**Date**: 2026-02-27
**Scope**: All 10 packages under `aave-core/` (107 Move source files)
**Cross-referenced**: Certora V3.0.2, Spearbit V3.0.2, OtterSec V3.1-V3.3

---

## Table of Contents

- [Summary](#summary)
- [Prior Audit Finding Status](#prior-audit-finding-status)
- [Error Findings](#error-findings)
- [Warning Findings](#warning-findings)
- [Info Findings](#info-findings)

---

## Summary

| Severity  | Count   |
| --------- | ------- |
| Error     | 29      |
| Warning   | 53      |
| Info      | 50      |
| **Total** | **132** |

### Packages Reviewed

| Package                 | Files | Errors | Warnings | Info |
| ----------------------- | ----- | ------ | -------- | ---- |
| `aave-acl`              | 1     | 2      | 3        | 3    |
| `aave-config`           | 5     | 1      | 5        | 5    |
| `aave-math`             | 2     | 0      | 4        | 5    |
| `aave-oracle`           | 1     | 5      | 3        | 3    |
| `aave-pool` (core)      | 7     | 2      | 11       | 7    |
| `aave-pool` (logic)     | 8     | 4      | 7        | 16   |
| `aave-pool` (tokens)    | 4     | 7      | 7        | 3    |
| `aave-pool` (periphery) | 7     | 5      | 7        | 2    |
| `chainlink-data-feeds`  | 2     | 2      | 3        | 2    |
| `chainlink-platform`    | 2     | 0      | 2        | 2    |
| `aave-data`             | 2     | 3      | 2        | 2    |
| `aave-large-packages`   | 1     | 0      | 1        | 0    |
| `aave-mock-underlyings` | 1     | 0      | 1        | 0    |

---

## Prior Audit Finding Status

### Fixed

| Audit Finding                                 | Source        | Location                 |
| --------------------------------------------- | ------------- | ------------------------ |
| Dust rounding in repay                        | Spearbit HIGH | `borrow_logic.move`      |
| MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD precision | Certora M-02  | `liquidation_logic.move` |
| `set_user_emode` health check                 | Spearbit      | `emode_logic.move`       |
| Flashloan duplicate asset check               | Spearbit      | `validation_logic.move`  |
| Repay-with-aTokens collateral flag            | Spearbit      | `borrow_logic.move`      |

### Not Fixed

| Audit Finding                                 | Source          | Location                  |
| --------------------------------------------- | --------------- | ------------------------- |
| Liquidation collateral flag `==` vs `>=`      | Spearbit 5.3.19 | `liquidation_logic.move`  |
| `finalize_transfer` compares unscaled amounts | Spearbit 5.3.23 | `pool_token_logic.move`   |
| Negative benchmark stored as huge u256        | Spearbit 5.3.3  | `registry.move`           |
| No staleness check on price retrieval         | Spearbit 5.3.6  | `registry.move`           |
| `Initialized` event missing token address     | Spearbit 5.3.14 | `a_token_factory.move`    |
| Cross-type token creation not guarded         | Spearbit 5.3.15 | `a_token_factory.move`    |
| `set_incentives_controller` desync            | Spearbit 5.3.25 | `token_base.move`         |
| No `DeleteRef` stored for token objects       | Spearbit 5.3.26 | `a_token_factory.move`    |
| eMode LTV uses `>` instead of `>=`            | Spearbit 5.3.1  | `pool_configurator.move`  |
| SmartTable hash-collision DoS                 | OtterSec ADV-03 | Protocol-wide             |
| Oracle staleness                              | OtterSec ADV-01 | `registry.move`           |
| No last-admin guard                           | OtterSec SUG-05 | `acl_manage.move`         |
| `set_reserve_pause` no idempotency guard      | OtterSec SUG-02 | `pool_configurator.move`  |
| GHO liquidation bonus config                  | OtterSec SUG-00 | `v1_values.move`          |
| Missing `#[view]` on getters                  | Certora I-02    | Protocol-wide             |
| Unbounded `SimpleMap` in rewards — DoS        | OtterSec ADV-00 | `rewards_controller.move` |

---

## Error Findings

### E-01: Liquidation collateral flag uses `==` instead of `>=`

- **File**: `aave-core/sources/aave-logic/liquidation_logic.move`
- **Category**: Protocol Logic
- **Audit Ref**: Spearbit 5.3.19 (NOT FIXED)

The check for whether to clear a user's collateral flag after liquidation uses exact equality instead of `>=`. If a liquidation overshoots the exact balance due to rounding, the flag is never cleared, leaving the position in an inconsistent state. This can prevent further liquidations on the user and create stuck positions.

**Suggestion**: Change the equality check to `>=` so that any balance at or below zero triggers flag removal.

---

### E-02: `finalize_transfer` compares unscaled amounts

- **File**: `aave-core/sources/aave-pool/pool_token_logic.move`
- **Category**: Protocol Logic
- **Audit Ref**: Spearbit 5.3.23

Transfer validation compares raw (unscaled) amounts rather than scaled amounts. Because the liquidity index evolves over time, the same raw amount represents different scaled values. This can allow transfers that should be blocked (e.g., when the sender would fall below the required collateral) or block transfers that should succeed.

**Suggestion**: Scale the transfer amount by the current liquidity index before comparison.

---

### E-03: `has_no_collateral_left` excludes protocol fee from bad-debt check

- **File**: `aave-core/sources/aave-logic/liquidation_logic.move`
- **Category**: Protocol Logic

When determining if a user has zero collateral remaining (for bad debt cleanup), the protocol fee portion is not considered. This means a user with a tiny protocol-fee-only collateral remnant would not trigger the bad-debt handling path, potentially leaving orphaned debt.

**Suggestion**: Include protocol fee balances in the `has_no_collateral_left` check, or explicitly document why they are excluded.

---

### E-04: `internal_repay` lacks guard for `on_behalf_of != account_address` with `use_a_tokens`

- **File**: `aave-core/sources/aave-logic/borrow_logic.move`
- **Category**: Access Control

When repaying with aTokens (`use_a_tokens = true`), a user can burn aTokens from their own balance to repay someone else's debt. No explicit authorization check prevents this. While possibly intentional (matching EVM behavior), it allows users to reduce their own collateral to repay arbitrary third-party debt.

**Suggestion**: If intentional, add a NatSpec comment explaining the design choice. Otherwise, add `assert!(on_behalf_of == signer::address_of(account), ...)` when `use_a_tokens` is true.

---

### E-05: `set_reserve_configuration_with_guard` is `public` not `public(friend)`

- **File**: `aave-core/sources/aave-pool/pool.move`
- **Category**: Access Control
- **Audit Ref**: OtterSec ADV-02

This function mutates reserve configuration state but is declared `public`, allowing any module to call it. Per project conventions and OtterSec ADV-02, state-mutating functions should be `public(friend)` to restrict callers to known trusted modules.

**Suggestion**: Change to `public(friend)` and add friend declarations for the modules that need to call it (e.g., `pool_configurator`).

---

### E-06: Negative Chainlink benchmark stored as huge u256

- **File**: `aave-core/chainlink-data-feeds/sources/registry.move`
- **Category**: Oracle
- **Audit Ref**: Spearbit 5.3.3

Chainlink prices use signed i192, but the registry stores them as raw u256. A negative price (which indicates a feed error) wraps to a very large positive number (close to `u256::MAX`), breaking all downstream calculations that assume positive prices. This would cause massively inflated asset valuations.

**Suggestion**: Check the sign bit of the i192 value before casting to u256. If negative, either revert with a protocol error or return 0 with a fallback price mechanism.

---

### E-07: No staleness check on price retrieval

- **File**: `aave-core/chainlink-data-feeds/sources/registry.move`
- **Category**: Oracle
- **Audit Ref**: Spearbit 5.3.6, OtterSec ADV-01

`latest_round_data` returns prices without validating that the timestamp is recent. Stale prices (from hours or days ago) can enable: incorrect liquidations of healthy positions, borrowing beyond safe limits, and exploitable arbitrage between the stale on-chain price and the real market price.

**Suggestion**: Add a configurable staleness threshold per feed. In `latest_round_data`, assert `current_timestamp - updated_at <= staleness_threshold`. Reject prices that exceed the threshold.

---

### E-08: `test_only_risk_or_pool_admin` calls wrong guard function

- **File**: `aave-core/aave-oracle/sources/oracle.move`
- **Category**: Testing

The test helper `test_only_risk_or_pool_admin` calls the wrong ACL guard internally, meaning test coverage may not exercise the real access control path. Tests passing with this helper do not prove the production guard works correctly.

**Suggestion**: Fix the test helper to call the same guard function used in production code.

---

### E-09: `u256 <= 0` comparison for negative price guard

- **File**: `aave-core/aave-oracle/sources/oracle.move`
- **Category**: Types

Since `u256` is unsigned, `value <= 0` is equivalent to `value == 0`. This means negative prices that were cast to large u256 values (see E-06) pass the check silently. The guard intended to catch negative prices is ineffective.

**Suggestion**: Handle negative prices at the Chainlink adapter level (E-06). For the oracle module, check `value == 0` explicitly and document that u256 cannot represent negatives.

---

### E-10: Unchecked u256 underflow in snapshot timestamp freshness

- **File**: `aave-core/aave-oracle/sources/oracle.move`
- **Category**: Error Handling

Timestamp arithmetic `current_timestamp - stored_timestamp` can underflow if `stored_timestamp > current_timestamp` (e.g., during testing or chain reorganizations). The underflow produces a huge u256 value that would pass any freshness check.

**Suggestion**: Add `assert!(current_timestamp >= stored_timestamp, ...)` before the subtraction, or use saturating subtraction.

---

### E-11: Unchecked u256 underflow in ratio growth calculations

- **File**: `aave-core/aave-oracle/sources/oracle.move`
- **Category**: Error Handling

Growth rate computation subtracts two u256 values without verifying ordering. If the numerator is less than the denominator, the subtraction underflows and produces a huge result, corrupting the growth rate.

**Suggestion**: Add an ordering assertion before subtraction, or return 0 if the ratio would be negative.

---

### E-12: `set_asset_custom_price` checks wrong condition

- **File**: `aave-core/aave-oracle/sources/oracle.move`
- **Category**: Protocol Logic
- **Audit Ref**: OtterSec SUG-05 variant

The cap validation logic inverts the intended condition. Instead of ensuring the custom price is within bounds, the check allows out-of-bounds values and rejects in-bounds values.

**Suggestion**: Invert the condition to correctly enforce the price cap.

---

### E-13: `user_config::get_first_asset_id_by_mask` underflow when `bit_map_data == 0`

- **File**: `aave-core/aave-config/sources/user_config.move`
- **Category**: Error Handling

When no bits are set in the user configuration bitmap (`bit_map_data == 0`), the function can underflow during bit manipulation, producing garbage results.

**Suggestion**: Add an early return or assertion for the zero case: `if (bit_map_data == 0) { return NONE_SENTINEL; }`.

---

### E-14: SmartTable hash-collision DoS in `acl_manage`

- **File**: `aave-core/aave-acl/sources/acl_manage.move`
- **Category**: Resources
- **Audit Ref**: OtterSec ADV-03

The role storage uses `SmartTable`, which is susceptible to hash-collision denial-of-service attacks. An attacker can craft inputs that cause hash collisions, degrading lookup performance from O(1) to O(n).

**Suggestion**: Replace `SmartTable` with `BigOrderedMap` throughout.

---

### E-15: No last-admin guard for `DEFAULT_ADMIN_ROLE`

- **File**: `aave-core/aave-acl/sources/acl_manage.move`
- **Category**: Access Control
- **Audit Ref**: OtterSec SUG-05

An admin can revoke their own `DEFAULT_ADMIN_ROLE` without checking if they are the last admin. This can permanently lock out all admin access to the protocol.

**Suggestion**: Before revoking `DEFAULT_ADMIN_ROLE`, check that at least one other address holds the role.

---

### E-16: Silent `u256 -> u64` cast in `a_token_factory::rescue_tokens`

- **File**: `aave-core/sources/aave-tokens/a_token_factory.move:344`
- **Category**: Error Handling

`(amount as u64)` truncation when calling `fungible_asset_manager::transfer`. If `amount > u64::MAX`, the transfer silently sends far less than requested. For a rescue operation, this means tokens could be only partially recovered with no indication of failure.

**Suggestion**: Add `assert!(amount <= (U64_MAX as u256), error_config::get_eamount_overflow())` before the cast.

---

### E-17: Silent `u256 -> u64` cast in `a_token_factory::burn`

- **File**: `aave-core/sources/aave-tokens/a_token_factory.move:536`
- **Category**: Error Handling

Same truncation issue during burn. The scaled accounting is computed on the full u256 value, but the actual underlying FA transfer uses the truncated u64. This creates a divergence between protocol accounting and actual FA supply.

**Suggestion**: Same bounds check as E-16.

---

### E-18: Silent `u256 -> u64` cast in `a_token_factory::transfer_underlying_to`

- **File**: `aave-core/sources/aave-tokens/a_token_factory.move:600`
- **Category**: Error Handling

Same truncation issue when transferring underlying assets.

**Suggestion**: Same bounds check as E-16.

---

### E-19: Silent `u256 -> u64` cast in `token_base::mint_scaled`

- **File**: `aave-core/sources/aave-tokens/token_base.move:350`
- **Category**: Error Handling

`(amount_scaled as u64)` when calling `fungible_asset::mint`. If `amount_scaled` exceeds `u64::MAX`, the minted FA amount is silently truncated while the u256 scaled accounting records the full value.

**Suggestion**: `assert!(amount_scaled <= (U64_MAX as u256), error_config::get_eamount_overflow())`.

---

### E-20: Silent `u256 -> u64` cast in `token_base::burn_scaled`

- **File**: `aave-core/sources/aave-tokens/token_base.move:445`
- **Category**: Error Handling

Same truncation issue during burn.

**Suggestion**: Same bounds check as E-19.

---

### E-21: Silent `u256 -> u64` cast in `token_base::transfer`

- **File**: `aave-core/sources/aave-tokens/token_base.move:586`
- **Category**: Error Handling

Same truncation issue during transfer.

**Suggestion**: Same bounds check as E-19.

---

### E-22: Silent `u256 -> u128` cast in `token_base` mint/burn/transfer

- **File**: `aave-core/sources/aave-tokens/token_base.move:326-327, 433-434, 544-547`
- **Category**: Error Handling

`(new_scaled_balance as u128)` and `(index as u128)` casts in `set_user_state`. If either value exceeds `u128::MAX`, the cast aborts with a generic arithmetic error and no protocol-specific error code, making diagnosis impossible.

**Suggestion**: Add explicit overflow assertions with meaningful error codes:

```move
assert!(new_scaled_balance <= (u128::MAX as u256), error_config::get_ebalance_overflow());
assert!(index <= (u128::MAX as u256), error_config::get_eindex_overflow());
```

---

### E-23: Unbounded `SimpleMap<address, UserData>` in rewards — DoS vector

- **File**: `aave-core/sources/aave-periphery/rewards_controller.move:82-89`
- **Category**: Resources
- **Audit Ref**: OtterSec ADV-00

`RewardData.users_data` is a `SimpleMap` with O(n) operations. Every mint, burn, and transfer triggers `update_data`, which performs a linear scan. As users accumulate, gas costs grow without bound, eventually making the protocol unusable for all users of that asset.

**Suggestion**: Replace `SimpleMap<address, UserData>` with `BigOrderedMap<address, UserData>`.

---

### E-24: `Accrued` event emits wrong `user_index` value

- **File**: `aave-core/sources/aave-periphery/rewards_controller.move:1345-1357`
- **Category**: Events

Both `asset_index` and `user_index` fields in the `Accrued` event are set to `new_asset_index`:

```move
Accrued {
    asset_index: new_asset_index,
    user_index: new_asset_index,   // BUG: should be old user index
    ...
}
```

Off-chain accounting tools compute zero accrual for every event since the delta is always zero.

**Suggestion**: Capture `let old_user_index = (user_data.index as u256)` before `update_user_data`, then emit `user_index: old_user_index`.

---

### E-25: `Initialized` event missing token address

- **File**: `aave-core/sources/aave-tokens/a_token_factory.move:62-77`, `variable_debt_token_factory.move:44-57`
- **Category**: Events
- **Audit Ref**: Spearbit 5.3.14

The `Initialized` event does not include the address of the newly created token object. Off-chain indexers cannot determine which on-chain object address was created without parsing transaction side effects. The variable debt factory variant also omits `treasury`, making the two events asymmetric.

**Suggestion**: Add `token_address: address` to both `Initialized` structs.

---

### E-26: Cross-type token creation not guarded

- **File**: `aave-core/sources/aave-tokens/a_token_factory.move`, `variable_debt_token_factory.move`
- **Category**: Types / Access Control
- **Audit Ref**: Spearbit 5.3.15

Neither factory checks whether `underlying_asset` is itself a protocol-managed token of the opposite type. An attacker with `AssetListingAdmin` privileges could configure a reserve where the underlying is a variable debt token address (or vice versa), causing accounting confusion.

**Suggestion**: In both `create_token` functions, assert that `underlying_asset` is neither an existing aToken nor an existing variable debt token.

---

### E-27: `set_incentives_controller` can desync aToken and variable debt token controllers

- **File**: `aave-core/sources/aave-tokens/token_base.move:230-236`
- **Category**: Access Control
- **Audit Ref**: Spearbit 5.3.25

`pool_token_logic` is a friend of `token_base` directly, which means it can call `token_base::set_incentives_controller` with an arbitrary `metadata_address`. This bypasses the factory-level enforcement and allows setting the controller on any `TokenBaseState` object independently, de-syncing the aToken and variable debt token controllers for the same reserve.

**Suggestion**: Remove `pool_token_logic` from `token_base`'s friend list. Route all incentives-controller mutations exclusively through the respective factory modules.

---

### E-28: `option::destroy_some` panics if transfer strategy is `None`

- **File**: `aave-core/sources/aave-periphery/rewards_distributor.move:275-285, 328-338`
- **Category**: Error Handling

In `claim_rewards_internal` and `claim_all_rewards_internal`, `option::destroy_some` is called on `get_pull_rewards_transfer_strategy` without checking `is_some` first. If no strategy is installed, the call aborts with a generic Move error instead of a protocol-meaningful message.

**Suggestion**: Replace with an explicit assertion:

```move
let strategy_opt = rewards_controller::get_pull_rewards_transfer_strategy(reward, addr);
assert!(option::is_some(&strategy_opt), error_config::get_eno_transfer_strategy_for_reward());
let strategy = option::destroy_some(strategy_opt);
```

---

### E-29: GHO configuration errors

- **File**: `aave-core/aave-data/sources/v1_values.move`
- **Category**: Configuration
- **Audit Ref**: OtterSec SUG-00

Multiple configuration issues:

1. GHO liquidation bonus is set to an incorrect value
2. GHO mainnet address is `@0x0` (a placeholder that would break deployment)
3. Interest rate parameters are marked TODO with placeholder values

**Suggestion**: Set correct GHO liquidation bonus per protocol specification. Replace `@0x0` with the actual deployed GHO token address. Finalize interest rate parameters before mainnet deployment.

---

## Warning Findings

### W-01 through W-10: SmartTable usage throughout (OtterSec ADV-03)

All instances below use `SmartTable` instead of `BigOrderedMap`/`OrderedMap`, making them susceptible to hash-collision DoS:

| #    | File                                          | Field                                                                                        |
| ---- | --------------------------------------------- | -------------------------------------------------------------------------------------------- |
| W-01 | `acl_manage.move`                             | `Roles.acl_instance`                                                                         |
| W-02 | `pool.move`                                   | Reserve data maps                                                                            |
| W-03 | `pool_configurator.move`                      | `pending_ltv` storage                                                                        |
| W-04 | `pool_fee_manager.move`                       | Fee storage                                                                                  |
| W-05 | `default_reserve_interest_rate_strategy.move` | Strategy storage                                                                             |
| W-06 | `a_token_factory.move`                        | `TokenMap.underlying_to_token`, `token_to_underlying`                                        |
| W-07 | `variable_debt_token_factory.move`            | `TokenMap.underlying_to_token`, `token_to_underlying`                                        |
| W-08 | `token_base.move`                             | `TokenBaseState.user_state`                                                                  |
| W-09 | `rewards_controller.move`                     | `authorized_claimers`, `pull_rewards_transfer_strategy_table`, `assets`, `is_reward_enabled` |
| W-10 | `large_packages.move`                         | Sequential key storage                                                                       |

**Suggestion**: Migrate all `SmartTable` instances to `BigOrderedMap`. For bounded/small collections, use `OrderedMap`.

---

### W-11 through W-18: Missing `#[view]` annotations (Certora I-02)

| #    | File                      | Functions                                                                              |
| ---- | ------------------------- | -------------------------------------------------------------------------------------- |
| W-11 | `error_config.move`       | 130+ `get_e*()` getter functions                                                       |
| W-12 | `helper.move`             | `bitwise_negation`                                                                     |
| W-13 | `pool_logic.move`         | All getter functions                                                                   |
| W-14 | `generic_logic.move`      | Read-only calculation functions                                                        |
| W-15 | `wad_ray_math.move`       | Constant-returning getters (e.g., `wad()`, `ray()`, `half_wad()`)                      |
| W-16 | `math_utils.move`         | Pure computation functions                                                             |
| W-17 | `token_base.move:753,774` | `#[view]` on private `fun` (has no effect, should be removed or functions made public) |
| W-18 | `reserve_config.move`     | `get_*` functions                                                                      |

**Suggestion**: Add `#[view]` to all pure-read `public` functions. Remove `#[view]` from private functions where it has no effect.

---

### W-19 through W-26: Access control — `public` instead of `public(friend)`

| #    | File                             | Functions                                                                                                                                            |
| ---- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| W-19 | `reserve_config.move`            | All `set_*` functions (set_ltv, set_liquidation_threshold, etc.)                                                                                     |
| W-20 | `token_base.move`                | `only_pool_admin` guard                                                                                                                              |
| W-21 | `token_base.move`                | `only_token_admin` guard                                                                                                                             |
| W-22 | `rewards_distributor.move:45-65` | `claim_rewards`, `claim_rewards_on_behalf`, `claim_rewards_to_self`, `claim_all_rewards`, `claim_all_rewards_on_behalf`, `claim_all_rewards_to_self` |
| W-23 | `transfer_strategy.move:98-119`  | `create_pull_rewards_transfer_strategy`                                                                                                              |
| W-24 | `emission_manager.move:353`      | `only_admin` hardcodes `@aave_pool` instead of using ACL role                                                                                        |
| W-25 | `rewards_controller.move:687`    | `configure_assets` does not validate asset is registered aToken/vToken at the controller level                                                       |
| W-26 | `acl_manage.move`                | No last-admin guard for `DEFAULT_ADMIN_ROLE` (OtterSec SUG-05)                                                                                       |

**Suggestion**: Change state-mutating `public` functions to `public(friend)` with appropriate friend declarations. Mark user-facing functions as `public entry`. Replace hardcoded address checks with `acl_manage::is_*` role checks.

---

### W-27 through W-35: Error handling gaps

| #    | File                                          | Issue                                                                                                   |
| ---- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| W-27 | `token_base.move:428`                         | `burn_scaled`: `old_scaled_balance - amount_scaled` can underflow without descriptive error             |
| W-28 | `token_base.move:541`                         | `transfer`: `sender_old_scaled_balance - amount_scaled` can underflow without descriptive error         |
| W-29 | `collector.move:33`                           | `init_module` uses `get_ecaller_not_pool_admin()` instead of `get_ecaller_must_be_pool()`               |
| W-30 | `emission_manager.move:219`                   | `set_emission_per_second` missing length check between `rewards` and `new_emissions_per_second` vectors |
| W-31 | `transfer_strategy.move:127`                  | `emergency_withdrawal` missing zero-address check on `to`                                               |
| W-32 | `math_utils.move`                             | `calculate_linear_interest` missing timestamp equality guard                                            |
| W-33 | `math_utils.move`                             | `pow` has no overflow protection for large exponents                                                    |
| W-34 | `pool_fee_manager.move`                       | `u128 -> u64` silent truncation                                                                         |
| W-35 | `default_reserve_interest_rate_strategy.move` | Missing `slope2 > 0` validation; `available_liquidity` potential underflow                              |

**Suggestion**: Add explicit assertions before unsafe arithmetic. Use protocol-specific error codes from `error_config`. Add bounds checks before all narrowing casts.

---

### W-36 through W-42: Resource and object issues

| #    | File                                   | Issue                                                                                    |
| ---- | -------------------------------------- | ---------------------------------------------------------------------------------------- |
| W-36 | `a_token_factory.move:423`             | No `DeleteRef` stored; `create_sticky_object` prevents future deletion (Spearbit 5.3.26) |
| W-37 | `variable_debt_token_factory.move:273` | Same as W-36                                                                             |
| W-38 | `token_base.move:670-690`              | `drop_token` removes resources but sticky object persists                                |
| W-39 | `token_base.move:689`                  | `ManagedFungibleAsset` inner ref drop-ability unconfirmed                                |
| W-40 | `a_token_factory.move:282`             | O(n) symbol scan in `token_address` view function                                        |
| W-41 | `variable_debt_token_factory.move:209` | Same O(n) scan as W-40                                                                   |
| W-42 | `rewards_controller.move:75,82,91`     | `AssetData`, `RewardData`, `UserData` carry unused `key` ability                         |

**Suggestion**:

- W-36/37: Use `object::create_object` instead of `create_sticky_object` and store a `DeleteRef` in `TokenData`
- W-38: Exercise the `DeleteRef` in `drop_token` to fully remove the object
- W-39: Verify `MintRef`, `BurnRef`, `TransferRef` implement `drop` in the Aptos framework
- W-40/41: Add a `symbol_to_token: SmartTable<String, address>` reverse index to `TokenMap`
- W-42: Remove `key` ability from these structs; they only need `store, drop, copy`

---

### W-43 through W-53: Other warnings

| #    | File                          | Issue                                                         |
| ---- | ----------------------------- | ------------------------------------------------------------- |
| W-43 | `pool_configurator.move`      | eMode LTV uses strict `>` instead of `>=` (Spearbit 5.3.1)    |
| W-44 | `pool_configurator.move`      | `set_reserve_pause` no idempotency guard (OtterSec SUG-02)    |
| W-45 | `pool_configurator.move`      | Variable shadowing in `set_reserve_freeze`                    |
| W-46 | `pool_logic.move`             | `update_state` cache not syncing `curr_*` fields after update |
| W-47 | `rewards_controller.move:713` | No oracle price staleness check in `configure_assets`         |
| W-48 | `transfer_strategy.move:226`  | `u256 -> u64` cast for reward amounts without bounds check    |
| W-49 | `coin_migrator.move`          | Missing `_for_testing` helpers and `#[test_only]` friends     |
| W-50 | `events.move`                 | Missing `_for_testing` helpers and `#[test_only]` friends     |
| W-51 | `fungible_asset_manager.move` | Missing `_for_testing` helpers                                |
| W-52 | `v1_values.move`              | TODO placeholder interest rates for GHO                       |
| W-53 | `v1_deployment.move`          | `debug::print` statements in production code                  |

---

## Info Findings

### I-01 through I-10: Style and naming

| #    | File                                   | Issue                                                                                  |
| ---- | -------------------------------------- | -------------------------------------------------------------------------------------- |
| I-01 | `coin_migrator.move:29`                | Event struct name typo: `CoinToFaConvertion` should be `CoinToFaConversion`            |
| I-02 | `token_base.move:692-697`              | `init_module` placed in "Private functions" section instead of its own section         |
| I-03 | `a_token_factory.move:672`             | Same as I-02                                                                           |
| I-04 | `variable_debt_token_factory.move:406` | Same as I-02                                                                           |
| I-05 | `flashloan_logic.move`                 | Section ordering does not match project convention                                     |
| I-06 | `error_config.move`                    | One getter name contains typo (mismatched constant/getter)                             |
| I-07 | `user_config.move`                     | Operator precedence ambiguity in bitwise expressions (should use explicit parentheses) |
| I-08 | `wad_ray_math.move`                    | `ray_div_down` guard is overly conservative                                            |
| I-09 | `mock_underlying_token_factory.move`   | Wrong error constant used for `assert_token_exists`                                    |
| I-10 | `ui_pool_data_provider_v3.move`        | `is_virtual_acc_active` hardcoded to `true`                                            |

---

### I-11 through I-20: NatSpec and documentation

| #    | File                           | Issue                                                                                  |
| ---- | ------------------------------ | -------------------------------------------------------------------------------------- |
| I-11 | `acl_manage.move`              | Missing `@notice` on several public functions                                          |
| I-12 | `oracle.move`                  | Fabricated timestamps used for custom prices (missing documentation of why)            |
| I-13 | `pool.move`                    | Some inline getters missing `@dev` comments                                            |
| I-14 | `liquidation_logic.move`       | Dead commented-out code in validation paths                                            |
| I-15 | `rewards_controller.move:79`   | `available_rewards_count: u128` should be `u64` for idiomatic range loops              |
| I-16 | `token_base.move:684`          | Inconsistent `Option` cleanup in `drop_token`; implicit drop suffices                  |
| I-17 | `emission_manager.move:69`     | `create_named_object` without `DeleteRef` (singleton, less concerning)                 |
| I-18 | `collector.move:111`           | Error code `get_ecaller_not_atoken()` misleading — should be `get_easset_not_atoken()` |
| I-19 | `token_base.move:418`          | `burn_scaled` reuses `get_einvalid_mint_amount()` error code — should be burn-specific |
| I-20 | `rewards_controller.move:1480` | `reserve_index - user_index` without defensive check                                   |

---

### I-21 through I-30: Confirmed correct patterns

| #    | File                              | What was verified                                                                   |
| ---- | --------------------------------- | ----------------------------------------------------------------------------------- |
| I-21 | `events.move`                     | All event structs correctly have `has store, drop`; emitters are `public(friend)`   |
| I-22 | `generic_logic.move`              | Rounding directions are protocol-favorable (debt rounds up, collateral rounds down) |
| I-23 | `supply_logic.move`               | Correct ordering of state operations (update before transfer)                       |
| I-24 | `isolation_mode_logic.move`       | Asymmetric `ceil_div` usage is safe                                                 |
| I-25 | `user_logic.move`                 | Adequate NatSpec documentation                                                      |
| I-26 | `pool_data_provider.move`         | Fully annotated with `#[view]`, no issues                                           |
| I-27 | `collector.move:98`               | `withdraw` correctly uses `public entry fun`                                        |
| I-28 | `rewards_controller.move:104-159` | Event structs correctly have `has store, drop`                                      |
| I-29 | `rewards_distributor.move`        | Clean module structure, no `init_module` needed                                     |
| I-30 | `collector.move:119`              | Widening cast `(amount as u256)` is safe                                            |

---

### I-31 through I-50: Additional style and testing info

| #    | Category | Details                                                                                                        |
| ---- | -------- | -------------------------------------------------------------------------------------------------------------- |
| I-31 | Testing  | `emode_logic.move` — `set_user_emode` health check confirmed fixed                                             |
| I-32 | Testing  | `validation_logic.move` — Flashloan duplicate check confirmed fixed                                            |
| I-33 | Testing  | `borrow_logic.move` — Repay-with-aTokens collateral flag confirmed fixed                                       |
| I-34 | Testing  | `borrow_logic.move` — Dust rounding confirmed fixed                                                            |
| I-35 | Testing  | `liquidation_logic.move` — MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD confirmed fixed                                 |
| I-36 | Style    | `chainlink-data-feeds/registry.move` — `SimpleMap` used for feeds (small/bounded, tolerable)                   |
| I-37 | Style    | `chainlink-data-feeds/router.move` — `_authority` signer never verified; wrong error category                  |
| I-38 | Style    | `chainlink-platform/forwarder.move` — Raw error codes in assert!                                               |
| I-39 | Style    | `chainlink-platform/storage.move` — Raw error code in init_module                                              |
| I-40 | Style    | `v1_deployment.move` — Bare `assert!` without error code                                                       |
| I-41 | Style    | `pool_configurator.move` — Multiple section ordering issues                                                    |
| I-42 | Style    | `oracle.move` — Sequential integer division causes precision loss                                              |
| I-43 | Style    | `math_utils.move` — `ceil_div` potential overflow on `a + b - 1`                                               |
| I-44 | Style    | `a_token_factory.move:286-307` — O(n) iteration via `for_each_ref` to find token by symbol                     |
| I-45 | Testing  | `rewards_distributor.move` — Has `_for_testing` helpers, good pattern                                          |
| I-46 | Style    | `emission_manager.move:353` — Design choice to use `@aave_pool` instead of ACL should be documented            |
| I-47 | Testing  | `fungible_asset_manager.move:91-96` — `assert_token_exists` is `public` but only used internally               |
| I-48 | Style    | `rewards_controller.move:442` — `is_reward_enabled.keys()` returns all keys, O(n) but tolerable for small sets |
| I-49 | Style    | `acl_manage.move` — Module section ordering does not follow convention                                         |
| I-50 | Style    | `reserve_config.move` — Bitwise expressions should use explicit parentheses for clarity                        |

---

## Prioritized Recommendations

### Immediate (before mainnet)

1. **E-16 through E-22**: Add bounds checks before all `u256 -> u64` and `u256 -> u128` casts in token modules
2. **E-23**: Replace `SimpleMap<address, UserData>` with `BigOrderedMap` in `rewards_controller`
3. **E-06, E-07**: Fix Chainlink negative price handling and add staleness checks
4. **E-01**: Fix liquidation collateral flag `==` to `>=`
5. **E-29**: Resolve all GHO configuration placeholders

### High Priority

6. **W-01 through W-10**: Migrate `SmartTable` to `BigOrderedMap` protocol-wide
7. **E-02**: Fix `finalize_transfer` to compare scaled amounts
8. **E-05, W-19 through W-26**: Restrict `public` state-mutating functions to `public(friend)`
9. **E-27**: Fix `set_incentives_controller` friend access to prevent desync
10. **E-15**: Add last-admin guard for `DEFAULT_ADMIN_ROLE`

### Medium Priority

11. **W-11 through W-18**: Add `#[view]` annotations to all pure-read public functions
12. **E-25**: Add token address to `Initialized` events
13. **E-24**: Fix `Accrued` event `user_index` field
14. **W-27 through W-35**: Add defensive assertions for underflow/overflow
15. **W-53**: Remove `debug::print` from production code

### Low Priority

16. **I-01**: Fix `CoinToFaConvertion` typo (before deployment only)
17. **I-02 through I-05**: Fix module section ordering
18. **W-49 through W-51**: Add missing test helpers
19. **I-11 through I-20**: Improve NatSpec documentation
20. **I-36 through I-50**: Address remaining style issues
