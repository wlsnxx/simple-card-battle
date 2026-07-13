## AutoplayBot.gd
##
## Base genérica de bot de autoplay. O comportamento padrão "joga"
## pressionando o primeiro botão focável da cena — suficiente para o stress
## de navegação/carga de cena do template (Home ⇄ Game em loop).
##
## Jogos reais sobrescrevem _act() com a lógica do gameplay: ler o estado da
## cena, decidir a ação e usar press_button()/tap(). Referência completa
## (perfis casual/skilled, reaction adaptativa, miss rate intencional,
## consumo proativo de power-ups): AutoplayBot.gd do Dotway/fingerdot.

extends Node

var _enabled: bool = false
var _scene_root: Node = null
var _interval: float = 0.3
var _cooldown: float = 0.0


## Liga o bot na cena atual. [param action_interval] é o espaçamento entre
## ações em segundos de JOGO (escala junto com Engine.time_scale).
func start(scene_root: Node, action_interval: float = 0.3) -> void:
	_scene_root = scene_root
	_interval = action_interval
	_cooldown = _interval
	_enabled = true


func stop() -> void:
	_enabled = false
	_scene_root = null


func _process(delta: float) -> void:
	if not _enabled or not is_instance_valid(_scene_root):
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = _interval
	_act(_scene_root)


## Uma "jogada" do bot. Sobrescreva com a lógica do seu jogo.
func _act(root: Node) -> void:
	var btn: BaseButton = _find_first_button(root)
	if btn != null:
		press_button(btn)


## Aciona um botão como se o jogador tivesse tocado nele.
func press_button(btn: BaseButton) -> void:
	if btn.disabled or not btn.is_visible_in_tree():
		return
	btn.pressed.emit()


## Sintetiza um toque real (down+up) numa posição — para gameplay sem botões.
func tap(pos: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = pos
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventScreenTouch.new()
	up.position = pos
	up.pressed = false
	Input.parse_input_event(up)


func _find_first_button(node: Node) -> BaseButton:
	if node is BaseButton and (node as BaseButton).is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found: BaseButton = _find_first_button(child)
		if found != null:
			return found
	return null
