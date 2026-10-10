#!/usr/bin/env bash
# Runs every example and recipe against api.hanzo.ai and prints a count per language.
# An example passes when it answers; a recipe passes when every answer in its
# expect.json is right. Needs HANZO_API_KEY, curl, jq, uv, node, go and cargo.
set -uo pipefail
: "${HANZO_API_KEY:?set HANZO_API_KEY}"
cd "$(dirname "$0")"

npm ci --no-audit --no-fund --loglevel=error || exit 1
py() { uv run -q --no-project --python 3.12 --with-requirements requirements.txt python "$@"; }

pass=0 fail=0 failed=0 summary=
check() { # check <label> <command...>
  local out
  if out=$("${@:2}" 2>&1); then pass=$((pass + 1)); echo "pass $1"; else fail=$((fail + 1)); echo "FAIL $1"; fi
  printf '%s\n' "$out" | sed 's/^/    /'
}
count() { # count <language>
  summary+="$1: $pass passed, $fail failed"$'\n'
  failed=$((failed + fail)) pass=0 fail=0
}

for f in examples/curl/*.sh; do check "$f" bash "$f"; done
count curl
for f in examples/python/*.py recipes/*/run.py; do check "$f" py "$f"; done
count python
for f in examples/typescript/*.ts recipes/*/run.ts; do check "$f" npx tsx "$f"; done
count typescript
check examples/go go -C examples/go run .
count go
check examples/rust cargo run -q --manifest-path examples/rust/Cargo.toml
count rust

printf '\n%s' "$summary"
[ "$failed" -eq 0 ]
