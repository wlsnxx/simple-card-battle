#!/usr/bin/env bash
## tools/scripts/autoplay.sh — roda o stress test com AutoplayBot (janela visível).
##
## Uso:
##   ./tools/scripts/autoplay.sh [games] [speed]
##
##   games   número de ciclos de jogo   padrão: 20
##   speed   multiplicador de tempo     padrão: 4
##
## O CI roda o equivalente headless (ver tests.yml). O bot padrão do template
## navega pelos botões da cena; sobrescreva AutoplayBot._act() no seu jogo.

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  sed -n '2,11p' "$0" | sed 's/^## \?//'
  exit 0
fi

source "$(dirname "$0")/find_godot.sh"
PROJECT_DIR="$(cd "$(dirname "$0")/../../godot" && pwd)"

GAMES="${1:-20}"
SPEED="${2:-4}"

echo "🎮 Autoplay: $GAMES ciclos | ${SPEED}x"
echo "   Godot: $GODOT_BIN"

"$GODOT_BIN" --path "$PROJECT_DIR" -- --autoplay "$GAMES" "$SPEED"
