#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
#  download-llms.sh — Download LLM-ready documentation files
#
#  Usage:
#    ./scripts/download-llms.sh
# ──────────────────────────────────────────────────────────────

LLMS_DIR="llms"

echo "→ Downloading Aptos LLM documentation into ${LLMS_DIR}/..."
mkdir -p "${LLMS_DIR}"
curl -sL -o "${LLMS_DIR}/aptos-llms-full.txt" https://aptos.dev/llms-full.txt

LINE_COUNT=$(wc -l < "${LLMS_DIR}/aptos-llms-full.txt")
echo "✓ Downloaded aptos-llms-full.txt (${LINE_COUNT} lines)"
