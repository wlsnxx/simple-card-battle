#!/usr/bin/env bash
## tools/scripts/debug.sh — Abre o jogo direto em qualquer tela para inspeção visual.
##
## Uso:
##   ./tools/scripts/debug.sh SCREEN [--screenshot] [--screenshot-early]
##
## Telas: as chaves de SceneRoutes.DEBUG_SCREENS (home, game, ...).
##
## Flags:
##   --screenshot        Captura user://debug_ss.png (~3s de settle) e fecha
##   --screenshot-early  Captura ~1s após a transição (toasts efêmeros)
##
## Exemplos:
##   ./tools/scripts/debug.sh home --screenshot
##   ./tools/scripts/debug.sh game

if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
  sed -n '2,15p' "$0" | sed 's/^## \?//'
  exit 0
fi

# Descobre o binário do Godot (Linux/Windows, launcher Godots)
source "$(dirname "$0")/find_godot.sh"

# Auto-inicia Xvfb se não houver display disponível (SSH sem X11, CI)
_XVFB_PID=""
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* ]]; then
  if command -v Xvfb &>/dev/null; then
    DISPLAY=:99
    export DISPLAY
    Xvfb :99 -screen 0 1080x1920x24 -nolisten tcp &>/dev/null &
    _XVFB_PID=$!
    sleep 1
    echo "   Display: Xvfb :99 (virtual)"
  else
    echo "⚠️  Sem display e Xvfb não encontrado."
    exit 1
  fi
fi

PROJECT_DIR="$(cd "$(dirname "$0")/../../godot" && pwd)"
SCREEN="$1"
shift

echo "🔍 Debug: $SCREEN"
echo "   Godot: $GODOT_BIN"

"$GODOT_BIN" --path "$PROJECT_DIR" --resolution 720x1280 -- --goto "$SCREEN" "$@"

[[ -n "$_XVFB_PID" ]] && kill "$_XVFB_PID" 2>/dev/null
