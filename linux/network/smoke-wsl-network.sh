#!/usr/bin/env bash
set -euo pipefail

echo "[wsl-smoke] hostname: $(hostname)"
echo "[wsl-smoke] kernel: $(uname -a)"

TARGETS=("1.1.1.1" "8.8.8.8")
for t in "${TARGETS[@]}"; do
  if ping -c 1 -W 2 "$t" >/dev/null 2>&1; then
    echo "[wsl-smoke] ping $t: OK"
  else
    echo "[wsl-smoke] ping $t: FAIL" >&2
  fi
done

if command -v ip >/dev/null 2>&1; then
  echo "[wsl-smoke] interfaces:"
  ip -br a
else
  echo "[wsl-smoke] ip command not found" >&2
fi
