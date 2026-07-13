## SceneRoutes.gd
##
## Caminhos das cenas em um só lugar — nada de strings soltas pelo código.
## DEBUG_SCREENS alimenta o DebugCLI (--goto): registre aqui cada tela nova
## para ganhar navegação direta + screenshot de graça.

extends Node

const HOME: String = "res://Menu.tscn"
const GAME: String = "res://Main.tscn"
const COLLECTION: String = "res://Collection.tscn"

## tela (nome usado no --goto) → cena. Entradas podem apontar para a mesma
## cena com setup diferente — trate casos especiais no DebugCLI.
const DEBUG_SCREENS: Dictionary = {
	"home": HOME,
	"game": GAME,
	"collection": COLLECTION,
}
