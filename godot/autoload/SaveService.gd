## SaveService.gd
##
## Persistência em user://save.json. Núcleo genérico: carga com fallback
## para dados corrompidos, config chave-valor e reset. Adicione as seções
## do seu jogo em _default_data() (highscores, conquistas, moedas...) —
## o SaveService do Dotway é a referência completa.

extends Node

const SAVE_PATH: String = "user://save.json"
## Suba ao mudar o formato e trate a migração em _migrate().
const SAVE_VERSION: int = 1

## Dados brutos do save. Sistemas leem/escrevem e chamam save_all().
var data: Dictionary = {}


func _ready() -> void:
	load_all()


## Estado inicial de um perfil novo. Estenda com as seções do seu jogo.
func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"config": {
			"first_run": true,
			"vibration": true,
			"bgm": true,
			"sfx": true,
		},
	}

func get_coins() -> int:
	return int(data.get("coins", 0))

func add_coins(amount: int) -> void:
	var current = get_coins()
	data["coins"] = current + amount
	save_all()


func load_all() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _default_data()
		save_all()
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		data = _default_data()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save corrompido — recomeçando do zero")
		data = _default_data()
		save_all()
		return
	data = parsed
	_migrate()


func save_all() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file")
		return
	file.store_string(JSON.stringify(data, "  "))


## Lê uma configuração com fallback.
func get_config_value(key: String, default_value: Variant = null) -> Variant:
	var config: Dictionary = data.get("config", {})
	return config.get(key, default_value)


## Grava uma configuração e persiste imediatamente.
func set_config_value(key: String, value: Variant) -> void:
	if not data.has("config"):
		data["config"] = {}
	data["config"][key] = value
	save_all()


## Apaga tudo e volta ao estado inicial.
func reset_all() -> void:
	data = _default_data()
	save_all()


## Migra saves de versões antigas para o formato atual.
func _migrate() -> void:
	var version: int = int(data.get("version", 0))
	if version >= SAVE_VERSION:
		return
	# match version: ... (adicione os passos conforme SAVE_VERSION crescer)
	data["version"] = SAVE_VERSION
	save_all()
