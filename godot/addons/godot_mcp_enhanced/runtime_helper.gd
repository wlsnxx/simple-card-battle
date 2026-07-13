extends Node

const _AUTOPLAY_BOT_PATH := "res://addons/godot_mcp_enhanced/autoplay_bot.gd"
const _STRESS_TEST_PATH := "res://addons/godot_mcp_enhanced/stress_test_runner.gd"

func _ready() -> void:
	if not OS.has_feature("debug") or not EngineDebugger.is_active():
		return
	EngineDebugger.register_message_capture("mcp", _on_mcp_msg)

func _on_mcp_msg(msg: String, data: Array) -> bool:
	if msg == "request_screenshot":
		_take_screenshot()
		return true
	elif msg == "simulate_action":
		var action = data[0]
		# Intercepta comandos especiais codificados como actions
		if action.begins_with("mcp_stress_test_start"):
			var parts: PackedStringArray = action.split(":")
			var n_games := int(parts[1]) if parts.size() > 1 else 10
			var t_scale := float(parts[2]) if parts.size() > 2 else 52.0
			_start_stress_test(n_games, t_scale)
			return true
		if action == "mcp_stress_test_stop":
			_stop_stress_test()
			return true
		if action.begins_with("mcp_autoplay_start"):
			var parts: PackedStringArray = action.split(":")
			var delay := float(parts[1]) if parts.size() > 1 else 0.35
			_start_autoplay(delay)
			return true
		if action == "mcp_autoplay_stop":
			_stop_autoplay()
			return true
		var pressed = data[1]
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		return true
	elif msg == "simulate_mouse":
		var pos_x = data[0]
		var pos_y = data[1]
		var pressed = data[2]
		var ev = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = Vector2(pos_x, pos_y)
		ev.global_position = Vector2(pos_x, pos_y)
		Input.parse_input_event(ev)
		return true
	elif msg == "autoplay_start":
		var delay := float(data[0]) if data.size() > 0 else 0.3
		_start_autoplay(delay)
		return true
	elif msg == "autoplay_stop":
		_stop_autoplay()
		return true
	return false

func _start_autoplay(reaction_delay: float) -> void:
	_stop_autoplay()
	var game := get_tree().root.find_child("Game", true, false)
	if game == null:
		push_error("[RuntimeMCPHelper] Game node not found — inicie uma partida primeiro")
		return
	var bot_script: Script = load(_AUTOPLAY_BOT_PATH)
	if bot_script == null:
		push_error("[RuntimeMCPHelper] autoplay_bot.gd não encontrado em " + _AUTOPLAY_BOT_PATH)
		return
	var bot: Node = Node.new()
	bot.set_script(bot_script)
	bot.name = "AutoplayBot"
	add_child(bot)
	bot.call("start", game, reaction_delay)
	print("[RuntimeMCPHelper] AutoplayBot iniciado (reaction_delay=%.2f)" % reaction_delay)

func _stop_autoplay() -> void:
	for child in get_children():
		if child.name == "AutoplayBot":
			child.call("stop")
			child.queue_free()
			print("[RuntimeMCPHelper] AutoplayBot parado")

func _start_stress_test(n_games: int, time_scale: float) -> void:
	_stop_stress_test()
	var stress_script: Script = load(_STRESS_TEST_PATH)
	if stress_script == null:
		push_error("[RuntimeMCPHelper] stress_test_runner.gd não encontrado")
		return
	var runner: Node = Node.new()
	runner.set_script(stress_script)
	runner.name = "StressTestRunner"
	add_child(runner)
	runner.call("start", n_games, time_scale)
	print("[RuntimeMCPHelper] StressTestRunner iniciado (%d games, %.0fx)" % [n_games, time_scale])

func _stop_stress_test() -> void:
	for child in get_children():
		if child.name == "StressTestRunner":
			child.call("stop")
			child.queue_free()
			print("[RuntimeMCPHelper] StressTestRunner parado")

func _take_screenshot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport = get_tree().root
	var img = viewport.get_texture().get_image()
	if img:
		var buffer = img.save_png_to_buffer()
		var b64 = Marshalls.raw_to_base64(buffer)
		EngineDebugger.send_message("mcp:screenshot_response", [b64])
