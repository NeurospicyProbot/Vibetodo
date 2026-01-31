#!/usr/bin/env sh
# Setup script for git hooks
#
# Usage: ./scripts/setup-hooks.sh
#
# This installs the pre-commit hook that runs formatting and tests
# before each commit, ensuring CI won't fail on basic issues.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DEST="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Install pre-commit hook
if [ -f "$HOOKS_SRC/pre-commit" ]; then
    cp "$HOOKS_SRC/pre-commit" "$HOOKS_DEST/pre-commit"
    chmod +x "$HOOKS_DEST/pre-commit"
    echo "  ✓ Installed pre-commit hook"
fi

echo ""
echo "Done! Git hooks installed."
echo ""
echo "The pre-commit hook will run before each commit:"
echo "  - mix format --check-formatted"
echo "  - mix compile --warnings-as-errors"
echo "  - mix test"
echo ""
echo "To skip hooks (not recommended): git commit --no-verify"
