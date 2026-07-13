extends Node

func _ready():
	# Make the "Single" button pulse like Clash Royale
	var btn_single = $VBoxContainer/BtnSingle
	btn_single.pivot_offset = btn_single.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(btn_single, "scale", Vector2(1.1, 1.1), 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn_single, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	
	# Inject Coins Display dynamically
	var coins_panel = PanelContainer.new()
	var coins_label = Label.new()
	coins_label.text = "💰 Moedas: " + str(SaveService.get_coins())
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_panel.add_child(coins_label)
	
	# Position at top right
	coins_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coins_panel.position = Vector2(get_viewport().size.x - 200, 20)
	coins_panel.size = Vector2(180, 50)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(coins_panel)
	add_child(canvas_layer)

func _on_BtnSingle_pressed():
	Navigator.change_scene(SceneRoutes.GAME)


func _on_BtnMulti_pressed():
	#get_tree().change_scene('res://Lobby.tscn')
	#queue_free()
	pass
