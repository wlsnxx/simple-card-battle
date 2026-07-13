## DebugCLI.gd
##
## CLI de debug/inspeção visual iniciado via argumentos de linha de comando.
## É a base do fluxo "IA inspeciona a tela": abre qualquer tela registrada
## em SceneRoutes.DEBUG_SCREENS e captura screenshot reproduzível.
##
## Uso (args do usuário vêm DEPOIS do separador --):
##   godot --path godot --resolution 720x1280 -- --goto home --screenshot
##
##   --goto SCREEN     Navega direto para a tela (chaves de DEBUG_SCREENS).
##   --screenshot      Salva user://debug_ss.png e encerra o processo.
##   --screenshot-early  Variante que captura ~1s após a transição —
##                     para elementos efêmeros (toasts, animações de entrada).
##
## Para telas com estado sintético (save populado, dialogs abertos etc.),
## adicione um case no match de _goto_screen — ver o AutoplayCLI do
## Fingerdot/Dotway como referência de padrões (dialogs, scroll, dark/light).

extends Node

const SCREENSHOT_PATH: String = "user://debug_ss.png"


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var auto_idx: int = args.find("--autoplay")
	if auto_idx >= 0:
		var games: int = int(args[auto_idx + 1]) if args.size() > auto_idx + 1 else 20
		var speed: float = float(args[auto_idx + 2]) if args.size() > auto_idx + 2 else 4.0
		StressTestRunner.start.call_deferred(games, speed)
		return
	var goto_idx: int = args.find("--goto")
	if goto_idx < 0:
		return
	var screen: String = args[goto_idx + 1] if args.size() > goto_idx + 1 else ""
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	_goto_screen.call_deferred(screen, args)


## Navega para a tela pedida e dispara a captura, se solicitada.
func _goto_screen(screen: String, args: PackedStringArray) -> void:
	var path: String = str(SceneRoutes.DEBUG_SCREENS.get(screen, ""))
	if path.is_empty():
		push_error("[DebugCLI] --goto: tela desconhecida '%s'. Use: %s" % [
			screen, " | ".join(SceneRoutes.DEBUG_SCREENS.keys()),
		])
		get_tree().quit(1)
		return
	print("[DebugCLI] --goto %s" % screen)
	Navigator.change_scene(path)
	if args.has("--screenshot-early"):
		_take_screenshot(SCREENSHOT_PATH, 60)
	elif args.has("--screenshot"):
		_take_screenshot(SCREENSHOT_PATH, 200)


## Aguarda o Navigator concluir a transição (cena garantidamente na árvore),
## espera [param settle_frames] para animações de entrada e captura.
## 200 frames (~3.3s) cobre animações típicas; 60 (~1s) pega toasts efêmeros.
func _take_screenshot(path: String, settle_frames: int) -> void:
	while Navigator.is_busy():
		await get_tree().process_frame
	for _i: int in settle_frames:
		await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[DebugCLI] Screenshot salvo: " + ProjectSettings.globalize_path(path))
	get_tree().quit()
