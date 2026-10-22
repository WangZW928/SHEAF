#!/usr/bin/env python3
"""Exercise real SHEAF tools in an isolated, generated Lean project (no AI sessions)."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / ".local/windows"


def run(args, cwd, expected=0, **kw):
    r = subprocess.run([str(x) for x in args], cwd=cwd, text=True,
                       capture_output=True, timeout=180, **kw)
    print("$", " ".join(str(x) for x in args), flush=True)
    if r.stdout:
        print(r.stdout.rstrip(), flush=True)
    if r.returncode != expected:
        raise RuntimeError(f"exit {r.returncode}, expected {expected}: {r.stderr}")
    return r


with tempfile.TemporaryDirectory(prefix="smoke-", dir=LOCAL) as temp:
    project = Path(temp)
    shutil.copytree(ROOT / "template/tools", project / "tools")
    (project / "coord").mkdir()
    (project / "dag/nodes").mkdir(parents=True)
    (project / "lean").mkdir()
    (project / "coord/sheaf.env").write_text(
        "SHEAF_LIB=Smoke\nSHEAF_BUILD_WAIT=0\nSHEAF_BUILD_POLL=0.1\n")
    run(["git", "init", "-q"], project)
    run(["git", "config", "user.name", "SHEAF environment check"], project)
    run(["git", "config", "user.email", "sheaf-env@example.invalid"], project)
    (project / ".gitignore").write_text("local/\n__pycache__/\nlean/.lake/\nlean/.sandbox/\n")
    run(["lake", "init", "Smoke", "lib"], project / "lean")
    run(["lake", "build"], project / "lean")
    run(["python3", "tools/claim.py", "take", "WIN1", "environment-check"], project)
    run(["python3", "tools/claim.py", "take", "WIN2", "environment-check"], project, expected=1)
    run(["python3", "tools/claim.py", "release", "WIN1", "environment-check", "smoke complete"], project)
    run(["python3", "tools/dag_queue.py", "summary"], project)
    run(["python3", "tools/queue.py", "write"], project)
    run(["python3", "tools/build.py"], project)
    last = json.loads((project / "local/builds/last.json").read_text())
    assert last["result"] == "green", last
    sandbox = project / "lean/.sandbox/WIN1/Smoke"
    sandbox.mkdir(parents=True)
    # Imports/checks only: this test does not formalize any mathematical target.
    imported = sandbox / "Imported.lean"
    imported.write_text("import Smoke.Basic\n#check Nat\n")
    group_env = dict(os.environ, SHEAF_GROUP="WIN1")
    run(["tools/lean_file.sh", "lean/Smoke/Basic.lean"], project, env=group_env)
    run(["tools/lean_file.sh", imported], project, env=group_env)
    run(["tools/land.sh", imported, "lean/Smoke/Imported.lean"], project, env=group_env)
    run(["python3", "tools/build.py"], project)
    last = json.loads((project / "local/builds/last.json").read_text())
    assert last["result"] == "green" and last["verified"], last
    # Each test owns a separate socket; no existing tmux server is touched.
    socket = project / "tmux.sock"
    try:
        run(["tmux", "-S", socket, "-f", "/dev/null", "new-session", "-d",
             "-s", "sheaf-windows-smoke", "-c", project, "sleep 60"], project)
        health = run(["tools/session_health.sh"], project,
                     env=dict(os.environ, TMUX=f"{socket},0,0"))
        assert "sheaf-windows-smoke OK" in health.stdout, health.stdout
    finally:
        subprocess.run(["tmux", "-S", str(socket), "kill-server"],
                       capture_output=True, timeout=10)
print("PASS: Lean build, claims, queue, shared build, worker mirror, landing, tmux health")
