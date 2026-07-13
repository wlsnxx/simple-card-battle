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
	for card_id in unlocked:
		var tex_rect = TextureRect.new()
		tex_rect.texture = load("res://Card/" + card_id + ".png")
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(card_size, card_size * 1.4)
		grid.add_child(tex_rect)

func _on_buy_pressed():
	if SaveService.get_coins() >= 100:
		SaveService.add_coins(-100)
		coins_label.text = "💰 " + str(SaveService.get_coins())
		AudioManager.play_victory()
		
		# Pick random card to unlock
		var unlocked = SaveService.get_unlocked_cards()
		var locked = []
		for c in ALL_CARDS:
			if not c in unlocked:
				locked.append(c)
		
		if locked.size() > 0:
			var new_card = locked[randi() % locked.size()]
			SaveService.unlock_card(new_card)
			_populate_grid()
		else:
			print("All cards unlocked!")
	else:
		AudioManager.play_defeat() # Not enough coins
