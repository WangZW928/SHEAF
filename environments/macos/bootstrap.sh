#!/bin/bash
# Re-runnable macOS setup. Proxy settings, if needed, are inherited from the caller.
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo 'macOS only; see environments/README.md.' >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT/environments/macos/versions.env"
command -v brew >/dev/null || { echo 'Install Homebrew first: https://brew.sh' >&2; exit 2; }
brew install tmux bash coreutils findutils grep elan-init python@3.14
mkdir -p "$ROOT/.local/macos"
if [ ! -x "$ROOT/.local/macos/venv/bin/python3" ]; then
  "$(brew --prefix python@3.14)/bin/python3.14" -m venv "$ROOT/.local/macos/venv"
fi
RUN="$ROOT/environments/macos/run.sh"
"$RUN" elan toolchain install "$SHEAF_BASELINE_LEAN"
# This default belongs only to the repository-local ELAN_HOME.
"$RUN" elan default "$SHEAF_BASELINE_LEAN"
SRC="$ROOT/.local/macos/lean4-skills-source"
if [ ! -d "$SRC" ]; then
  git clone https://github.com/cameronfreer/lean4-skills.git "$SRC"
  git -C "$SRC" checkout --detach "$SHEAF_LEAN4_SKILLS_REV"
elif [ "$(git -C "$SRC" rev-parse HEAD)" != "$SHEAF_LEAN4_SKILLS_REV" ]; then
  echo "Existing Lean skill checkout differs from versions.env; preserving it: $SRC" >&2
  exit 2
fi
DEST="$ROOT/.agents/skills/lean4"
if [ ! -e "$DEST" ] && [ ! -L "$DEST" ]; then
  mkdir -p "$(dirname "$DEST")"
  ln -s ../../.local/macos/lean4-skills-source/plugins/lean4/skills/lean4 "$DEST"
fi
if command -v code >/dev/null 2>&1; then
  code --install-extension leanprover.lean4
fi
"$RUN" python3 "$ROOT/environments/macos/doctor.py"
