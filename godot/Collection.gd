extends Node

var ALL_CARDS = ["one", "two", "top", "x10", "back", "back_card"] # All available card textures
var card_size = 150
var grid: GridContainer
var coins_label: Label

func _ready():
	var bg = preload("res://Background.tscn").instantiate()
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(header)
	
	var btn_back = Button.new()
	btn_back.text = "< Voltar"
	btn_back.custom_minimum_size = Vector2(150, 0)
	btn_back.pressed.connect(func(): Navigator.change_scene(SceneRoutes.HOME))
	header.add_child(btn_back)
	
	var title = Label.new()
	title.text = "Minha Coleção"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	coins_label = Label.new()
	coins_label.text = "💰 " + str(SaveService.get_coins())
	header.add_child(coins_label)
	
	# Grid
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	
	_populate_grid()
	
	# Store
	var btn_buy = Button.new()
	btn_buy.text = "Comprar Nova Carta (100 Moedas)"
	btn_buy.custom_minimum_size = Vector2(0, 80)
	btn_buy.pressed.connect(_on_buy_pressed)
	vbox.add_child(btn_buy)

func _populate_grid():
	for child in grid.get_children():
		child.queue_free()
		
	var unlocked = SaveService.get_unlocked_cards()
	for card_data in unlocked:
		var c = preload("res://Card/Card.tscn").instantiate()
		c.cardType = card_data["t"]
		c.cardValue = card_data["v"]
		
		# We must wrap it in a Control node to fit the GridContainer properly
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(160, 240)
		
		c.position = Vector2(80, 120) # Center inside wrapper
		c.scale = Vector2(0.8, 0.8) # Scale down for collection
		c.initialize()
		
		# Disable input on the collection card
		c.set_process_input(false)
		if c.has_node("MoveShape"):
			c.get_node("MoveShape").disabled = true
			
		wrapper.add_child(c)
		grid.add_child(wrapper)

func _on_buy_pressed():
	if SaveService.get_coins() >= 100:
		SaveService.add_coins(-100)
		coins_label.text = "💰 " + str(SaveService.get_coins())
		AudioManager.play_victory()
		
		# Pick random card to unlock
		# Types: A=0, E=1, F=2, W=3, X=4
		var t = randi() % 5
		var v = (randi() % 9) + 2 if t < 4 else 10 # 2 to 10 for normal, 10 for X
		
		var new_card = {"t": t, "v": v}
		SaveService.unlock_card(new_card)
		_populate_grid()
		
		# Explode some particles in the center of screen (Gacha Feel)
		var p = GPUParticles2D.new()
		var mat = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 50.0
		mat.spread = 180.0
		mat.initial_velocity_min = 200.0
		mat.initial_velocity_max = 400.0
		mat.scale_min = 5.0
		mat.scale_max = 10.0
		mat.color = Color(1.0, 0.8, 0.2)
		p.process_material = mat
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = 50
		p.position = Vector2(360, 640) # Center of 720x1280
		add_child(p)
		p.emitting = true
	else:
		AudioManager.play_defeat() # Not enough coins
