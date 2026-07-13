extends Node
## StressTestRunner — orquestra N partidas do Fingerdot usando o AutoplayBot.
##
## Usa Engine.time_scale elevado para acelerar. A partir de time_scale ~52,
## rounds com timer mínimo (0.85s) chegam ao timeout antes do bot reagir,
## criando game overs orgânicos sem simulação de erro.
##
## Ativação via simulate_action: "mcp_stress_test_start:<games>:<time_scale>"
## Resultado escrito em: /tmp/fingerdot_stress_results.json

const BOT_SCRIPT_PATH := "res://addons/godot_mcp_enhanced/autoplay_bot.gd"
const RESULTS_PATH := "/tmp/fingerdot_stress_results.json"

var _target_games: int = 100
var _time_scale: float = 52.0
var _games_done: int = 0
var _bot: Node = null
var _game_was_valid: bool = false

# Tracking por partida
var _game_rounds: int = 0
var _game_fast_hits: int = 0
var _game_max_combo: int = 0
var _prev_fast_combo: int = 0
var _prev_count: int = 0

# Acumulados
var _scores: Array = []
var _levels: Array = []
var _rounds_list: Array = []
var _fast_hits_list: Array = []
var _max_combo_list: Array = []


func start(target_games: int, time_scale: float) -> void:
	_target_games = target_games
	_time_scale = time_scale
	Engine.time_scale = time_scale
	print("[StressTest] Iniciando %d partidas em %.0fx velocidade" % [target_games, time_scale])
	_spawn_bot()


func stop() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(_bot):
		_bot.call("stop")
		_bot.queue_free()
	queue_free()


func _process(_delta: float) -> void:
	if _games_done >= _target_games:
		return
	if not is_instance_valid(_bot):
		return

	var game = _bot.get("_game")
	var game_valid: bool = game != null and is_instance_valid(game)

	if game_valid:
		_update_ingame_tracking(game)

	if _game_was_valid and not game_valid:
		_handle_game_over()

	_game_was_valid = game_valid


func _update_ingame_tracking(game: Node) -> void:
	var gs := get_tree().root.get_node_or_null("GameState")
	if gs == null:
		return

	# Fast hits acumulados
	var fc: int = gs.get("fast_combo")
	if fc > _prev_fast_combo:
		_game_fast_hits += fc - _prev_fast_combo
	_prev_fast_combo = fc
	_game_max_combo = maxi(_game_max_combo, fc)

	# Rounds jogados
	var cnt: int = game.get("_count_generated") if game.get("_count_generated") != null else 0
	if cnt > _prev_count:
		_game_rounds += cnt - _prev_count
	_prev_count = cnt


func _handle_game_over() -> void:
	var gs := get_tree().root.get_node_or_null("GameState")
	var score := 0
	var level := 0
	if gs != null:
		score = gs.get("score") if gs.get("score") != null else 0
		level = gs.get("level") if gs.get("level") != null else 0

	_scores.append(score)
	_levels.append(level)
	_rounds_list.append(_game_rounds)
	_fast_hits_list.append(_game_fast_hits)
	_max_combo_list.append(_game_max_combo)

	_games_done += 1

	var log_interval := maxi(1, floori(float(_target_games) / 10.0))
	if _games_done % log_interval == 0 or _games_done <= 3:
		print("[StressTest] %d/%d | score=%d level=%d rounds=%d fast=%d maxcombo=%d" % [
			_games_done, _target_games, score, level, _game_rounds, _game_fast_hits, _game_max_combo
		])

	if _games_done >= _target_games:
		_finish()
	else:
		_restart_game()


func _restart_game() -> void:
	if is_instance_valid(_bot):
		_bot.call("stop")
		_bot.queue_free()
		_bot = null

	_game_rounds = 0
	_game_fast_hits = 0
	_game_max_combo = 0
	_prev_fast_combo = 0
	_prev_count = 0
	_game_was_valid = false

	# Aguarda Navigator terminar transição para EndGame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var nav := get_tree().root.get_node_or_null("Navigator")
	if nav and nav.has_method("change_scene"):
		nav.call("change_scene", "res://scenes/screens/Game.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/screens/Game.tscn")

	_wait_and_spawn_bot()


func _wait_and_spawn_bot() -> void:
	var game: Node = null
	var attempts := 0
	while game == null and attempts < 300:
		await get_tree().process_frame
		game = get_tree().root.find_child("Game", true, false)
		attempts += 1

	if game == null:
		push_error("[StressTest] Game node não encontrado após 300 frames")
		return

	# Frame extra para inicialização completa
	await get_tree().process_frame
	_spawn_bot()


func _spawn_bot() -> void:
	var game := get_tree().root.find_child("Game", true, false)
	if game == null:
		push_error("[StressTest] Game node não encontrado em _spawn_bot")
		return

	var bot_script: Script = load(BOT_SCRIPT_PATH)
	_bot = Node.new()
	_bot.set_script(bot_script)
	add_child(_bot)
	_bot.call("start", game, 0.0)  # reaction_delay = 0 para máxima velocidade
	_game_was_valid = true
	_prev_count = game.get("_count_generated") if game.get("_count_generated") != null else 0
	_prev_fast_combo = 0


func _finish() -> void:
	Engine.time_scale = 1.0

	var stats := {
		"games": _games_done,
		"time_scale": _time_scale,
		"scores": _scores,
		"levels": _levels,
		"rounds": _rounds_list,
		"fast_hits": _fast_hits_list,
		"max_combos": _max_combo_list,
	}

	var json_str := JSON.stringify(stats)

	var file := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

	print("[StressTest] COMPLETE: %d partidas" % _games_done)
	print("[StressTest] RESULTS_JSON: " + json_str)
	queue_free()
