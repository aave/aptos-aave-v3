<div align="center">
    <a href="https://aptos.aave.com/">
      <img src="./assets/logo.png" alt="Logo" style="transform: scale(0.7);">
    </a>
    <h1 align="center">Aave's V3 Protocol on Aptos</h1>
    <p align="center">
        This is the official Aptos version of the Aave V3 Protocol.
    </p>
    <p align="center">
        <a href="https://github.com/aave/aptos-aave-v3/actions/workflows/unit_tests.yml">
            <img src="https://github.com/aave/aptos-aave-v3/actions/workflows/unit_tests.yml/badge.svg" alt="CI">
        </a>
        <a href="https://codecov.io/gh/aave/aptos-aave-v3">
          <img src="https://codecov.io/gh/aave/aptos-aave-v3/graph/badge.svg?token=OSHPA0N2BQ" alt="Coverage"/>
        </a>
        <a href="https://github.com/aave/aptos-aave-v3/blob/main/LICENSE">
          <img src="https://img.shields.io/badge/license-Apache--2.0-007EC7.svg" alt="License"/>
        </a>
    </p>
    <p align="center">
        <a href="https://aave.com/docs">📚 Documentation</a>
        <span>&nbsp;</span>
        <a href="https://github.com/aave/aptos-aave-v3/issues/new?labels=bug&template=bug-report---.md">🐛 Report Bug</a>
        <span>&nbsp;</span>
        <a href="https://github.com/aave/aptos-aave-v3/issues/new?labels=enhancement&template=feature-request---.md">✨ Request Feature</a>
    </p>
</div>

---

```bash=
├── aave-acl                // Access control list Package
├── aave-config             // Configurator Package
├── aave-data               // Data & Deployment Configurations
├── aave-large-packages     // Large Packages Package
├── aave-math               // Math library Package
├── aave-mock-underlyings   // Mock Underlyings Package
├── aave-oracle             // Oracle Package
├── aave-core               // Core Package
```

---

## 📊 Inter-package Dependency Graph

```mermaid
flowchart TD

  %% Level 1
  aave-config
  chainlink-data-feeds
  aave-large-packages
  aave-mock-underlyings

  %% Level 2
  aave-acl --> aave-config
  aave-math --> aave-config

  %% Level 3
  aave-oracle --> aave-config
  aave-oracle --> aave-acl
  aave-oracle --> chainlink-data-feeds

  %% Level 4
  aave-pool --> aave-acl
  aave-pool --> aave-config
  aave-pool --> aave-math
  aave-pool --> aave-oracle

  %% Level 5
  aave-data --> aave-acl
  aave-data --> aave-config
  aave-data --> aave-oracle
  aave-data --> aave-data
  aave-data --> aave-pool
```

---

## 🚀 Getting Started

### 1. 🧩 Clone the Repository

```bash
git clone https://github.com/aave/aptos-aave-v3.git && cd aptos-aave-v3
```

---

### 2. 🛠️ Prerequisites

Make sure the following tools are installed:

