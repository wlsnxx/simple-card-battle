@tool
extends EditorDebuggerPlugin

signal screenshot_received(base64_data: String)

func _has_capture(prefix: String) -> bool:
	return prefix == "mcp"

func _capture(message: String, data: Array, session_id: int) -> bool:
	if message == "mcp:request_screenshot":
		return false
	if message == "mcp:screenshot_response":
		var base64 = data[0] if data.size() > 0 else ""
		emit_signal("screenshot_received", base64)
		return true
	return false

func request_screenshot() -> void:
	var sessions = get_sessions()
	if sessions.size() > 0:
		var session = sessions[0]
		if session.is_active():
			session.send_message("mcp:request_screenshot", [])

func simulate_action(action: String, pressed: bool) -> void:
	var sessions = get_sessions()
	if sessions.size() > 0 and sessions[0].is_active():
		sessions[0].send_message("mcp:simulate_action", [action, pressed])

func simulate_mouse(pos_x: float, pos_y: float, pressed: bool) -> void:
	var sessions = get_sessions()
	if sessions.size() > 0 and sessions[0].is_active():
		sessions[0].send_message("mcp:simulate_mouse", [pos_x, pos_y, pressed])

func start_autoplay(reaction_delay: float = 0.3) -> void:
	var sessions := get_sessions()
	if sessions.size() > 0 and sessions[0].is_active():
		sessions[0].send_message("mcp:autoplay_start", [reaction_delay])

func stop_autoplay() -> void:
	var sessions := get_sessions()
	if sessions.size() > 0 and sessions[0].is_active():
		sessions[0].send_message("mcp:autoplay_stop", [])
