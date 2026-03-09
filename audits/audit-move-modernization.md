# AAVE v3 Aptos - Move Modernization Audit

**Date**: 2026-03-09
**Scope**: All packages under `aave-core/` — Move source files only
**Focus**: Outdated Move V1 syntax and patterns, modernization to Move V2+

---

## Table of Contents

- [Summary](#summary)
- [Tier 1 Findings — Syntax](#tier-1-findings--syntax)
- [Tier 2 Findings — Visibility](#tier-2-findings--visibility)
- [Tier 3 Findings — API Migrations (Not Applied)](#tier-3-findings--api-migrations-not-applied)
- [Test Results](#test-results)
- [Files Modified](#files-modified)

---

## Summary

| Tier                    | Findings | Applied | Skipped |
| ----------------------- | -------- | ------- | ------- |
| Tier 1 — Syntax         | 111      | 111     | 0       |
| Tier 2 — Visibility     | 66       | 66      | 0       |
| Tier 3 — API Migrations | 25       | 0       | 25      |
| **Total**               | **202**  | **177** | **25**  |

### Tier Breakdown

| Rule  | Pattern                              | Count | Status      |
| ----- | ------------------------------------ | ----- | ----------- |
| T1-01 | `vector::borrow` → index notation    | 87    | [x] Fixed   |
| T1-02 | `vector::borrow_mut` → mutable index | 3     | [x] Fixed   |
| T1-04 | `x = x + 1` → `x += 1`               | 2     | [x] Fixed   |
| T1-09 | `while` counter → `for` range        | 19    | [x] Fixed   |
| T2-01 | `public(friend)` → `friend fun`      | 66    | [x] Fixed   |
| T3-03 | `coin` → `fungible_asset`            | 12    | [ ] Skipped |
| T3-04 | Resource accounts → named objects    | 13    | [ ] Skipped |

---

## Tier 1 Findings — Syntax

These changes produce identical compiled output. Zero semantic risk.

### M-01: `vector::borrow` → Index Notation (T1-01)

- **Files**: 13 source files (87 occurrences)
- **Category**: Syntax (Move 2.0+)
- **Status**: [x] Fixed

The codebase used `*vector::borrow(&v, i)` for all vector element access. Move 2.0 introduced index notation `v[i]` which compiles identically but is more readable.

**Before:**

```move
let asset = *vector::borrow(&assets, i);
let config = vector::borrow(&config_inputs, i);  // reference form
```

**After:**

```move
let asset = assets[i];
let config = &config_inputs[i];  // reference form
```

**Locations fixed:**

| File                                 | Count |
| ------------------------------------ | ----- |
| `aave-data/sources/v1.move`          | 16    |
| `rewards_controller.move`            | 13    |
| `pool_configurator.move`             | 12    |
| `v1_deployment.move`                 | 10    |
| `emission_manager.move`              | 8     |
| `oracle.move`                        | 8     |
| `ui_incentive_data_provider_v3.move` | 6     |
| `flashloan_logic.move`               | 4     |
| `pool_data_provider.move`            | 3     |
| `large_packages.move`                | 2     |
| `rewards_distributor.move`           | 2     |
| `ui_pool_data_provider_v3.move`      | 2     |
| `pool_token_logic.move`              | 1     |

---

### M-02: `vector::borrow_mut` → Mutable Index Notation (T1-02)

- **File**: `sources/aave-periphery/rewards_controller.move`
- **Category**: Syntax (Move 2.0+)
- **Status**: [x] Fixed

3 occurrences of `vector::borrow_mut(&mut v, i)` replaced with `&mut v[i]`.

**Before:**

```move
let elem = vector::borrow_mut(&mut unclaimed_amounts, r);
```

**After:**

```move
let elem = &mut unclaimed_amounts[r];
```

---

### M-03: Compound Add Assignment (T1-04)

- **Files**: `aave-config/sources/user_config.move`, `aave-math/sources/wad_ray_math.move`
- **Category**: Syntax (Move 2.1+)
- **Status**: [x] Fixed

2 occurrences of `x = x + 1` replaced with `x += 1`.

**Before:**

```move
id = id + 1;   // user_config.move
b = b + 1;     // wad_ray_math.move
```

**After:**

```move
id += 1;
b += 1;
```

---

### M-04: While Counter Loops → For Range Loops (T1-09)

- **Files**: 3 source files (19 occurrences)
- **Category**: Syntax (Move 2.0+)
- **Status**: [x] Fixed

Counter-based `while` loops converted to `for` range loops, eliminating boilerplate counter initialization and increment.

**Before:**

```move
let i = 0;
while (i < vector::length(&keys)) {
    let key = *vector::borrow(&keys, i);
    // ... body ...
    i = i + 1;
};
```

**After:**

```move
for (i in 0..vector::length(&keys)) {
    let key = keys[i];
    // ... body ...
};
```

**Locations fixed:**

| File                        | Count | Notes                                   |
| --------------------------- | ----- | --------------------------------------- |
| `aave-data/sources/v1.move` | 16    | Data deployment loops                   |
| `large_packages.move`       | 2     | Code chunk iteration, module index loop |
| `generic_logic.move`        | 1     | Reserve iteration with continue/break   |

**Not converted** (correct `while` usage):

- `user_config.move` — bit-shifting loop with dynamic termination (`while (first_asset_position != 0)`)

---

## Tier 2 Findings — Visibility

Same semantics, cleaner declarations. Purely syntactic shorthand.

### M-05: `public(friend) fun` → `friend fun` (T2-01)

- **Files**: 15 source files (66 occurrences)
- **Category**: Visibility (Move 2.0+)
- **Status**: [x] Fixed

Move 2.0 introduced `friend fun` as shorthand for `public(friend) fun` — identical semantics, shorter syntax.

**Before:**

```move
public(friend) fun set_apt_fee(
    caller: &signer, asset: address, new_apt_fee: u64
) acquires FeeConfig, FeeConfigMetadata {
```

**After:**

```move
friend fun set_apt_fee(
    caller: &signer, asset: address, new_apt_fee: u64
) acquires FeeConfig, FeeConfigMetadata {
```

**Locations fixed:**

| File                                          | Count |
| --------------------------------------------- | ----- |
| `pool.move`                                   | 18    |
| `rewards_controller.move`                     | 10    |
| `a_token_factory.move`                        | 8     |
| `token_base.move`                             | 6     |
| `variable_debt_token_factory.move`            | 5     |
| `events.move`                                 | 4     |
| `emode_logic.move`                            | 2     |
| `isolation_mode_logic.move`                   | 2     |
| `pool_fee_manager.move`                       | 2     |
| `pool_logic.move`                             | 2     |
| `pool_token_logic.move`                       | 2     |
| `default_reserve_interest_rate_strategy.move` | 2     |
| `borrow_logic.move`                           | 1     |
| `fungible_asset_manager.move`                 | 1     |
| `transfer_strategy.move`                      | 1     |

**Not converted:**

- 1 occurrence in `tests/aave-periphery/rewards_system/helper_account.move` — test files excluded from modernization

---

## Tier 3 Findings — API Migrations (Not Applied)

These findings were identified but **skipped** because they are all breaking changes requiring redeployment.

### M-06: Resource Accounts → Named Objects (T3-04)

- **Files**: 5 source files (13 occurrences of `SignerCapability`)
- **Category**: Architecture
- **Status**: [ ] Skipped — Breaking change, requires redeployment

Modules using `create_resource_account` and `SignerCapability`:

- `oracle.move`
- `a_token_factory.move`
- `transfer_strategy.move`
- `collector.move`
- `pool_fee_manager.move`

**Why skipped:** Converting resource accounts to named objects changes the on-chain authority model. All existing resource account addresses would change, breaking deployed state. Only viable on fresh deploy.

---

### M-07: `aptos_framework::coin` → `fungible_asset` (T3-03)

- **Files**: 12 files (mostly test helpers, 1 source file)
- **Category**: API Migration
- **Status**: [ ] Skipped — Breaking change, requires redeployment

The `coin` module is used specifically for APT transfers in `pool_fee_manager.move`. The remaining usages are in test infrastructure.

**Why skipped:** APT is still commonly accessed via the coin module in Aptos. Migration to `fungible_asset` would change the fee collection API and require updating all callers. Only viable on fresh deploy.

---

## Test Results

| Metric   | Baseline | After Modernization |
| -------- | -------- | ------------------- |
| Tests    | 887      | 887                 |
| Passing  | 887      | 887                 |
| Failed   | 0        | 0                   |
| Coverage | 98.05%   | 98.06%              |

Tests were verified after each tier:

1. Tier 1 applied → 887/887 passing
2. Tier 2 applied → 887/887 passing

---

## Files Modified

29 source files across 7 packages:

| Package               | Files Modified | Changes             |
| --------------------- | -------------- | ------------------- |
| `aave-data`           | 2              | T1-01, T1-09        |
| `aave-oracle`         | 1              | T1-01               |
| `aave-large-packages` | 1              | T1-01, T1-09        |
| `aave-config`         | 1              | T1-04               |
| `aave-math`           | 1              | T1-04               |
| `aave-pool`           | 7              | T1-01, T2-01        |
| `aave-logic`          | 4              | T1-01, T1-09, T2-01 |
| `aave-periphery`      | 6              | T1-01, T1-02, T2-01 |
| `aave-events`         | 1              | T2-01               |
| `aave-tokens`         | 4              | T2-01               |

### Full file list

```
aave-core/aave-config/sources/user_config.move
aave-core/aave-data/sources/v1.move
aave-core/aave-data/sources/v1_deployment.move
aave-core/aave-large-packages/sources/large_packages.move
aave-core/aave-math/sources/wad_ray_math.move
aave-core/aave-oracle/sources/oracle.move
aave-core/sources/aave-events/events.move
aave-core/sources/aave-logic/borrow_logic.move
aave-core/sources/aave-logic/emode_logic.move
aave-core/sources/aave-logic/flashloan_logic.move
aave-core/sources/aave-logic/generic_logic.move
aave-core/sources/aave-logic/isolation_mode_logic.move
aave-core/sources/aave-periphery/emission_manager.move
aave-core/sources/aave-periphery/rewards_controller.move
aave-core/sources/aave-periphery/rewards_distributor.move
aave-core/sources/aave-periphery/transfer_strategy.move
aave-core/sources/aave-periphery/ui_incentive_data_provider_v3.move
aave-core/sources/aave-periphery/ui_pool_data_provider_v3.move
aave-core/sources/aave-pool/default_reserve_interest_rate_strategy.move
aave-core/sources/aave-pool/pool.move
aave-core/sources/aave-pool/pool_configurator.move
aave-core/sources/aave-pool/pool_data_provider.move
aave-core/sources/aave-pool/pool_fee_manager.move
aave-core/sources/aave-pool/pool_logic.move
aave-core/sources/aave-pool/pool_token_logic.move
aave-core/sources/aave-tokens/a_token_factory.move
aave-core/sources/aave-tokens/fungible_asset_manager.move
aave-core/sources/aave-tokens/token_base.move
aave-core/sources/aave-tokens/variable_debt_token_factory.move
```
