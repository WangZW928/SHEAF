#!/bin/bash
# Execute a command with SHEAF's Windows (WSL2) dependencies, without editing shell profiles.
set -euo pipefail
[ "$(uname -s)" = Linux ] || { echo 'This entry point is for WSL2/Linux only.' >&2; exit 2; }
SHEAF_REPO=$(cd "$(dirname "$0")/../.." && pwd)
case "$SHEAF_REPO" in
  /mnt/*|/media/*)
    echo 'The SHEAF checkout must stay on the WSL2 filesystem, not a Windows drive.' >&2
    echo 'Clone it under your Linux home, e.g. ~/SHEAF. See environments/windows/README.md.' >&2
    exit 2
    ;;
esac
if ! grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null; then
  echo 'NOTE: not running under WSL2; this environment targets Windows via WSL2.' >&2
fi
export SHEAF_PLATFORM=windows
export ELAN_HOME="$SHEAF_REPO/.local/windows/elan"
export VIRTUAL_ENV="$SHEAF_REPO/.local/windows/venv"
export MATHLIB_CACHE_DIR="$SHEAF_REPO/.local/windows/mathlib-cache"
export LEAN4_PLUGIN_ROOT="$SHEAF_REPO/.local/windows/lean4-skills-source/plugins/lean4"
export LEAN4_SCRIPTS="$LEAN4_PLUGIN_ROOT/lib/scripts"
export LEAN4_REFS="$LEAN4_PLUGIN_ROOT/skills/lean4/references"
export PATH="$VIRTUAL_ENV/bin:$ELAN_HOME/bin:$LEAN4_PLUGIN_ROOT/bin:$PATH"
[ -x "$VIRTUAL_ENV/bin/python3" ] || { echo 'Run environments/windows/bootstrap.sh first.' >&2; exit 2; }
if [ "$#" -eq 0 ]; then
  exec bash --noprofile --norc -i
fi
exec "$@"
