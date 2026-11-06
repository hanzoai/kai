# Kai Duel

A Godot 4.2+ example where Kai chooses each player's next move.

Godot's ordinary (non-.NET) edition is enough: the game is written in GDScript.

## Run

Offline rules and parser tests:

```bash
godot --headless --path examples/godot --script tests/test_duel.gd
```

Live game against hosted Kai:

```bash
HANZO_API_KEY=... KAI_MODEL=kai godot --path examples/godot
```

Optional environment variables:

- `HANZO_API_KEY` - required for the hosted default
- `KAI_MODEL` - defaults to `kai`
- `HANZO_BASE_URL` - defaults to `https://api.hanzo.ai`

## Loopback mode

For a no-hosted-service run, start a local Kai checkpoint:

```bash
cd /Users/z/work/hanzo/decision
cargo run -p kai -- serve --addr 127.0.0.1:8080 --models /absolute/path/to/preseeded-kai-checkpoint --device cpu
```

Then run:

```bash
HANZO_BASE_URL=http://127.0.0.1:8080 godot --path examples/godot
```

The bearer header is omitted when `HANZO_API_KEY` is unset, which is appropriate only for loopback.

## Rules

Each round, Kai chooses one action for each player from the same visible state:

- `strike`: spend 1 energy; deal 3 damage, reduced by 2 against `guard`
- `guard`: reduce incoming strike damage by 2
- `charge`: gain 2 energy, capped at 5
- `recover`: heal 2 HP, capped at 10; unavailable for 2 rounds

The game validates both returned choices locally. An illegal choice or failed request stops auto-play and is reported; the game does not silently substitute a local move.

## Design

- `scripts/duel.gd` contains only game rules.
- `scripts/kai_client.gd` contains only HTTP and response validation.
- `scripts/main.gd` contains only UI and round flow.
- One request carries both `p1_move` and `p2_move`, so both players decide from the same state.
- Kai returns probabilities, not explanations; the UI shows probabilities and confidence only.
