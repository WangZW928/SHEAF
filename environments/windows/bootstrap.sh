#!/bin/bash
# Re-runnable WSL2 (Windows) setup. Proxy settings, if needed, are inherited from the caller.
set -euo pipefail
[ "$(uname -s)" = Linux ] || { echo 'WSL2/Linux only; see environments/README.md.' >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WINDOWS="$ROOT/environments/windows"
# One pin set for all platforms; do not copy it (environments/README.md).
source "$ROOT/environments/macos/versions.env"

PACKAGES="tmux bash coreutils findutils grep git curl wget rsync python3 python3-venv build-essential"
missing=""
for pkg in $PACKAGES; do
  dpkg -s "$pkg" 2>/dev/null | grep -q '^Status: install ok installed' || missing="$missing $pkg"
done
if [ -n "$missing" ]; then
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    if sudo -n true 2>/dev/null; then
      SUDO=sudo
    else
      echo "Missing apt packages:$missing" >&2
      echo 'Install them with: sudo apt-get update && sudo apt-get install -y <packages>' >&2
      exit 2
    fi
  fi
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update
  # shellcheck disable=SC2086
  $SUDO apt-get install -y --no-install-recommends $PACKAGES
fi

mkdir -p "$ROOT/.local/windows"
if [ ! -x "$ROOT/.local/windows/venv/bin/python3" ]; then
  python3 -m venv "$ROOT/.local/windows/venv"
fi
export ELAN_HOME="$ROOT/.local/windows/elan"
if [ ! -x "$ELAN_HOME/bin/elan" ]; then
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$ELAN_HOME/bin"
  if curl -sSf -m 30 \
      https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
      -o "$TMP/elan-init.sh"; then
    sh "$TMP/elan-init.sh" -y --no-modify-path --default-toolchain "$SHEAF_BASELINE_LEAN"
  else
    echo 'raw.githubusercontent.com unreachable; using the elan release binary instead.' >&2
    url=$(curl -sSf https://api.github.com/repos/leanprover/elan/releases/latest | python3 -c \
      'import json,sys; print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"]=="elan-x86_64-unknown-linux-gnu.tar.gz"))')
    curl -sSfL "$url" -o "$TMP/elan.tgz"
    tar -xzf "$TMP/elan.tgz" -C "$ELAN_HOME/bin"
    chmod +x "$ELAN_HOME/bin/elan"
  fi
fi
RUN="$WINDOWS/run.sh"
"$RUN" elan toolchain install "$SHEAF_BASELINE_LEAN"
# This default belongs only to the repository-local ELAN_HOME.
"$RUN" elan default "$SHEAF_BASELINE_LEAN"
SRC="$ROOT/.local/windows/lean4-skills-source"
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
  ln -s ../../.local/windows/lean4-skills-source/plugins/lean4/skills/lean4 "$DEST"
fi
"$RUN" python3 "$WINDOWS/doctor.py"
