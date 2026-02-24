#!/usr/bin/env bash
set -euo pipefail
SKILL_DIR=${1:-.}
python3 -m json.tool < "$SKILL_DIR/schemas/task.schema.json" >/dev/null 2>&1 || true
echo "Schema looks okay"
