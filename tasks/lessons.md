# Lessons Learned

<!-- Claude updates this file automatically after corrections. Review at session start. -->
<!-- If a mistake repeats, escalate the rule to CLAUDE.md -->

## Move / Aptos

- `npm install --no-save` can fail on newer npm versions (11.x) — use `npx` with pinned version instead
- `aptos move fmt` requires `--config-path ./movefmt.toml` and `--emit-mode "overwrite"` flags
- Error codes in `error_config.move` must use public getter functions — never reference raw constants from other modules
- `SmartTable` is the standard collection type, not `Table`
- `inline fun` for small accessor helpers avoids call overhead

## Tooling

- Skills CLI (`npx skills@<version>`) handles its own fetching — no need for a separate `npm install` step
- Aptos LLM docs (`llms-full.txt` and `llms-small.txt`) are both ~58k lines — too large for `@` auto-include in CLAUDE.md
