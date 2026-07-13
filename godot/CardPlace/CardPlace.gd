extends Area2D

func _on_CardPlace_area_entered(card):	
	if not card.dropped:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			card.dropped = true
			card.areaToMove = self.get_node("Collision")
		
func _on_CardPlace_area_exited(card):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass
		#area.get_node("Sprite").texture = load("res://assets/card_place.png")
		#if areaToMove != null && area.name == areaToMove.name:
		#areaToMove = null
		#area.canDrop = false
