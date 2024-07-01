# Aave V3 Test Framework

## 1. Install dependencies

```bash=
cd test-suites
pnpm i
```

## 2. Create test Acoount

```bash
cd crest
make init-test-profiles
```

## 3. Init Test Data

```bash=
cd test-suites
pnpm init-data
```

## 4. Test

```bash
cd test-suites
pnpm test:logic
```