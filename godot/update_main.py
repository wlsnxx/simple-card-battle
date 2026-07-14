import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace('SaveService.get_unlocked_cards()', 'SaveService.get_active_deck_cards()')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {filepath}")

process_file('Main1P.gd')
process_file('Main.gd')
