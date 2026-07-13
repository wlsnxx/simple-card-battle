# {NOME_DO_JOGO} — Project Memory

Shared context for AI agents. Keep it lean.

## Project Overview
{Descreva o jogo em 2-3 linhas: gênero, mecânica central, plataformas-alvo.}
- **Engine:** Godot 4.6.x
- **Binary:** versões gerenciadas pelo launcher **Godots**. Se não estiver no PATH, busque:
  - **Windows:** `Godot_*-stable_win64_console.exe` em `%APPDATA%/Godot/app_userdata/Godots/versions/`
  - **Linux:** `Godot_*-stable_linux.x86_64` em `~/.local/share/godot/app_userdata/Godots/versions/`
  - Ou: `source tools/scripts/find_godot.sh` (define `$GODOT_BIN`)
- **Run CMD:** `<binary> --path godot/`

## Scene Flow
`Home → Game` (through `Navigator.change_scene(path)`).
{Atualize conforme telas forem criadas; registre cada uma em SceneRoutes.DEBUG_SCREENS.}

## Singletons (Autoloads)
- **SceneRoutes**: Caminhos de cenas + mapa de telas do DebugCLI.
- **Navigator**: Scene transitions with fade (`skip_fade` para bots).
- **DebugCLI**: `--goto <tela> --screenshot` para inspeção visual por IA/CI.
{Adicione aqui os autoloads do jogo: GameState, SaveService, AudioService, Events...}

## Architecture Guidelines
1. **TSCN-First**: All UI layout nodes in `.tscn`. Scripts only for logic.
2. **Nesting Boxes**: CanvasLayer → MarginContainer → BoxContainers → Leaf Nodes.
3. **Static Typing**: Full static types required for all GDScript 2.0.
4. **Theme variations**: Apply `theme_type_variation` instead of manual color overrides.
5. **Web Stability (iOS)**: Single-threaded build (no COOP/COEP) with PWA meta tags is required to prevent process reloads.

## Directories
- `godot/autoload/`: Singletons.
- `godot/scripts/`: Logic files (gameplay/UI).
- `godot/scenes/`: `.tscn` files and components.
- `godot/tests/unit/`: GUT unit tests (invariants + formulas).
- `godot/tools/`: Ferramentas headless (ex: `render_svg.gd` — SVG→PNG p/ logo/splash).
- `godot/assets/`: Texturas, temas, fontes.

## Validation gate (MANDATORY)
1. **Headless Execution**: `binary --path godot --headless --quit`
2. **Unit tests (GUT)**: `binary --headless --path godot -s res://addons/gut/gut_cmdln.gd -gexit`
3. **Screenshots (on demand)**: `binary --path godot --resolution 720x1280 -- --goto <tela> --screenshot`
   (salva em `user://debug_ss.png`; `--screenshot-early` para toasts/animações efêmeras)
   Alternativa MCP: `mcp_godot-mcp-enhanced_get_running_scene_screenshot` (ver README).

CI (`.github/workflows/tests.yml`) runs GUT em todo push/PR.
Mudanças de UI: prints antes/depois em `docs/comparativos/` + link no PR.
