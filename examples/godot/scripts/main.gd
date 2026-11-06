extends Control

const AUTO_DELAY := 1.2

var game := KaiDuel.new()
var kai := KaiClient.new()
var auto_play := false
var awaiting := false
var last_latency := 0.0

var status_label: Label
var p1_label: Label
var p2_label: Label
var probabilities: Label
var log_text: RichTextLabel
var next_button: Button
var auto_button: Button
var reset_button: Button
var timer: Timer

func _ready() -> void:
	add_child(kai)
	kai.round_ready.connect(_on_round_ready)
	kai.request_failed.connect(_on_request_failed)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var title := Label.new()
	title.text = "Kai Duel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	status_label = Label.new()
	vbox.add_child(status_label)

	var players := HBoxContainer.new()
	players.name = "Players"
	vbox.add_child(players)
	p1_label = Label.new()
	p1_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players.add_child(p1_label)
	p2_label = Label.new()
	p2_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players.add_child(p2_label)

	probabilities = Label.new()
	vbox.add_child(probabilities)

	log_text = RichTextLabel.new()
	log_text.custom_minimum_size = Vector2(0, 220)
	log_text.scroll_following = true
	vbox.add_child(log_text)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	vbox.add_child(buttons)
	next_button = Button.new()
	next_button.text = "Next Round"
	next_button.pressed.connect(_on_next_pressed)
	buttons.add_child(next_button)
	auto_button = Button.new()
	auto_button.text = "Auto: Off"
	auto_button.pressed.connect(_on_auto_pressed)
	buttons.add_child(auto_button)
	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset_button)

	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

	_refresh()
	_append("Kai Duel ready. Press Next Round to ask Kai for both moves.")

func _on_next_pressed() -> void:
	if awaiting:
		return
	if game.is_finished():
		game.reset()
		_refresh()
	_append("Asking Kai for round %d..." % [game.round + 1])
	awaiting = true
	next_button.disabled = true
	kai.request_round(game.state())

func _on_auto_pressed() -> void:
	auto_play = not auto_play
	auto_button.text = "Auto: On" if auto_play else "Auto: Off"
	if auto_play and not awaiting and not game.is_finished():
		_on_next_pressed()

func _on_reset_pressed() -> void:
	game.reset()
	auto_play = false
	auto_button.text = "Auto: Off"
	awaiting = false
	next_button.disabled = false
	timer.stop()
	_refresh()
	_append("Match reset.")

func _on_timer_timeout() -> void:
	if auto_play and not awaiting and not game.is_finished():
		_on_next_pressed()

func _on_round_ready(p1_action: String, p1_probabilities: Dictionary, p1_confidence: float, p2_action: String, p2_probabilities: Dictionary, p2_confidence: float, latency_ms: float) -> void:
	awaiting = false
	next_button.disabled = false
	last_latency = latency_ms

	if not game.legal_actions(1).has(p1_action):
		_append("Kai returned an illegal move for player 1: %s" % p1_action)
		auto_play = false
		auto_button.text = "Auto: Off"
		timer.stop()
		return
	if not game.legal_actions(2).has(p2_action):
		_append("Kai returned an illegal move for player 2: %s" % p2_action)
		auto_play = false
		auto_button.text = "Auto: Off"
		timer.stop()
		return

	var result: Dictionary = game.apply_actions(p1_action, p2_action)
	probabilities.text = "P1 %s (%.0f%%), P2 %s (%.0f%%), latency %.0f ms" % [
		p1_action, p1_confidence * 100.0, p2_action, p2_confidence * 100.0, latency_ms
	]
	_append(game.last_summary)
	if bool(result.get("finished", false)):
		var winner := int(result.get("winner", 0))
		if winner == 1:
			_append("Player 1 wins.")
		elif winner == 2:
			_append("Player 2 wins.")
		else:
			_append("Draw.")
		auto_play = false
		auto_button.text = "Auto: Off"
		timer.stop()
	elif auto_play:
		timer.start(AUTO_DELAY)
	_refresh()

func _on_request_failed(message: String) -> void:
	awaiting = false
	next_button.disabled = false
	auto_play = false
	auto_button.text = "Auto: Off"
	timer.stop()
	_append("Request failed: " + message)

func _refresh() -> void:
	p1_label.text = "Player 1: %d HP, %d energy" % [game.p1_hp, game.p1_energy]
	p2_label.text = "Player 2: %d HP, %d energy" % [game.p2_hp, game.p2_energy]
	if game.is_finished():
		status_label.text = "Finished"
	else:
		status_label.text = "Round %d / %d" % [game.round + 1, KaiDuel.ROUND_CAP]
	if game.is_finished():
		next_button.text = "Reset and Play"
	else:
		next_button.text = "Next Round"

func _append(text: String) -> void:
	log_text.append_text(text + "\n")
