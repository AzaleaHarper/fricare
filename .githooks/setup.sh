#!/usr/bin/env bash
set -euo pipefail

# Point git to use the checked-in hooks directory
git config core.hooksPath .githooks
echo "Git hooks configured. Pre-commit checks are now active."