- [Aptos CLI](https://aptos.dev/tools/aptos-cli/)
- [yq](https://github.com/mikefarah/yq)
- [Node.js + pnpm](https://pnpm.io/installation)
- [codespell](https://pypi.org/project/codespell/)
- [pre-commit](https://pre-commit.com/#install)
- [Python 3](https://www.python.org/downloads/)
- [GNU Make](https://www.gnu.org/software/make/)

---

## 🧪 Running a Local Testnet

### 🧰 Option 1: Using Makefile

Start by copying `.env.template` to `.env` and editing any relevant values.

#### ✅ Start the testnet

```bash
make local-testnet
```

#### ✅ With indexer (e.g. for Petra Wallet support)

```bash
make local-testnet-with-indexer
```

#### 🔧 Configure workspace

```bash
make set-workspace-config \
  && make init-workspace-config \
  && make init-profiles \
  && make init-test-profiles \
  && make fund-profiles \
  && make fund-test-profiles
```

This will initialize, configure, and fund local accounts with APT.

#### 🛠️ Compile & Deploy

```bash
make compile-all
make publish-all
```

#### 🌐 View your local testnet

[https://explorer.aptoslabs.com/?network=local](https://explorer.aptoslabs.com/?network=local)

---

### 🐳 Option 2: Using `aave-test-kit` (Docker)

[`aave-test-kit`](aave-test-kit/README.md) is a local simulation environment for Aave on Aptos, inspired by Tenderly.

➡️ See the linked README for Docker-based setup and usage.

---

## 🧪 Testing

### ✅ Run Unit Tests (Move)

These do **not require a local testnet**.

```bash
make test-all
```

---

### 🔬 Run TypeScript Integration Tests

These must be run **after successful contract deployment**:

```bash
make ts-test
```

---

## 📝 Generate Aptos Move Docs

Generate full module documentation across all packages:

```bash
make doc-all
```

Docs will be generated under each package's `doc/` directory.

---

## 🧰 TypeScript SDK

A TypeScript SDK is available for interacting with the Aave V3 Protocol on Aptos directly from your applications.

### 📦 Install via npm

```bash
pnpm add @aave/aave-v3-aptos-ts-sdk
# or
npm install @aave/aave-v3-aptos-ts-sdk
```

### 📘 Explore the SDK

👉 **[View on npm](https://www.npmjs.com/package/@aave/aave-v3-aptos-ts-sdk)**
Browse available functions, types, and usage examples.

📖 For full usage details, please refer to the [README documentation](https://www.npmjs.com/package/@aave/aave-v3-aptos-ts-sdk#readme) on the npm package page.

---

## 🔐 Security Audits

All audit reports related to Aave's Move implementation on Aptos are stored in the `/audits` directory at the root of this repository.

### 📁 Audit Directory Structure

```bash
/audits
├── Certora Aave Aptos Core V3.0.2 Report.pdf
├── Certora Aave Aptos Core V3.1-V3.3 Report.pdf
├── Certora Aave Aptos Periphery V3.0.2 Report.pdf
├── Ottersec Aave Aptos V3.1-V3.3 Report.pdf
├── Spearbit Aave Aptos Core V3.0.2 Report.pdf
├── Spearbit Aave Aptos Core V3.1-V3.3 Report.pdf
└── Spearbit Aave Aptos Periphery V3.0.2 Report.pdf
```

📂 [Browse Audit Reports](/audits)

---

## 📚 Aave Move Smart Contract Docs

Official documentation for Aave's Move-based smart contracts is now available via GitHub Pages.

The docs are auto-generated from each package and published using [MkDocs Material](https://squidfunk.github.io/mkdocs-material/), with clean navigation and search.

### 📥 Explore the Docs

👉 **[View Smart Contract Documentation](https://aave.github.io/aptos-aave-v3)**
Browse all modules, structs, functions, and events used across Aave's V3 Aptos packages.

---

## 📜 Running Examples

In addition to Move unit tests and integration tests, this repository contains **example scripts** (such as flashloans) that demonstrate how to interact with the deployed protocol on Aptos. They are all located under the `./examples` packages at root level.

### 🛠️ Compile Example Scripts

Example are compiled separately via calling the main commands listed under `./examples/Makefile`:

```bash
# For testnet
make compile-scripts-testnet

# For mainnet
make compile-scripts-mainnet
```

### 🚀 Execute Example Scripts

Once compiled, scripts can be executed against the target network compiled above. For example:

```bash
# Simple flashloan example
make execute-flashloan-simple

# Complex flashloan example
make execute-flashloan-complex
```

Each script corresponds to a .mv compiled Move script under `./examples/build/AaveScripts/bytecode_scripts/`. They are executed via aptos move run-script, with arguments such as asset addresses and flashloan amounts passed in from the Makefile.

🔍 These scripts are primarily intended as examples and tests of protocol functionality, such as taking and repaying flashloans.

---

## AI Agent Skills

This project supports AI coding agents (Claude Code, Codex, Cursor, etc.) via shared skills from [avaralabs/skills](https://github.com/avaralabs/skills).

### Installing Skills

Install skills for all supported agents:

```bash
./scripts/update-agents.sh
```

Or for a specific agent only:

```bash
./scripts/update-agents.sh claude-code
./scripts/update-agents.sh codex
```

This installs skills into `.agents/skills/` with symlinks in each agent's config directory (e.g., `.claude/skills/`).

Same can be achieved using the command:

```bash
pnpm run update-agents # Install AI agent skills from avaralabs/skills
```

### LLM Documentation

Download Aptos reference documentation for AI agents (stored locally in `llms/`, gitignored):

```bash
make download-llms
# or
pnpm run download-llms
```

### Claude Code Setup

The project includes Claude Code configuration out of the box:

- `CLAUDE.md` + `PROJECT.md` — project knowledge and workflow instructions
- `.claude/settings.json` — shared plugins and permissions
- `.claude/settings.local.json` — personal overrides (not committed)

#### MCP Servers

Configured in `.mcp.json` (auto-enabled via `.claude/settings.json`):

- **Aptos** — Aptos blockchain interaction (`APTOS_BOT_KEY` env var required)
- **GitHub** — issues, PRs, project boards (`GITHUB_PERSONAL_ACCESS_TOKEN` env var required)
- **Linear** — issue tracking
- **Sentry** — error monitoring, issue lookup, stack traces (`SENTRY_AUTH_TOKEN` env var required)
- **Google Cloud** — general GCP interaction via gcloud CLI (requires `gcloud` CLI authenticated)
- **Google Cloud Storage** — GCS bucket and object operations
- **Google Cloud Observability** — logs, metrics, traces, error reports
- **Google Drive** — file access via OAuth

#### MCP Server Setup

Add required tokens to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export APTOS_BOT_KEY="your_aptos_bot_key_here"
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
export SENTRY_AUTH_TOKEN="your_sentry_token_here"
```

- **GitHub** — requires a [Personal Access Token](https://github.com/settings/tokens) with `repo`, `issues`, and `project` scopes
- **Linear** — authenticates via browser OAuth on first use (no token needed)
- **Google Cloud** — requires the `gcloud` CLI to be installed and authenticated (`gcloud auth login`)
- **Google Drive** — authenticates via browser OAuth on first use

Restart your terminal and Claude Code after adding tokens. Never commit them to the repo.
