#!/usr/bin/env bash
set -euo pipefail
TASK_JSON="$1"
TASK_ID=$(echo "$TASK_JSON" | jq -r '.task_id')
ARTROOT=${OPENCLAW_ARTIFACT_ROOT:-/var/lib/openclaw/artifacts}
mkdir -p "$ARTROOT"
URL=$(echo "$TASK_JSON" | jq -r '.params.artifact_url')
NAME=$(echo "$TASK_JSON" | jq -r '.params.name')
TMP=/tmp/${TASK_ID}
mkdir -p "$TMP"
curl -fsSL "$URL" -o "$TMP/artifact.tar.gz"
# verify optional sha
if [ -n "$(echo "$TASK_JSON" | jq -r '.params.sha // ""')" ]; then
  SHA_EXPECT=$(echo "$TASK_JSON" | jq -r '.params.sha')
  SHA_ACT=$(sha256sum "$TMP/artifact.tar.gz" | awk '{print $1}')
  if [ "$SHA_EXPECT" != "$SHA_ACT" ]; then
    echo "SHA mismatch" >&2
    exit 2
  fi
fi
# install into /opt/openclaw/skills/$NAME
DEST=/opt/openclaw/skills/$NAME
mkdir -p "$DEST"
tar -xzf "$TMP/artifact.tar.gz" -C "$DEST"
# run smoke test if present
if [ -x "$DEST/test_smoke.sh" ]; then
  (cd "$DEST" && ./test_smoke.sh) || { echo "smoke test failed" >&2; exit 3; }
fi
echo "Deployed $NAME to $DEST" > "$ARTROOT/${TASK_ID}-deploy.txt"
