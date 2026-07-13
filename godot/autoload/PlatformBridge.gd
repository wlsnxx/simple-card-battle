## PlatformBridge.gd
##
## Ponte com recursos nativos da plataforma: share, vibração, telemetria.
## Share nativo Android/iOS e notificações locais entram via plugins da
## família godot-mobile-plugins — receita no README ("Plugins nativos").
## Com os plugins vendorados, espelhe o wiring do PlatformBridge do Dotway
## (nó Share quando Engine.has_singleton("SharePlugin"), rota "native").

extends Node

## Emitido quando uma vibração foi solicitada mas a plataforma não suporta
## (web). Listeners aplicam feedback visual substituto (shake, flash).
## intensity: 1=light, 2=medium, 3=heavy.
signal haptic_fallback(intensity: int)

var _is_web: bool = false


func _ready() -> void:
	_is_web = OS.has_feature("web")


## Retorna true se rodando em build web (sem haptic nativo).
func is_web() -> bool:
	return _is_web


## Abre a interface de compartilhamento com uma imagem salva em user://.
## [return] Como foi entregue: "web" (Web Share API) ou "clipboard"
## (texto copiado; no desktop também abre a pasta da imagem).
func share_image(path: String, title: String, body: String) -> String:
	print("[Bridge] share_image title=%s path=%s" % [title, path])
	if _is_web:
		_share_web(path, title, body)
		return "web"

	DisplayServer.clipboard_set(body)
	if OS.get_name() in ["Android", "iOS"]:
		return "clipboard"

	# Desktop: além do clipboard, abre a pasta com o PNG.
	if FileAccess.file_exists(path):
		var full_path: String = ProjectSettings.globalize_path(path)
		OS.shell_open("file://" + full_path.get_base_dir())
	else:
		push_warning("Share image path does not exist: %s" % path)
	return "clipboard"


## Web Share API via JavaScriptBridge: PNG (Level 2) → texto → clipboard.
## Erros/cancelamento do usuário são silenciosos (padrão de share sheet).
func _share_web(path: String, title: String, body: String) -> void:
	if not OS.has_feature("web"):
		return
	var b64: String = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		b64 = Marshalls.raw_to_base64(file.get_buffer(file.get_length()))
	var js: String = """
	(async () => {
		try {
			const title = %s, text = %s, b64 = '%s';
			let files;
			if (b64) {
				const bin = atob(b64);
				const arr = new Uint8Array(bin.length);
				for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
				files = [new File([arr], 'share.png', {type: 'image/png'})];
			}
			if (files && navigator.canShare && navigator.canShare({files})) {
				await navigator.share({title, text, files});
			} else if (navigator.share) {
				await navigator.share({title, text});
			} else if (navigator.clipboard) {
				await navigator.clipboard.writeText(text);
			}
		} catch (e) { /* usuário cancelou o share sheet */ }
	})();
	""" % [JSON.stringify(title), JSON.stringify(body), b64]
	JavaScriptBridge.eval(js)


func vibrate_light() -> void:
	_vibrate(10, 1)


func vibrate_medium() -> void:
	_vibrate(25, 2)


func vibrate_heavy() -> void:
	_vibrate(80, 3)


func _vibrate(duration_ms: int, intensity: int) -> void:
	if not bool(SaveService.get_config_value("vibration", true)):
		return
	if _is_web:
		haptic_fallback.emit(intensity)
	else:
		Input.vibrate_handheld(duration_ms)


## Telemetria (stub — plugue seu provedor de analytics aqui).
func send_screen(screen_name: String) -> void:
	print("[Bridge] screen=%s" % screen_name)


func send_event(category: String, action: String, label: String, value: int) -> void:
	print("[Bridge] event category=%s action=%s label=%s value=%d" % [category, action, label, value])
