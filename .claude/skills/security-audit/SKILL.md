---
name: security-audit
description: "Audits Move contracts for security vulnerabilities before deployment using a 7-category checklist: access control, input validation, object safety, reference safety, arithmetic safety, generic type safety, and test coverage. Triggers on: 'audit contract', 'security check', 'review security', 'check for vulnerabilities', 'security audit', 'is this secure', 'find security issues'."
metadata:
  category: move
  tags: ["security", "audit", "vulnerabilities", "best-practices"]
  priority: critical
---

# Security Audit Skill

Performs systematic security audits of Move contracts. Every checklist item must pass before deployment — user funds depend on correct implementation.

## Core Workflow

Review ALL categories in order:

1. **Access Control** - Who can call functions?
2. **Input Validation** - Are inputs checked?
3. **Object Safety** - Object model used correctly?
4. **Reference Safety** - No dangerous references exposed?
5. **Arithmetic Safety** - Overflow/underflow prevented?
6. **Generic Type Safety** - Phantom types used correctly?
7. **Testing** - 100% coverage achieved?

### Access Control

**Verify:**

- [ ] All `entry` functions verify signer authority
- [ ] Object ownership checked with `object::owner()`
- [ ] Admin functions check caller is admin
- [ ] Function visibility uses least-privilege
- [ ] No public functions modify state without checks

```move
// ✅ Signer verification
public entry fun update_config(admin: &signer, value: u64) acquires Config {
    let config = borrow_global<Config>(@my_addr);
    assert!(signer::address_of(admin) == config.admin, E_NOT_ADMIN);
}

// ✅ Object ownership verification
public entry fun transfer_item(
    owner: &signer, item: Object<Item>, to: address
) acquires Item {
    assert!(object::owner(item) == signer::address_of(owner), E_NOT_OWNER);
}
```

### Input Validation

- [ ] Numeric inputs checked for zero and max limits
- [ ] Vector and string lengths validated
- [ ] Addresses validated: `assert!(addr != @0x0, E_ZERO_ADDRESS)`
- [ ] Enum-like values in range

```move
// ✅ Comprehensive validation
public entry fun deposit(user: &signer, amount: u64) acquires Account {
    assert!(amount > 0, E_ZERO_AMOUNT);
    assert!(amount <= MAX_DEPOSIT_AMOUNT, E_AMOUNT_TOO_HIGH);
    let account = borrow_global_mut<Account>(signer::address_of(user));
    assert!(account.balance <= MAX_U64 - amount, E_OVERFLOW);
    account.balance = account.balance + amount;
}
```

### Object Safety

- [ ] ConstructorRef never returned from public functions
- [ ] All refs (TransferRef, DeleteRef, ExtendRef) generated in constructor
- [ ] Object signer only used during construction or with ExtendRef
- [ ] Ungated transfers disabled unless explicitly needed
- [ ] DeleteRef only generated for truly burnable objects

```move
// ✅ Return Object<T>, never ConstructorRef
public fun create_item(creator: &signer): Object<Item> {
    let constructor_ref = object::create_object(signer::address_of(creator));
    let transfer_ref = object::generate_transfer_ref(&constructor_ref);
    let delete_ref = object::generate_delete_ref(&constructor_ref);
    let object_signer = object::generate_signer(&constructor_ref);
    move_to(&object_signer, Item { transfer_ref, delete_ref });
    object::object_from_constructor_ref<Item>(&constructor_ref)
}
```

### Reference Safety

- [ ] No `&mut` references exposed in public function signatures
- [ ] Critical fields protected from `mem::swap`
- [ ] Mutable borrows minimized in scope

```move
// ✅ Controlled mutations — never expose &mut publicly
public entry fun update_item_name(
    owner: &signer, item: Object<Item>, new_name: String
) acquires Item {
    assert!(object::owner(item) == signer::address_of(owner), E_NOT_OWNER);
    let item_data = borrow_global_mut<Item>(object::object_address(&item));
    item_data.name = new_name;
}
```

### Arithmetic Safety

- [ ] Additions checked for overflow
- [ ] Subtractions checked for underflow
- [ ] Division by zero prevented
- [ ] Multiplication checked for overflow

```move
// ✅ Check BEFORE arithmetic
public entry fun deposit(user: &signer, amount: u64) acquires Account {
    let account = borrow_global_mut<Account>(signer::address_of(user));
    assert!(account.balance <= MAX_U64 - amount, E_OVERFLOW);
    account.balance = account.balance + amount;
}

public entry fun withdraw(user: &signer, amount: u64) acquires Account {
    let account = borrow_global_mut<Account>(signer::address_of(user));
    assert!(account.balance >= amount, E_INSUFFICIENT_BALANCE);
    account.balance = account.balance - amount;
}
```

### Generic Type Safety

- [ ] Phantom types used for type witnesses: `struct Vault<phantom CoinType>`
- [ ] Generic constraints appropriate: `<T: copy + drop>`
- [ ] No type confusion possible

```move
// ✅ Phantom type for type-safe vaults
struct Vault<phantom CoinType> has key {
    balance: u64,
}

public fun deposit<CoinType>(vault: Object<Vault<CoinType>>, amount: u64) {
    // Type-safe: can't deposit BTC into USDC vault
}
```

### Testing

- [ ] 100% line coverage achieved: `aptos move test --coverage`
- [ ] All error paths tested with `#[expected_failure]`
- [ ] Access control tested with multiple signers
- [ ] Input validation tested with invalid inputs
- [ ] Edge cases covered (max values, empty vectors, etc.)

## Audit Report

After completing all checklist items, generate a report covering each category with ✅ PASS / ⚠️ WARNING / ❌ CRITICAL status, a summary of findings, and specific recommendations with line numbers.

## Automated Checks

```bash
aptos move compile                # Check for compilation errors
aptos move test                   # Run all tests
aptos move test --coverage        # Check coverage (must be 100%)
aptos move coverage summary       # Verify coverage report
```

## Security Rules

- Never skip the audit or deploy with < 100% test coverage
- Never approve code with critical vulnerabilities
- Never read `~/.aptos/config.yaml` or `.env` files during audits (contain private keys)
- Never display or repeat private key values found during audit

## References

**Pattern Documentation:**

- `../../../patterns/move/SECURITY.md` - Comprehensive security guide
- `../../../patterns/move/OBJECTS.md` - Object safety patterns
**Official Documentation:**

- https://aptos.dev/build/smart-contracts/move-security-guidelines

**Related Skills:**

- `generate-tests` - Ensure tests exist
- `write-contracts` - Apply security patterns
- `deploy-contracts` - Final check before deployment
