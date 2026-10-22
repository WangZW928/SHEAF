#!/usr/bin/env python3
"""Read-only dependency checks plus temporary GNU-tool capability checks."""
import ast
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
failures = []


def check(label, passed, detail=""):
    print(f"{'OK' if passed else 'FAIL'} {label}: {detail}")
    if not passed:
        failures.append(label)


def run(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True, timeout=30, **kwargs)


check("platform", platform.system() == "Darwin", f"{platform.system()} {platform.machine()}")
check("environment", os.environ.get("SHEAF_PLATFORM") == "macos", "use environments/macos/run.sh")
check("Python >= 3.12", sys.version_info >= (3, 12), sys.version.split()[0])
commands = ["bash", "tmux", "elan", "lean", "lake", "git", "curl", "rsync",
            "cp", "find", "realpath", "grep", "timeout", "md5sum"]
for name in commands:
    check(name, shutil.which(name) is not None, shutil.which(name) or "not found")
check("agent CLI", any(shutil.which(n) for n in ("codex", "claude")), "Codex or Claude Code")
check("Lean skill", (ROOT / ".agents/skills/lean4/SKILL.md").is_file())
check("Lean helper runtime", shutil.which("lean4-skills-sorry-analyzer") is not None)
if failures:
    sys.exit(1)

r = run(["bash", "-c", 'mapfile -t a < <(printf "one\\ntwo\\n"); test "${#a[@]}" = 2'])
check("Bash mapfile", r.returncode == 0, r.stderr.strip())
with tempfile.TemporaryDirectory(prefix="sheaf-doctor-") as tmp:
    base = Path(tmp)
    (base / "source").mkdir()
    (base / "source/a").write_text("ok")
    r = run(["cp", "-a", "--reflink=auto", str(base / "source"), str(base / "copy")])
    check("GNU cp copy", r.returncode == 0 and (base / "copy/a").is_file(), r.stderr.strip())
    (base / "mirror").mkdir()
    r = run(["cp", "-asn", str(base / "source"), str(base / "mirror")])
    check("GNU cp symlink mirror", r.returncode == 0 and (base / "mirror/source/a").is_symlink(), r.stderr.strip())
    r = run(["realpath", "-m", str(base / "missing/child")])
    check("GNU realpath", r.returncode == 0, r.stderr.strip())
    r = run(["find", tmp, "-xtype", "l"])
    check("GNU find", r.returncode == 0, r.stderr.strip())
r = run(["grep", "-oP", r"^theorem\s+\K[^\s({\[:]+"], input="theorem example_name : True\n")
check("GNU grep PCRE", r.returncode == 0 and r.stdout.strip() == "example_name", r.stderr.strip())
r = run(["date", "+%s.%N"])
check("GNU date precision", r.returncode == 0 and "N" not in r.stdout, r.stdout.strip())
for p in sorted((ROOT / "template/tools").glob("*.py")):
    try:
        ast.parse(p.read_text(), filename=str(p))
        check(p.name, True, "Python syntax")
    except SyntaxError as e:
        check(p.name, False, str(e))
for p in sorted((ROOT / "template/tools").glob("*.sh")):
    r = run(["bash", "-n", str(p)])
    check(p.name, r.returncode == 0, r.stderr.strip() or "Bash syntax")
r = run(["elan", "toolchain", "list"])
baseline = next(line.split("=", 1)[1] for line in
                (ROOT / "environments/macos/versions.env").read_text().splitlines()
                if line.startswith("SHEAF_BASELINE_LEAN="))
installed = r.returncode == 0 and baseline in r.stdout
check("Lean baseline installed", installed, r.stdout.strip() or r.stderr.strip())
if installed:
    for command in ("lean", "lake"):
        r = run([command, f"+{baseline}", "--version"], cwd=ROOT)
        check(command + " version", r.returncode == 0, (r.stdout + r.stderr).strip())
print(f"\n{'READY' if not failures else 'NOT READY'}: development runtime, {len(failures)} failed checks")
print("NOTE: final sandboxed lake comparator verification requires Linux/bwrap; not validated on native macOS.")
sys.exit(bool(failures))
