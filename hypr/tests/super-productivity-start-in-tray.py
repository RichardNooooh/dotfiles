#!/usr/bin/python
"""Mocked checks for the Super Productivity login helper."""

import contextlib
import json
import runpy
import subprocess
import time
import urllib.request
from pathlib import Path
from unittest.mock import patch


HELPER = Path(__file__).parents[2] / "bin/.local/bin/super-productivity-start-in-tray"
LUA_CLOSE = 'hl.dsp.window.close({window = "class:superproductivity"})'


class Response:
    def __init__(self, ready):
        self.ready = ready

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def read(self, *_):
        return json.dumps({"data": {"rendererReady": self.ready}}).encode()


def run_helper(readiness):
    calls = []

    def urlopen(url, timeout):
        calls.append(("urlopen", url, timeout))
        return Response(readiness.pop(0))

    class Process:
        def poll(self):
            return None

    def popen(command, start_new_session):
        calls.append(("popen", command, start_new_session))
        return Process()

    def check_output(command):
        calls.append(("check_output", command))
        return b'[{"class": "superproductivity"}]'

    def run(command, check):
        calls.append(("run", command, check))

    with contextlib.suppress(SystemExit), \
         patch.object(urllib.request, "urlopen", urlopen), \
         patch.object(subprocess, "Popen", popen), \
         patch.object(subprocess, "check_output", check_output), \
         patch.object(subprocess, "run", run), \
         patch.object(time, "sleep", lambda _: calls.append(("sleep",))):
        runpy.run_path(str(HELPER), run_name="__main__")
    return calls


# A not-yet-ready app is started once, then its window is closed through the
# Lua-evaluation endpoint so the application's tray setting handles the hide.
calls = run_helper([False, True])
assert ("popen", ["super-productivity"], True) in calls
assert ("check_output", ["hyprctl", "clients", "-j"]) in calls
assert ("run", ["hyprctl", "eval", LUA_CLOSE], True) in calls
assert not any(call[0] == "sleep" for call in calls)

# A ready instance is left alone: no launch, client listing, or close request.
calls = run_helper([True])
assert calls == [("urlopen", "http://127.0.0.1:3876/health", 1)]

print("super-productivity tray helper mocked checks: ok")
