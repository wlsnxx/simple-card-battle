## UiUtils.gd
##
## Utilidades de UI compartilhadas: variações de tema claro/escuro,
## formatação de números e toast de feedback.
##
## Regra do projeto (AI_PREFERENCES): estilize com theme_type_variation do
## base_theme.tres — nunca override manual de cor/fonte em script.

extends Node

## Fundo atual é claro? O jogo atualiza ao trocar skin/tema — variation()
## e as telas usam para escolher a variante Dark dos labels.
var background_light: bool = false


## Escolhe a variação de tema conforme o fundo ativo.
## Ex: label.theme_type_variation = UiUtils.variation(&"LabelBody", &"LabelBodyDark")
func variation(on_dark_bg: StringName, on_light_bg: StringName) -> StringName:
	return on_light_bg if background_light else on_dark_bg


## Formata um inteiro com separador de milhar: 1234567 → "1,234,567".
func format_score(n: int) -> String:
	if n == 0:
		return "0"
	var s := str(absi(n))
	var result := ""
	var count := 0
	for i: int in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" + result) if n < 0 else result


## Toast central: pop-in, ~1.4s visível, fade-out e auto-remoção.
## Não bloqueia input (mouse_filter ignore em toda a árvore).
func show_toast(host: Node, text: String, color: Color = Color.WHITE) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 110
	host.add_child(layer)

	# Wrapper Control para suportar animação de modulate (CanvasLayer não tem).
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14, 0.95)
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(3)
	sb.border_color = Color(color.r, color.g, color.b, 0.85)
	sb.content_margin_left = 56
	sb.content_margin_right = 56
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 16
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.modulate = color
	card.add_child(lbl)

	# Pop-in + auto fade-out. Tween ancorado no root: morre junto com a cena.
	card.scale = Vector2(0.85, 0.85)
	root.modulate.a = 0.0
	var tw := root.create_tween().set_parallel(true)
	tw.tween_property(root, "modulate:a", 1.0, 0.18)
	tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.4)
	tw.chain().tween_property(root, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(layer.queue_free)
