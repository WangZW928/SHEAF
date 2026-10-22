# Platform environments

| Platform | Status | Entry point |
| --- | --- | --- |
| macOS / Apple Silicon | Implemented; validation record in the Mac guide | [macos/README.md](macos/README.md) |
| macOS / Intel | Homebrew prefix supported; not tested on Intel hardware | [macos/README.md](macos/README.md) |
| Windows | Reserved; not installed or tested | [windows/README.md](windows/README.md) |
| Linux | Original tool assumptions; no environment provisioner here | Repository `AGENTS.md` |

Keep platform setup under `environments/<platform>/`. Keep downloaded toolchains,
virtual environments, caches and smoke projects under `.local/<platform>/`
(ignored by Git). Project `lean-toolchain`, Lake manifests and Mathlib pins remain
project-specific. Do not copy a Mac virtual environment or compiled `.olean` cache
to Windows; recreate dependencies there.
