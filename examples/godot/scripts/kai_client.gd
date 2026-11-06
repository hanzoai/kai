class_name KaiClient
extends Node

signal round_ready(p1_action: String, p1_probabilities: Dictionary, p1_confidence: float, p2_action: String, p2_probabilities: Dictionary, p2_confidence: float, latency_ms: float)
signal request_failed(message: String)

var _http: HTTPRequest
var _busy := false
var _pending_round := 0

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func request_round(state: Dictionary) -> void:
	if _busy:
		request_failed.emit("Kai request already in flight")
		return
	var api_key := OS.get_environment("HANZO_API_KEY")
	var base_url := OS.get_environment("HANZO_BASE_URL")
	if base_url == "":
		base_url = "https://api.hanzo.ai"
	base_url = base_url.trim_suffix("/")
	var model := OS.get_environment("KAI_MODEL")
	if model == "":
		model = "kai"

	var criteria := {}
	for action in ["strike", "guard", "charge", "recover"]:
		criteria[action] = action_description(action)
	# Legal moves are validated locally after Kai answers; sending the full set
	# keeps the request stable even when one player has a cooldown.
	var questions := {
		"p1_move": {
			"type": "choice",
			"instructions": "Choose player one's action for this round.",
			"criteria": criteria,
		},
		"p2_move": {
			"type": "choice",
			"instructions": "Choose player two's action for this round.",
			"criteria": criteria,
		},
	}
	var payload := {
		"model": model,
		"state": state,
		"questions": questions,
	}
	var json_text := JSON.stringify(payload)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if api_key != "":
		headers.append("Authorization: Bearer " + api_key)

	_busy = true
	_pending_round += 1
	var err := _http.request(base_url + "/v1/decisions", headers, HTTPClient.METHOD_POST, json_text)
	if err != OK:
		_busy = false
		request_failed.emit("Could not start HTTP request: %d" % err)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("Network error: %d" % result)
		return
	if response_code != 200:
		request_failed.emit("Kai returned HTTP %d: %s" % [response_code, body.get_string_from_utf8()])
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Kai returned invalid JSON")
		return

	var answers: Dictionary = parsed.get("answers", {})
	var p1_answer: Dictionary = answers.get("p1_move", {})
	var p2_answer: Dictionary = answers.get("p2_move", {})
	var p1_action := str(p1_answer.get("choice", ""))
	var p2_action := str(p2_answer.get("choice", ""))
	var p1_probabilities: Dictionary = p1_answer.get("probabilities", {})
	var p2_probabilities: Dictionary = p2_answer.get("probabilities", {})
	var p1_confidence := float(p1_answer.get("confidence", 0.0))
	var p2_confidence := float(p2_answer.get("confidence", 0.0))
	var latency := float(parsed.get("latency_ms", 0.0))

	round_ready.emit(p1_action, p1_probabilities, p1_confidence, p2_action, p2_probabilities, p2_confidence, latency)

func action_description(action: String) -> String:
	match action:
		"strike":
			return "spend 1 energy; deal 3 damage, reduced by 2 against guard"
		"guard":
			return "reduce incoming strike damage by 2 this round"
		"charge":
			return "gain 2 energy, capped at 5"
		"recover":
			return "heal 2 HP, capped at 10; unavailable for 2 rounds"
		_:
			return action
