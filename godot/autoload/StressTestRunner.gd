## StressTestRunner.gd
##
## Roda N ciclos de jogo com o AutoplayBot em velocidade acelerada e imprime
## um resumo parseável pelo CI (linha "RESULTS_JSON: {...}").
##
## Definição genérica de "fim de jogo": a cena atual deixou de ser
## SceneRoutes.GAME — cobre game over que navega para EndGame/Home e o bot
## do template (que volta ao menu). Especialize _is_game_over() se o seu
## jogo sinaliza o fim de outra forma (ex: sinal do GameState).
##
## Uso: godot --headless --path godot -- --autoplay [games] [speed]

extends Node

## Timeout de parede por partida — pega jogo travado/bot perdido.
const GAME_TIMEOUT_MS: int = 120_000

var _target_games: int = 0
var _running: bool = false
var _in_game: bool = false
var _done: int = 0
var _timeouts: int = 0
var _game_t0: int = 0
var _durations: Array[float] = []


func start(games: int, time_scale: float) -> void:
	_target_games = games
	Engine.time_scale = time_scale
	Navigator.skip_fade = true
	_running = true
	print("[StressTest] %d partidas | %.0fx" % [games, time_scale])
	_next_game.call_deferred()


func _next_game() -> void:
	_in_game = false
	# Navigator descarta change_scene durante transição — espera liberar.
	while Navigator.is_busy():
		await get_tree().process_frame
	Navigator.change_scene(SceneRoutes.GAME)


func _process(_delta: float) -> void:
	if not _running:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var on_game: bool = scene.scene_file_path == SceneRoutes.GAME
	if on_game and not _in_game:
		_in_game = true
		_game_t0 = Time.get_ticks_msec()
		AutoplayBot.start(scene)
	elif _in_game and _is_game_over(scene, on_game):
		_finish_game(false)
	elif _in_game and Time.get_ticks_msec() - _game_t0 > GAME_TIMEOUT_MS:
		_finish_game(true)


## Fim de jogo genérico: saiu da cena de gameplay. Especialize se preciso.
func _is_game_over(_scene: Node, on_game: bool) -> bool:
	return not on_game


func _finish_game(timed_out: bool) -> void:
	AutoplayBot.stop()
	_in_game = false
	_done += 1
	var dur: float = float(Time.get_ticks_msec() - _game_t0) / 1000.0
	_durations.append(dur)
	if timed_out:
		_timeouts += 1
	print("[StressTest] game %d/%d %s em %.1fs" % [
		_done, _target_games, "TIMEOUT" if timed_out else "ok", dur,
	])
	if _done >= _target_games:
		_finish()
	else:
		_next_game.call_deferred()


func _finish() -> void:
	_running = false
	Engine.time_scale = 1.0
	var total: float = 0.0
	for d: float in _durations:
		total += d
	var avg: float = total / maxf(1.0, float(_durations.size()))
	var results: Dictionary = {
		"games": _done,
		"summary": {
			"avg_seconds": snappedf(avg, 0.01),
			"timeouts": _timeouts,
		},
	}
	print("RESULTS_JSON: " + JSON.stringify(results))
	get_tree().quit(1 if _timeouts > 0 else 0)
