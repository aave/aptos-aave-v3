# Task Tracker

<!-- Claude writes plans here with checkable items before starting implementation. -->

## Pending

- [ ] Configure `APTOS_BOT_KEY` in `.mcp.json` with actual bot API key
- [ ] Review and update `SENTRY_AUTH_TOKEN` MCP config if Sentry is not used

## Done

- [x] Fix CLAUDE.md — remove server/mobile/forge references, align with Move project
- [x] Fix `.claude/settings.json` — remove Rust/Cargo permissions, add Aptos/Move ones
- [x] Create PROJECT.md with project-specific context
- [x] Create `.mcp.json` with all MCP servers
- [x] Create `scripts/download-llms.sh` and `scripts/update-agents.sh`
- [x] Add `download-llms` and `update-agents` to Makefile and package.json
- [x] Create `.claude/agents/move-code-reviewer.md`
- [x] Download Aptos LLM docs to `llms/`
- [x] Apply all changes to `aptos-aave-gho` sibling repo
