# AI_PREFERENCES.md

Canonical AI coding preferences for **Fingerdot**. 
High-density rules for minimal token consumption.

## GDScript Moderno (Godot 4.6)
- **Static Typing REQUIRED**: Use `: type`, `-> type`.
- **Inference**: Use `:=` only when type is crystal clear.
- **Typed Arrays**: Use `Array[Type]`.
- **Logic**: Prefer functional-style (lambdas) for signal wiring.

## UI Policy (TSCN-First) - MANDATORY
- **Static UI**: MUST be in `.tscn`. No `Label.new()`, `Button.new()`, `add_child()` for fixed layout.
- **Node Binding**: Use Scene Unique Names (`%NodeName`) and `@onready`.
- **Styling**: USE `theme_type_variation` (LabelTitle, LabelScore, etc.) from `base_theme.tres`.
- **NEVER**: Manually override `modulate`, `theme_override_colors`, or font sizes in script for static changes. Swap the variation instead.

## Gameplay Invariants
- **DashLink logic**: Fixed center dot color defines the unique valid path.
- **Winner Path**: Exactly one visible path must match FixedDot color.
- **Bomb indicator**: Keep `!` visible on bomb targets.
- **Localization**: Use `tr("KEY")` everywhere for UI text.

## Git & Validation
- **Headless check**: Always run Godot headless before finishing a task to catch hidden errors.
- **Atomic Commits**: One feature/fix per commit.
- **No Push**: Never push if there are editor warnings or linter errors in modified files.
