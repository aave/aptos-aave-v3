# Claude Code Configuration

@PROJECT.md

## Aptos Reference

Full Aptos documentation is available at `llms/aptos-llms-full.txt` (read on demand when needed for Move language, Aptos framework, or SDK questions).

## Setup

```bash
npm run update-agents # Install AI agent skills from avaralabs/skills
```

### Slash Commands

- `/review-pr` — comprehensive PR review using specialized agents
- `/commit` — create a commit from staged/unstaged changes

### MCP Servers

Configured in `.mcp.json` (auto-enabled via `.claude/settings.json`):

- **Aptos** — Aptos blockchain interaction (`APTOS_BOT_KEY` env var required)
- **GitHub** — issues, PRs, project boards (`GITHUB_PERSONAL_ACCESS_TOKEN` env var required)
- **Linear** — issue tracking
- **Sentry** — error monitoring, issue lookup, stack traces (`SENTRY_AUTH_TOKEN` env var required)
- **Google Cloud** — GCP interaction via gcloud CLI (requires `gcloud` CLI authenticated)
- **Google Cloud Storage** — GCS bucket and object operations
- **Google Cloud Observability** — logs, metrics, traces, error reports
- **Google Drive** — file access via OAuth

## Git

When creating git commits, do not include the Co-Authored-By: Claude trailer.

## Workflow

When reviewing branch changes, run these checks (in parallel where possible):

1. Check for silent failures — swallowed errors, missing error handling
2. Verify code comments are accurate
3. Review any new types
4. General code review — logic, security, best practices
5. Formatting: `make fmt`
6. Linting: `make lint`
7. Tests: `make test-all` (or relevant `make test-<pkg>`)
8. Write a short summary of important changes for PR description

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
