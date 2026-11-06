class_name KaiDuel
extends RefCounted

const ROUND_CAP := 20
const MAX_HP := 10
const MAX_ENERGY := 5

var round := 0
var p1_hp := MAX_HP
var p1_energy := 3
var p1_cooldowns := {"recover": 0}
var p2_hp := MAX_HP
var p2_energy := 3
var p2_cooldowns := {"recover": 0}
var finished := false
var winner := 0 # 0 draw/unfinished, 1 player one, 2 player two
var last_summary := ""

func reset() -> void:
	round = 0
	p1_hp = MAX_HP
	p1_energy = 3
	p1_cooldowns = {"recover": 0}
	p2_hp = MAX_HP
	p2_energy = 3
	p2_cooldowns = {"recover": 0}
	finished = false
	winner = 0
	last_summary = "Reset."

func legal_actions(player: int) -> Array[String]:
	var energy := p1_energy if player == 1 else p2_energy
	var cooldowns: Dictionary = p1_cooldowns if player == 1 else p2_cooldowns
	var actions: Array[String] = []
	if energy >= 1:
		actions.append("strike")
	actions.append("guard")
	actions.append("charge")
	if int(cooldowns.get("recover", 0)) == 0:
		actions.append("recover")
	return actions

func action_criteria(player: int) -> Dictionary:
	var criteria := {}
	for action in legal_actions(player):
		match action:
			"strike":
				criteria[action] = "spend 1 energy; deal 3 damage, reduced by 2 against guard"
			"guard":
				criteria[action] = "reduce incoming strike damage by 2 this round"
			"charge":
				criteria[action] = "gain 2 energy, capped at 5"
			"recover":
				criteria[action] = "heal 2 HP, capped at 10; unavailable for 2 rounds"
	return criteria

func is_finished() -> bool:
	return finished

func state() -> Dictionary:
	return {
		"round": round + 1,
		"round_cap": ROUND_CAP,
		"p1": {"hp": p1_hp, "energy": p1_energy, "cooldowns": p1_cooldowns.duplicate(true)},
		"p2": {"hp": p2_hp, "energy": p2_energy, "cooldowns": p2_cooldowns.duplicate(true)},
		"last_summary": last_summary,
	}

func apply_actions(p1_action: String, p2_action: String) -> Dictionary:
	if finished:
		return {"error": "match already finished"}
	if not legal_actions(1).has(p1_action):
		return {"error": "illegal action for player 1: " + p1_action}
	if not legal_actions(2).has(p2_action):
		return {"error": "illegal action for player 2: " + p2_action}

	var p1_guard := p1_action == "guard"
	var p2_guard := p2_action == "guard"

	var p1_damage := 3 if p1_action == "strike" else 0
	var p2_damage := 3 if p2_action == "strike" else 0
	if p2_guard:
		p1_damage = maxi(0, p1_damage - 2)
	if p1_guard:
		p2_damage = maxi(0, p2_damage - 2)

	p1_hp = clampi(p1_hp - p2_damage, 0, MAX_HP)
	p2_hp = clampi(p2_hp - p1_damage, 0, MAX_HP)

	if p1_action == "charge":
		p1_energy = mini(MAX_ENERGY, p1_energy + 2)
	if p2_action == "charge":
		p2_energy = mini(MAX_ENERGY, p2_energy + 2)
	if p1_action == "strike":
		p1_energy -= 1
	if p2_action == "strike":
		p2_energy -= 1
	if p1_action == "recover":
		p1_hp = mini(MAX_HP, p1_hp + 2)
	if p2_action == "recover":
		p2_hp = mini(MAX_HP, p2_hp + 2)

	p1_cooldowns["recover"] = 2 if p1_action == "recover" else maxi(0, int(p1_cooldowns.get("recover", 0)) - 1)
	p2_cooldowns["recover"] = 2 if p2_action == "recover" else maxi(0, int(p2_cooldowns.get("recover", 0)) - 1)

	round += 1
	last_summary = "Round %d: P1 %s, P2 %s. P1 %d HP / %d energy; P2 %d HP / %d energy." % [
		round, p1_action, p2_action, p1_hp, p1_energy, p2_hp, p2_energy
	]

	if p1_hp <= 0 and p2_hp <= 0:
		finished = true
		winner = 0
	elif p2_hp <= 0:
		finished = true
		winner = 1
	elif p1_hp <= 0:
		finished = true
		winner = 2
	elif round >= ROUND_CAP:
		finished = true
		winner = 1 if p1_hp > p2_hp else (2 if p2_hp > p1_hp else 0)

	return {
		"round": round,
		"p1_action": p1_action,
		"p2_action": p2_action,
		"p1_hp": p1_hp,
		"p2_hp": p2_hp,
		"p1_energy": p1_energy,
		"p2_energy": p2_energy,
		"finished": finished,
		"winner": winner,
	}
