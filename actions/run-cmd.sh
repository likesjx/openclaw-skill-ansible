#!/usr/bin/env bash
set -euo pipefail
TASK_JSON="$1"
TASK_ID=$(echo "$TASK_JSON" | jq -r '.task_id')
CMD=$(echo "$TASK_JSON" | jq -r '.params.cmd')
TIMEOUT=$(echo "$TASK_JSON" | jq -r '.params.timeout // 30')
ARTROOT=${OPENCLAW_ARTIFACT_ROOT:-/var/lib/openclaw/artifacts}
mkdir -p "$ARTROOT"
OUT="$ARTROOT/${TASK_ID}-run-cmd.json"
# run safely
timeout ${TIMEOUT}s bash -lc "$CMD" > "$ARTROOT/${TASK_ID}-stdout.log" 2> "$ARTROOT/${TASK_ID}-stderr.log" || true
cat > "$OUT" <<EOF
{
  "task_id": "$TASK_ID",
  "status": "completed",
  "stdout": "$(sed 's/"/\\"/g' "$ARTROOT/${TASK_ID}-stdout.log" | tr '\n' '\\n')",
  "stderr": "$(sed 's/"/\\"/g' "$ARTROOT/${TASK_ID}-stderr.log" | tr '\n' '\\n')"
}
EOF
