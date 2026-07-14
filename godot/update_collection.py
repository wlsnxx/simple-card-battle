import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add deck_label and active_deck
    content = content.replace('var coins_label: Label', 'var coins_label: Label\nvar deck_label: Label\nvar active_deck: Array\nconst MAX_DECK_SIZE = 15')
    
    # Add deck_label to header
    header_str = '''	coins_label = Label.new()
	coins_label.text = "?? " + str(SaveService.get_coins())
	header.add_child(coins_label)'''
    
    new_header_str = '''	active_deck = SaveService.get_active_deck_indices()
	deck_label = Label.new()
	deck_label.text = "Deck: " + str(active_deck.size()) + "/" + str(MAX_DECK_SIZE)
	deck_label.custom_minimum_size = Vector2(100, 0)
	header.add_child(deck_label)
	
''' + header_str
    
    content = content.replace(header_str, new_header_str)
    
    # Modify _populate_grid
    populate_str = '''	var unlocked = SaveService.get_unlocked_cards()
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
		grid.add_child(wrapper)'''
        
    new_populate_str = '''	var unlocked = SaveService.get_unlocked_cards()
	for i in range(unlocked.size()):
		var card_data = unlocked[i]
		var c = preload("res://Card/Card.tscn").instantiate()
		c.cardType = card_data["t"]
		c.cardValue = card_data["v"]
		
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(160, 240)
		wrapper.gui_input.connect(_on_card_gui_input.bind(i, c))
		wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		
		c.position = Vector2(80, 120)
		c.scale = Vector2(0.8, 0.8)
		c.initialize()
		c.set_process_input(false)
		if c.has_node("MoveShape"):
			c.get_node("MoveShape").disabled = true
			
		if active_deck.has(i):
			c.modulate = Color(1, 1, 1, 1)
		else:
			c.modulate = Color(0.4, 0.4, 0.4, 1)
			
		wrapper.add_child(c)
		grid.add_child(wrapper)
		
func _on_card_gui_input(event: InputEvent, idx: int, card_node: Node2D):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if active_deck.has(idx):
			active_deck.erase(idx)
			card_node.modulate = Color(0.4, 0.4, 0.4, 1)
			AudioManager.play_impact()
		else:
			if active_deck.size() < MAX_DECK_SIZE:
				active_deck.append(idx)
				card_node.modulate = Color(1, 1, 1, 1)
				AudioManager.play_impact()
			else:
				AudioManager.play_defeat()
		
		SaveService.set_active_deck_indices(active_deck)
		deck_label.text = "Deck: " + str(active_deck.size()) + "/" + str(MAX_DECK_SIZE)
'''
    content = content.replace(populate_str, new_populate_str)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {filepath}")

process_file('Collection.gd')
