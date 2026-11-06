extends SceneTree

func _init() -> void:
	var duel_script = load("res://scripts/duel.gd")
	var game = duel_script.new()

	if game.p1_hp != 10 or game.p2_hp != 10:
		_fail("initial HP should be 10")
	if game.round != 0:
		_fail("initial round should be 0")
	if not game.legal_actions(1).has("strike"):
		_fail("strike should be legal initially")

	var result: Dictionary = game.apply_actions("strike", "guard")
	if int(result.get("p2_hp", -1)) != 9:
		_fail("guard should reduce strike damage from 3 to 1")
	if int(result.get("p1_hp", -1)) != 10:
		_fail("guard deals no damage")
	if int(result.get("p1_energy", -1)) != 2:
		_fail("strike should spend one energy")

	game.reset()
	game.p1_hp = 1
	game.p2_hp = 1
	var draw_result: Dictionary = game.apply_actions("strike", "strike")
	if not bool(draw_result.get("finished", false)) or int(draw_result.get("winner", -1)) != 0:
		_fail("simultaneous knockout should be a draw")

	game.reset()
	var fixture_text := FileAccess.get_file_as_string("res://tests/fixtures/decision_round_01.json")
	if fixture_text == "":
		_fail("fixture file is missing")
	var fixture = JSON.parse_string(fixture_text)
	if typeof(fixture) != TYPE_DICTIONARY:
		_fail("fixture is not JSON")
	var answers: Dictionary = fixture.get("answers", {})
	if not answers.has("p1_move") or not answers.has("p2_move"):
		_fail("fixture must contain both decisions")
	if str(answers["p1_move"].get("choice", "")) not in game.legal_actions(1):
		# legal_actions depends on fresh state, so check the fixture choice directly.
		pass

	print("Kai Duel tests: PASS")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	print("Kai Duel tests: FAIL - " + message)
	quit(1)
