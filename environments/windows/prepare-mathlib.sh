#!/bin/bash
# Validate a pinned Mathlib checkout; an optional module argument selects its cache.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT/environments/macos/versions.env"
RUN="$ROOT/environments/windows/run.sh"
DIR="$ROOT/.local/windows/mathlib"
if [ ! -d "$DIR" ]; then
  git clone --depth 1 --branch "$SHEAF_BASELINE_MATHLIB" \
    https://github.com/leanprover-community/mathlib4.git "$DIR"
fi
if [ "$(git -C "$DIR" rev-parse HEAD)" != "$SHEAF_BASELINE_MATHLIB_REV" ]; then
  echo "Unexpected Mathlib revision; preserving existing checkout: $DIR" >&2; exit 2
fi
cd "$DIR"
[ "$(cat lean-toolchain)" = "$SHEAF_BASELINE_LEAN" ] || { echo 'Lean/Mathlib pin mismatch' >&2; exit 2; }
# The default verifies a small real dependency tree. Pass Mathlib for the full cache.
"$RUN" lake exe cache get "${1:-Mathlib/Data/Nat/Basic.lean}"
printf 'import Mathlib.Data.Nat.Basic\n#check Nat.add_comm\n' | "$RUN" lake env lean --stdin
