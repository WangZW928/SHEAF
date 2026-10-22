#!/bin/bash
# Execute a command with SHEAF's macOS dependencies, without editing shell profiles.
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo 'This entry point is for macOS only.' >&2; exit 2; }
SHEAF_REPO=$(cd "$(dirname "$0")/../.." && pwd)
if [ -x /opt/homebrew/bin/brew ]; then
  SHEAF_BREW=/opt/homebrew
elif [ -x /usr/local/bin/brew ]; then
  SHEAF_BREW=/usr/local
else
  echo 'Homebrew is required. See environments/macos/README.md.' >&2; exit 2
fi
export SHEAF_PLATFORM=macos
export ELAN_HOME="$SHEAF_REPO/.local/macos/elan"
export VIRTUAL_ENV="$SHEAF_REPO/.local/macos/venv"
export MATHLIB_CACHE_DIR="$SHEAF_REPO/.local/macos/mathlib-cache"
export LEAN4_PLUGIN_ROOT="$SHEAF_REPO/.local/macos/lean4-skills-source/plugins/lean4"
export LEAN4_SCRIPTS="$LEAN4_PLUGIN_ROOT/lib/scripts"
export LEAN4_REFS="$LEAN4_PLUGIN_ROOT/skills/lean4/references"
export PATH="$VIRTUAL_ENV/bin:$SHEAF_BREW/opt/bash/bin:$SHEAF_BREW/opt/coreutils/libexec/gnubin:$SHEAF_BREW/opt/findutils/libexec/gnubin:$SHEAF_BREW/opt/grep/libexec/gnubin:$SHEAF_BREW/bin:$ELAN_HOME/bin:$LEAN4_PLUGIN_ROOT/bin:$PATH"
[ -x "$VIRTUAL_ENV/bin/python3" ] || { echo 'Run environments/macos/bootstrap.sh first.' >&2; exit 2; }
if [ "$#" -eq 0 ]; then
  exec bash --noprofile --norc -i
fi
exec "$@"
