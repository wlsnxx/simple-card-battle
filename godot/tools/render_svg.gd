extends SceneTree
## Ferramenta headless: rasteriza um SVG em PNG e reporta o retângulo usado.
## Base para gerar logo.png, boot splash, ícones etc. a partir de um SVG
## fonte único (o Godot NÃO aceita SVG direto como boot splash — só raster).
## Uso: godot --headless --path godot -s res://tools/render_svg.gd -- <svg> <png> <scale>


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("uso: -- <svg> <png> <scale>")
		quit(1)
		return
	var svg_text: String = FileAccess.get_file_as_string(args[0])
	var img := Image.new()
	if img.load_svg_from_buffer(svg_text.to_utf8_buffer(), float(args[2])) != OK:
		push_error("falha ao rasterizar " + args[0])
		quit(1)
		return
	var used: Rect2i = img.get_used_rect()
	print("size=%dx%d used=%d,%d,%d,%d" % [
		img.get_width(), img.get_height(),
		used.position.x, used.position.y, used.size.x, used.size.y,
	])
	img.save_png(args[1])
	quit(0)
