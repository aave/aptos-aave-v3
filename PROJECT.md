# AAVE v3 Aptos - Claude Code Configuration

## Project Overview

This is an **Aptos Move** implementation of the AAVE v3 lending protocol.

- **Language**: Move 2.3
- **Compiler**: 2.0
- **Formatter**: `movefmt.toml` (90 char width, 4 space indent)

---

## Commands

```yaml
# Testing
test-all: "make test-all"
test-acl: "make test-acl"
test-config: "make test-config"
test-math: "make test-math"
test-oracle: "make test-oracle"
test-pool: "make test-pool"
test-data: "make test-data"
test-mock-underlyings: "make test-mock-underlyings"
test-chainlink-platform: "make test-chainlink-platform"
test-chainlink-data-feeds: "make test-chainlink-data-feeds"

# Compilation
compile-all: "make compile-all"
compile-acl: "make compile-acl"
compile-config: "make compile-config"
compile-math: "make compile-math"
compile-oracle: "make compile-oracle"
compile-pool: "make compile-pool"
compile-data: "make compile-data"

# Formatting & Linting
fmt: "make fmt" # Format all (Move + Prettier + Markdown)
fmt-move: "make fmt-move" # Format Move code only
fmt-<pkg>: "make fmt-<pkg>" # Format specific package
lint: "make lint" # Run all linting
lint-prettier: "make lint-prettier" # Validate prettier formatting
lint-markdown: "make lint-markdown" # Lint markdown files
lint-codespell: "make lint-codespell" # Check spelling

# Coverage
coverage-all: "make coverage-all"
coverage-<pkg>: "make coverage-<pkg>"

# Local Development
local-testnet: "make local-testnet"
local-testnet-with-indexer: "make local-testnet-with-indexer"

# Publishing
publish-all: "make publish-all"

# TypeScript Test Suite
ts-test: "make ts-test"

# AI / LLM Setup
download-llms: "make download-llms" # Download Aptos LLM docs into llms/
update-agents: "make update-agents" # Install AI agent skills
```

---

## Package Structure

Packages in `aave-core/`:

| Package                 | Description                               |
| ----------------------- | ----------------------------------------- |
| `aave-acl`              | Access Control List management            |
| `aave-config`           | Protocol configuration                    |
| `aave-math`             | Math libraries (WadRayMath, etc.)         |
| `aave-oracle`           | Price oracle integration                  |
| `aave-pool`             | Main lending pool logic (largest package) |
| `aave-data`             | Data structures and deployment config     |
| `aave-large-packages`   | Large package deployment support          |
| `aave-mock-underlyings` | Mock tokens for testing                   |
| `chainlink-platform`    | Chainlink platform integration            |
| `chainlink-data-feeds`  | Chainlink price feed integration          |

---

## Pre-commit Hooks

Hooks run automatically on commit:

| Hook                      | Description                     |
| ------------------------- | ------------------------------- |
| `trailing-whitespace`     | Remove trailing whitespace      |
| `end-of-file-fixer`       | Ensure files end with newline   |
| `check-json`              | Validate JSON syntax            |
| `check-toml`              | Validate TOML syntax            |
| `check-added-large-files` | Block files > 3MB               |
| `detect-secrets`          | Scan for leaked secrets         |
| `format`                  | Runs `make fmt`                 |
| `check-env-secrets`       | Scan .env files for secrets     |
| `check-hardcoded-secrets` | Scan code for hardcoded secrets |
| `yamlfix`                 | Auto-format YAML files          |

Run manually: `pre-commit run --all-files`

---

## Workflow: Reviewing Branch Changes

When reviewing changes in a branch, run these checks (in parallel where possible):

1. **Check for silent failures** - Look for swallowed errors, missing error handling
2. **Verify code comments are accurate** - Comments match implementation
3. **Review any new types** - Ensure types are well-designed
4. **General code review** - Logic, security, best practices
5. **Move formatting** - Run `make fmt` (fix any issues)
6. **Linting** - Run `make lint`
7. **Tests** - Run relevant `make test-<package>` commands
8. **Write PR summary** - Short summary of important changes

### Review Checklist

```
[ ] Silent failures checked
[ ] Comments accurate
[ ] New types reviewed
[ ] General code review complete
[ ] make fmt (no changes needed)
[ ] make lint passes
[ ] Relevant tests pass
[ ] PR summary written
```

---

## Validation

For Move code changes:

```bash
make fmt && make lint && make test-all
```

For specific package changes (e.g., aave-pool):

```bash
make fmt-pool && make test-pool
```

For TypeScript test suite:

```bash
cd aave-test-suite && pnpm lint && pnpm test
```

---

## Security

- **Never commit `.env` files** - Use `.env.template` as reference
- **Secret detection** - Pre-commit hooks scan for secrets
- **Private keys** - Stored in `.env`, never hardcoded
- **Gitleaks** - Additional secret scanning via `.gitleaks.toml`
