# Windows environment — not configured

This directory reserves a separate Windows setup. The current Mac installation
does not establish Windows support.

SHEAF currently uses POSIX shell scripts, `fcntl` locks, symbolic links, tmux and
Unix process groups. Plan to run the tools inside WSL2/Linux and keep projects on
the WSL filesystem. Native PowerShell support would require additional changes
and testing. Do not run `environments/macos/bootstrap.sh` on Windows.

When a Windows host is available, add its installer, dependency checks and smoke
test results here. Reuse project source and version pins, not Mac binaries/caches.
