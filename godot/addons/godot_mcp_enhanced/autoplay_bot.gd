extends Node
## AutoplayBot — joga rounds do Fingerdot autonomamente via acesso direto ao Game.
##
## Melhorias sobre o plano original (autoplay_plan.md):
##   - Usa _current_correct_target diretamente (sem color matching, sem tolerância)
##   - Respeita _accept_input_at via _process (sem loop fixo com await)
##   - Verifica _context_active para não clicar durante overlays de ensino
##   - Bomb safety check embutido

var _game: Node = null
var _enabled: bool = false
var _reaction_delay: float = 0.3   # segundos após abertura da janela de input
var _last_correct_target: int = -2 # detecta troca de round
var _clicked_this_round: bool = false


func start(game_node: Node, reaction_delay: float = 0.3) -> void:
	_game = game_node
	_reaction_delay = reaction_delay
	_enabled = true
	_last_correct_target = -2
	_clicked_this_round = false


func stop() -> void:
	_enabled = false


func _process(_delta: float) -> void:
	if not _enabled or not is_instance_valid(_game):
		return

	var correct: int = _game.get("_current_correct_target")
	var played: float = _game.get("_played_time")
	var accept_at: float = _game.get("_accept_input_at")
	var context_active: bool = _game.get("_context_active")

	# Detecta início de novo round
	if correct != _last_correct_target:
		_last_correct_target = correct
		_clicked_this_round = false

	# Aguarda round válido, sem overlay ativo
	if _clicked_this_round or correct < 0 or context_active:
		return

	# Aguarda janela de input + delay de reação
	if played < accept_at + _reaction_delay:
		return

	# Bomb safety: não clica se o alvo correto virou bomb (não deveria acontecer)
	var bomb_slots: Array = _game.get("_bomb_slots")
	if bomb_slots.has(correct):
		return

	_clicked_this_round = true
	_game.call("_on_target_pressed", correct)
