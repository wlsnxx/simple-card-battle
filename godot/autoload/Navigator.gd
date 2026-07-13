## Navigator.gd
##
## Gerencia a navegação entre cenas com efeitos de transição.
## Fornece uma camada de overlay para realizar o fade-out e fade-in suave,
## garantindo que as trocas de tela não sejam abruptas para o jogador.

extends CanvasLayer

## Desliga o fade globalmente (bots/stress tests: economiza ~0.8s por troca).
var skip_fade: bool = false

## Nó de ColorRect usado para o efeito visual de transição.
var _overlay: ColorRect
## Indica se uma transição já está em andamento para evitar chamadas duplicadas.
var _busy: bool = false


func _ready() -> void:
	# Camada alta para garantir que o fade fique acima de toda a interface.
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


## True enquanto uma transição está em andamento (a cena nova pode ainda
## não estar na árvore) — ferramentas de screenshot devem aguardar.
func is_busy() -> bool:
	return _busy


## Realiza a troca para uma nova cena com um efeito de fade.
## [param path]: Caminho res:// para o arquivo .tscn da cena.
## [param duration]: Tempo em segundos para cada etapa (out/in) do fade.
func change_scene(path: String, duration: float = 0.2) -> void:
	if _busy:
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if skip_fade:
		duration = 0.0

	# Fade Out: escurece a tela.
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	await tween.finished

	# Troca real da cena.
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_warning("Failed to change scene: %s" % path)

	# Aguarda um frame para garantir que a nova cena foi instanciada.
	await get_tree().process_frame

	# Fade In: clareia a tela.
	var tween_in: Tween = create_tween()
	tween_in.tween_property(_overlay, "color:a", 0.0, duration)
	await tween_in.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
