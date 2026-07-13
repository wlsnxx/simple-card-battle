#!/usr/bin/env bash
## tools/scripts/find_godot.sh — descobre o binário do Godot (Linux/Windows).
##
## Ordem de busca:
##   1. $GODOT_BIN já definido pelo usuário
##   2. `godot` no PATH
##   3. Versões instaladas pelo launcher Godots (pega a stable mais recente):
##      - Windows: %APPDATA%/Godot/app_userdata/Godots/versions/Godot_*-stable_win64[_console].exe
##      - Linux:   ~/.local/share/godot/app_userdata/Godots/versions/Godot_*-stable_linux.x86_64
##
## Uso: source "$(dirname "$0")/find_godot.sh"   # define e exporta GODOT_BIN

_find_godot() {
  [[ -n "$GODOT_BIN" && -x "$GODOT_BIN" ]] && return 0

  GODOT_BIN=$(command -v godot 2>/dev/null)
  [[ -n "$GODOT_BIN" ]] && return 0

  local versions candidate
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      versions="$APPDATA/Godot/app_userdata/Godots/versions"
      # console.exe primeiro (stdout funciona no terminal), senão o .exe normal
      candidate=$(ls "$versions"/*/Godot_*-stable_win64_console.exe 2>/dev/null | sort -V | tail -1)
      [[ -z "$candidate" ]] && candidate=$(ls "$versions"/*/Godot_*-stable_win64.exe 2>/dev/null | sort -V | tail -1)
      ;;
    *)
      versions="$HOME/.local/share/godot/app_userdata/Godots/versions"
      candidate=$(ls "$versions"/*/Godot_*-stable_linux.x86_64 2>/dev/null | sort -V | tail -1)
      ;;
  esac
  [[ -x "$candidate" ]] && GODOT_BIN="$candidate"
}

_find_godot
export GODOT_BIN

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "❌ Godot não encontrado. Defina GODOT_BIN, instale no PATH ou use o launcher Godots." >&2
  return 1 2>/dev/null || exit 1
fi
