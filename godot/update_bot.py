import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace _act function
    act_str = '''func _act(root: Node) -> void:
	var btn: BaseButton = _find_first_button(root)
	if btn != null:
		press_button(btn)'''
        
    new_act_str = '''func _act(root: Node) -> void:
	if root.name == "Main1P" or root.name == "Main":
		var popup = root.get_node_or_null("PopupEnd")
		if popup and popup.visible:
			var btn = _find_first_button(popup)
			if btn:
				press_button(btn)
			return
			
		if root.has_method("isLocalTurn") and root.isLocalTurn():
			var my_cards = root.get_node_or_null("MyCardsLocation")
			if my_cards:
				var locations = my_cards.get_children()
				var available_cards = []
				for loc in locations:
					if loc.get_child_count() > 0:
						available_cards.append(loc.get_child(0))
				
				if available_cards.size() > 0:
					var card_to_play = available_cards[randi() % available_cards.size()]
					click(card_to_play.global_position)
					return
					
	var btn: BaseButton = _find_first_button(root)
	if btn != null:
		press_button(btn)

func click(pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = pos
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventMouseButton.new()
	up.position = pos
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	Input.parse_input_event(up)'''

    content = content.replace(act_str, new_act_str)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {filepath}")

process_file('autoload/AutoplayBot.gd')
