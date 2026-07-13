# Comparativos antes/depois

Toda mudança visual entra aqui com prints **antes/depois**, e o PR linka o arquivo.

## Padrão

Arquivo `AAAA-MM-DD-<slug>.md`:

```markdown
# Comparativo — <título>

> **Branch:** `feat/...` · **Atualizado:** AAAA-MM-DD

<contexto em 1-3 linhas: o que mudou e por quê>

| Antes | Depois |
|:---:|:---:|
| <img src="img/AAAA-MM-DD-<slug>-antes.png" width="330"> | <img src="img/AAAA-MM-DD-<slug>-depois.png" width="330"> |

## Validação
- Headless limpo; GUT N/N
```

## Como gerar os prints

```bash
godot --path godot --resolution 720x1280 -- --goto <tela> --screenshot
# salva user://debug_ss.png → copie para docs/comparativos/img/
```

- **Antes**: capture ANTES de mexer (ou via `git stash` dos arquivos alterados).
- Estados sintéticos (save populado, dialog aberto, elemento efêmero): adicione
  um case no `DebugCLI._goto_screen` que prepara o estado — assim o print é
  reproduzível por qualquer um (humano ou IA).
