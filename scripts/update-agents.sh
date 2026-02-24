#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
#  update-agents.sh — Install/update AI agent skills from avaralabs/skills
#
#  Usage:
#    ./scripts/update-agents.sh                  # install for default agents
#    ./scripts/update-agents.sh claude-code       # install for claude-code only
#    ./scripts/update-agents.sh codex cursor      # install for codex and cursor
#    AGENTS="codex" ./scripts/update-agents.sh   # via env var
# ──────────────────────────────────────────────────────────────

SKILLS_REPO="avaralabs/skills"
SKILLS_CLI_VERSION="${SKILLS_CLI_VERSION:-1.3.9}"

# Default agents to install for (override via args or AGENTS env var)
DEFAULT_AGENTS=("claude-code" "codex" "cursor" "droid" "opencode" "antigravity" "github-copilot")

# Determine target agents: CLI args > env var > defaults
if [[ $# -gt 0 ]]; then
  AGENTS=("$@")
elif [[ -n "${AGENTS:-}" ]]; then
  read -ra AGENTS <<< "$AGENTS"
else
  AGENTS=("${DEFAULT_AGENTS[@]}")
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║  Updating AI Agent Skills                        ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Repo:   ${SKILLS_REPO}"
echo "║  Agents: ${AGENTS[*]}"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Build the agent flags: -a claude-code -a codex ...
AGENT_FLAGS=()
for agent in "${AGENTS[@]}"; do
  AGENT_FLAGS+=("-a" "$agent")
done

# Install all skills from the repo, non-interactively (npx fetches the CLI automatically)
echo "→ Installing all skills for: ${AGENTS[*]} (skills CLI v${SKILLS_CLI_VERSION})..."
npx "skills@${SKILLS_CLI_VERSION}" add "${SKILLS_REPO}" \
  --skill '*' \
  "${AGENT_FLAGS[@]}" \
  -y

echo ""
echo "✓ Agent skills updated successfully"
