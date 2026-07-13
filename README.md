# godot-minimal — template de jogo Godot com ferramental de IA

Template extraído do **Dotway/fingerdot**: um projeto Godot 4.6 mínimo (Home → Game)
que já nasce com todo o ferramental de desenvolvimento assistido por IA — inspeção
visual por screenshot, testes GUT em CI, builds de 5 plataformas com release
automática, e os arquivos de contexto que fazem agentes (Claude Code etc.)
trabalharem bem no repo.

## O que vem pronto

| Peça | Onde | O que faz |
|---|---|---|
| **DebugCLI** | `godot/autoload/DebugCLI.gd` | `--goto <tela> --screenshot` — abre qualquer tela registrada e salva PNG reproduzível (base do fluxo "IA vê a tela") |
| **Navigator** | `godot/autoload/Navigator.gd` | Transições com fade; `skip_fade` para bots/stress |
| **SceneRoutes** | `godot/autoload/SceneRoutes.gd` | Rotas de cena + mapa `DEBUG_SCREENS` (registre cada tela nova) |
| **GUT + smoke test** | `godot/addons/gut`, `godot/tests/unit/` | Testes unitários; smoke valida que as rotas apontam para cenas reais |
| **AutoplayBot** | `godot/autoload/AutoplayBot.gd` | Bot base: default navega pelos botões (stress de cena/leaks); sobrescreva `_act()` com o gameplay — helpers `press_button()`/`tap()` |
| **StressTestRunner** | `godot/autoload/StressTestRunner.gd` | `--autoplay N SPEED`: N ciclos acelerados com timeout por partida e `RESULTS_JSON` parseável pelo CI |
| **CI de testes** | `.github/workflows/tests.yml` | GUT + stress test de 20 ciclos em todo push/PR |
| **CI de builds** | `.github/workflows/build-game.yml` | Android APK+AAB (gradle), iOS, Windows, Linux AppImage, Web — release automática **só na main** (dispatch em branch = build de validação) |
| **MCP (editor)** | `godot/addons/godot_mcp_enhanced` | Addon do [godot-mcp-enhanced](https://github.com/Rufaty/godot-mcp-enhanced) — screenshots/controle do editor via MCP |
| **Serviços base** | `godot/autoload/` | `SaveService` (save.json com migração e fallback de corrupção), `UiUtils` (toast, `format_score`, variações claro/escuro), `PlatformBridge` (share web/clipboard, haptics, telemetria stub), `Events` (signal bus), `GameState` (esqueleto) |
| **Tema base** | `godot/assets/themes/base_theme.tres` | Variações `LabelTitle/Body/HUD/Small` (+`Dark`) e `ButtonPrimary` — a regra "theme_type_variation, nunca override manual" executável desde o dia 1 |
| **Web local** | `tools/serve_web.py` | Servidor com gzip + HTTPS (certificado via `generate_cert.sh`) — teste no celular da rede; iOS Safari exige HTTPS |
| **Ferramentas headless** | `godot/tools/render_svg.gd` | SVG→PNG para logo/splash/ícones (boot splash NÃO aceita SVG direto) |
| **Scripts dev** | `tools/scripts/` | `find_godot.sh` (acha o binário via launcher Godots), `debug.sh`, `generate_android_keystore.sh` |
| **Contexto p/ IA** | `CLAUDE.md`, `memory.md`, `AI_PREFERENCES.md` | Regras (TSCN-first, tipagem estática), gate de validação, ponto de retomada entre sessões |
| **Comparativos** | `docs/comparativos/` | Padrão antes/depois para toda mudança de UI |

## Dois modos de uso

**Projeto novo** → copie o template inteiro (checklist abaixo).

**Projeto existente (modo toolkit)** → clone este repo dentro do projeto e instale só o que falta:

```bash
git clone github-wlsnxx:wlsnxx/godot-minimal.git
./godot-minimal/install.sh --dry-run   # mostra o que seria copiado
./godot-minimal/install.sh             # instala (NUNCA sobrescreve; --force se quiser)
echo "godot-minimal/" >> .gitignore    # o clone não é versionado no jogo
```

O installer pula tudo que já existe no alvo e imprime os passos manuais
(autoloads, plugins, DEBUG_SCREENS). Para atualizar o ferramental depois:
`git -C godot-minimal pull && ./godot-minimal/install.sh --dry-run` e escolha
o que sobrescrever com `--force` (compare antes, seus arquivos podem ter
divergido de propósito). Melhorias feitas em qualquer jogo → PR de volta aqui.

## Novo jogo — checklist

1. Copie a pasta (ou `git clone` + remova `.git`) e `git init`.
2. Troque `{NOME_DO_JOGO}` em `CLAUDE.md`/`memory.md`; em `godot/project.godot`:
   `config/name` e `config/custom_user_dir_name`.
3. `godot/export_presets.cfg`: `package/unique_name` (Android) e
   `application/bundle_identifier` (iOS) — `com.example.gametemplate` → o seu.
   ⚠️ O pacote Android vira **eterno** na 1ª publicação na Play Store.
4. Abra no editor uma vez (gera `.godot/` e uids) e rode o gate de validação:
   ```bash
   source tools/scripts/find_godot.sh
   "$GODOT_BIN" --path godot --headless --quit                                  # compile check
   "$GODOT_BIN" --headless --path godot -s res://addons/gut/gut_cmdln.gd -gexit # GUT
   "$GODOT_BIN" --path godot --resolution 720x1280 -- --goto home --screenshot  # smoke visual
   ```
5. Cada tela nova: cena em `scenes/screens/` + rota em `SceneRoutes` + entrada em
   `DEBUG_SCREENS`. Ganha `--goto`/screenshot de graça.
5b. Quando o gameplay existir: sobrescreva `AutoplayBot._act()` para o bot
   jogar de verdade (o default só navega por botões) e, se o fim de jogo não
   trocar de cena, especialize `StressTestRunner._is_game_over()`. Rode
   `./tools/scripts/autoplay.sh 20 8` ou `-- --autoplay 20 8` headless.
6. GitHub: o `tests.yml` roda sozinho. Para release assinada Android, rode
   `tools/scripts/generate_android_keystore.sh` e registre os 3 secrets.

## MCP (screenshots pelo editor)

O addon já está em `godot/addons/godot_mcp_enhanced` (habilitado no projeto) —
ele sobe um servidor HTTP na porta 3571 **quando o editor está aberto**.
O lado MCP (que o Claude Code consome) é **uma instalação por máquina,
compartilhada entre todos os jogos**: `C:\Users\Dvan\Projects\godot-mcp-enhanced`
(fonte + venv Windows já prontos). Cada projeto só registra:

```bash
# na RAIZ do projeto (o escopo do claude mcp add é o cwd!):
MCP="C:\\Users\\Dvan\\Projects\\godot-mcp-enhanced\\python"
claude mcp add godot-mcp-enhanced \
  --env GODOT_HOST=127.0.0.1 --env GDAI_MCP_SERVER_PORT=3571 \
  -- "$MCP\\.venv\\Scripts\\python.exe" "$MCP\\mcp_server.py"
claude mcp list   # deve mostrar ✔ Connected
```

Máquina nova (recriar a instalação compartilhada):

```bash
git clone https://github.com/Rufaty/godot-mcp-enhanced ~/Projects/godot-mcp-enhanced
cd ~/Projects/godot-mcp-enhanced/python
python -m venv .venv
./.venv/Scripts/python.exe -m pip install mcp httpx pydantic   # Linux: .venv/bin/python
```

As tools aparecem na PRÓXIMA sessão do Claude Code. Com o **editor aberto**,
o agente ganha `get_running_scene_screenshot`, inspeção de cena/nós etc.
Sem editor, o caminho 100% CLI (`--goto ... --screenshot`) cobre screenshots —
é o que o CI usa e o que funciona headless.

## Plugins nativos Android/iOS (receita do Dotway)

Família [godot-mobile-plugins](https://github.com/godot-mobile-plugins) (share,
notificações...; MIT; use a versão que casa com seu Godot — v5.2 = 4.6):

1. Baixe o zip `*-Multi-*`, extraia `addons/<Plugin>` e `ios/plugins` para `godot/`.
2. `git add -f godot/addons/<Plugin>/bin/` (o `.gitignore` tem exceção, confira!).
3. Habilite em `project.godot` (`editor_plugins`) e no preset iOS (`plugins/<Plugin>=true`).
4. No `build-game.yml`, adicione o plugin na `PackedStringArray()` dos jobs
   Android e iOS (procure "plugins nativos") — o export plugin injeta AAR/manifest.
5. Valide com `workflow_dispatch` na branch e inspecione o APK (classes no dex).

## Armadilhas já pagas (não repita)

- **`bin/` genérico no .gitignore engole AARs de addons** → exceção já incluída.
- **Boot splash não aceita SVG** ([godot#96177](https://github.com/godotengine/godot/issues/96177)) — gere PNG com `render_svg.gd`; splash cropado justo estica em tela alta: gere com respiro (canvas retrato, logo ~58% da largura).
- **Gradle build em CI**: instale o template (`android_source.zip` dos export templates) **e crie `godot/android/build/.gdignore`** — sem ele o 2º export (AAB após APK) quebra no mergeResources.
- **Args de CLI do jogo vêm depois de `--`**: `godot --path godot -- --goto home`.
- **Release job só na main** — dispatch em branch valida os 5 builds sem publicar.
