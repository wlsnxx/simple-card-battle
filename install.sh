#!/usr/bin/env bash
## install.sh — instala o ferramental do godot-minimal em um projeto existente.
##
## Uso (clonado DENTRO do projeto alvo):
##   git clone github-wlsnxx:wlsnxx/godot-minimal.git
##   ./godot-minimal/install.sh [--dry-run] [--force] [ALVO]
##
##   ALVO       raiz do projeto (padrão: diretório pai deste repo)
##   --dry-run  só mostra o que seria copiado
##   --force    sobrescreve arquivos existentes (padrão: NUNCA sobrescreve)
##
## O que instala (pulando o que já existir no alvo):
##   godot/addons/gut, godot/addons/godot_mcp_enhanced
##   godot/autoload/{DebugCLI,Navigator,SceneRoutes,AutoplayBot,StressTestRunner}.gd
##   godot/tools/render_svg.gd, godot/.gutconfig.json
##   tools/scripts/*.sh, .github/workflows/*.yml
##   docs/comparativos/README.md, AI_PREFERENCES.md
##   CLAUDE.md e memory.md (só se não existirem — são por projeto)
##
## Depois de instalar (passos manuais, impressos no fim):
##   1. Registrar autoloads no project.godot ([autoload]):
##      SceneRoutes → Navigator → DebugCLI (nessa ordem)
##   2. Habilitar plugins gut e godot_mcp_enhanced ([editor_plugins])
##   3. Criar SceneRoutes.DEBUG_SCREENS com as telas do jogo
##   4. .gitignore: adicionar "godot-minimal/" (este clone) e a exceção
##      "!godot/addons/*/bin/" se houver "bin/" genérico

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DRY=0
FORCE=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^## \?//'; exit 0 ;;
    *)         TARGET="$arg" ;;
  esac
done

[[ -z "$TARGET" ]] && TARGET="$(cd "$HERE/.." && pwd)"

if [[ ! -f "$TARGET/godot/project.godot" ]]; then
  echo "❌ '$TARGET' não parece um projeto (esperava godot/project.godot)."
  echo "   Projeto novo? Copie o template inteiro em vez de instalar:"
  echo "   cp -r '$HERE' NovoJogo && cd NovoJogo && rm -rf .git && git init"
  exit 1
fi

COPIED=0
SKIPPED=0

## Copia origem→destino respeitando --dry-run/--force. Diretórios inteiros
## são tratados como unidade (existe? pula — não faz merge parcial).
_install() {
  local src="$HERE/$1" dst="$TARGET/$2"
  if [[ ! -e "$src" ]]; then
    echo "   ⚠️  fonte ausente: $1"
    return
  fi
  if [[ -e "$dst" && "$FORCE" != "1" ]]; then
    echo "   ⏭️  já existe: $2"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  echo "   ✅ $2"
  COPIED=$((COPIED + 1))
  [[ "$DRY" == "1" ]] && return
  mkdir -p "$(dirname "$dst")"
  cp -r "$src" "$dst"
}

echo "🔧 godot-minimal → $TARGET $([[ $DRY == 1 ]] && echo '(dry-run)')"

_install godot/addons/gut                    godot/addons/gut
_install godot/addons/godot_mcp_enhanced     godot/addons/godot_mcp_enhanced
_install godot/autoload/DebugCLI.gd          godot/autoload/DebugCLI.gd
_install godot/autoload/Navigator.gd         godot/autoload/Navigator.gd
_install godot/autoload/SceneRoutes.gd       godot/autoload/SceneRoutes.gd
_install godot/autoload/AutoplayBot.gd       godot/autoload/AutoplayBot.gd
_install godot/autoload/StressTestRunner.gd  godot/autoload/StressTestRunner.gd
_install godot/autoload/SaveService.gd       godot/autoload/SaveService.gd
_install godot/autoload/UiUtils.gd           godot/autoload/UiUtils.gd
_install godot/autoload/Events.gd            godot/autoload/Events.gd
_install godot/autoload/GameState.gd         godot/autoload/GameState.gd
_install godot/autoload/PlatformBridge.gd    godot/autoload/PlatformBridge.gd
_install godot/assets/themes/base_theme.tres godot/assets/themes/base_theme.tres
_install godot/tools/render_svg.gd           godot/tools/render_svg.gd
_install godot/.gutconfig.json               godot/.gutconfig.json
_install tools/scripts/find_godot.sh         tools/scripts/find_godot.sh
_install tools/scripts/debug.sh              tools/scripts/debug.sh
_install tools/scripts/autoplay.sh           tools/scripts/autoplay.sh
_install tools/scripts/generate_android_keystore.sh tools/scripts/generate_android_keystore.sh
_install tools/scripts/generate_cert.sh      tools/scripts/generate_cert.sh
_install tools/serve_web.py                  tools/serve_web.py
_install godot/tests/unit/test_save_service.gd godot/tests/unit/test_save_service.gd
_install godot/tests/unit/test_ui_utils.gd   godot/tests/unit/test_ui_utils.gd
_install .github/workflows/tests.yml         .github/workflows/tests.yml
_install .github/workflows/build-game.yml    .github/workflows/build-game.yml
_install docs/comparativos/README.md         docs/comparativos/README.md
_install AI_PREFERENCES.md                   AI_PREFERENCES.md
_install CLAUDE.md                           CLAUDE.md
_install memory.md                           memory.md

echo ""
echo "📦 $COPIED instalados, $SKIPPED pulados (já existiam$([[ $FORCE == 1 ]] || echo '; use --force para sobrescrever'))."
echo ""
echo "Passos manuais (se ainda não feitos no alvo):"
echo "  1. project.godot [autoload]: SceneRoutes, Navigator, DebugCLI"
echo "  2. project.godot [editor_plugins]: gut e godot_mcp_enhanced"
echo "  3. SceneRoutes.DEBUG_SCREENS: registre as telas do jogo"
echo "  4. .gitignore: 'godot-minimal/' + exceção '!godot/addons/*/bin/'"
echo "  5. Valide: \$GODOT --path godot --headless --quit && GUT"
