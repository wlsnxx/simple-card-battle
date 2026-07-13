## GameState.gd
##
## Estado da partida corrente (esqueleto). Fonte de verdade do que está
## acontecendo AGORA; o que precisa sobreviver ao fechamento do app vai
## para o SaveService. Referência de arquitetura completa (modos, vidas,
## rewards, resultado de sessão): GameState.gd do Dotway.

extends Node

## Modo de jogo ativo — as telas leem para se configurar.
var game_mode: String = "default"
var score: int = 0


## Zera o estado no início de uma partida.
func start_run() -> void:
	score = 0


## Consolida o fim da partida: persista recordes/moedas via SaveService e
## deixe o resultado disponível para a tela de fim de jogo.
func finish_run() -> void:
	pass
