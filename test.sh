#!/usr/bin/env bash
# Runs every example and recipe against api.hanzo.ai and prints a count per language.
# An example passes when it answers; a recipe passes when every answer in its
# expect.json is right; the Claude Code plugin's tests run offline. Needs
# HANZO_API_KEY, curl, jq, uv, node, go and cargo.
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
# Offline: the plugin's hooks against a stand-in for Kai on 127.0.0.1, never the key above.
check examples/claude-code node --test examples/claude-code/test/kai.test.mjs
count claude-code

# C# is optional: build it when .NET is installed; run it only with a key.
if command -v dotnet >/dev/null 2>&1; then
  if dotnet build examples/csharp/Kai.csproj --configuration Release >/tmp/kai-csharp-build.log 2>&1; then
    check examples/csharp dotnet run --project examples/csharp/Kai.csproj --configuration Release
    count csharp
  else
    echo "FAIL examples/csharp (build)"; cat /tmp/kai-csharp-build.log | sed 's/^/    /'
    fail=$((fail + 1)); count csharp
  fi
else
  echo "csharp: skipped (.NET SDK not found)"
fi

# Godot is optional and its offline test needs no key.
if command -v godot >/dev/null 2>&1; then
  check examples/godot godot --headless --path examples/godot --script tests/test_duel.gd
  count godot
else
  echo "godot: skipped (Godot not found)"
fi

echo "vbscript: skipped on this host (requires Windows Script Host)"

printf '\n%s' "$summary"
[ "$failed" -eq 0 ]
