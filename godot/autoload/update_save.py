import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Modify _default_data to include active_deck
    default_data_str = '''		"unlocked_cards": [
			{"t": 0, "v": 2}, # Air 2
			{"t": 1, "v": 2}, # Earth 2
			{"t": 2, "v": 2}, # Fire 2
			{"t": 3, "v": 2}, # Water 2
			{"t": 0, "v": 3}  # Air 3
		],'''
    new_default_data_str = default_data_str + '''
		"active_deck": [0, 1, 2, 3, 4],'''
    
    content = content.replace(default_data_str, new_default_data_str)
    
    # 2. Add get_active_deck_indices and set_active_deck_indices below unlock_card
    unlock_func_str = '''func unlock_card(card_data: Dictionary) -> void:
	var cards = get_unlocked_cards()
	cards.append(card_data)
	data["unlocked_cards"] = cards
	save_all()'''
    
    new_methods = unlock_func_str + '''

func get_active_deck_indices() -> Array:
	return data.get("active_deck", [0, 1, 2, 3, 4])

func set_active_deck_indices(indices: Array) -> void:
	data["active_deck"] = indices
	save_all()
	
func get_active_deck_cards() -> Array:
	var unlocked = get_unlocked_cards()
	var indices = get_active_deck_indices()
	var deck = []
	for idx in indices:
		if idx < unlocked.size():
			deck.append(unlocked[idx])
	return deck
'''
    content = content.replace(unlock_func_str, new_methods)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {filepath}")

process_file('SaveService.gd')
