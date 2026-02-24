#!/usr/bin/env python3
"""Handler template for openclaw-skill-ansible.
This file receives a task JSON on stdin or via file, validates it against schemas/task.schema.json,
and dispatches to local action scripts in actions/.
"""
import json
import sys
import os
from pathlib import Path

SCHEMA_PATH = Path(__file__).resolve().parents[1] / 'schemas' / 'task.schema.json'
ACTIONS_DIR = Path(__file__).resolve().parents[1] / 'actions'


def load_task(path):
    with open(path) as f:
        return json.load(f)


def dispatch(task):
    action = task.get('action')
    script = ACTIONS_DIR / f"{action}.sh"
    if script.exists():
        cmd = f"/bin/bash {script} '{json.dumps(task)}'"
        rc = os.system(cmd)
        return rc
    else:
        print(f"Unknown action: {action}")
        return 2


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: handler.py /path/to/task.json')
        sys.exit(1)
    task_path = sys.argv[1]
    task = load_task(task_path)
    rc = dispatch(task)
    sys.exit(rc)
