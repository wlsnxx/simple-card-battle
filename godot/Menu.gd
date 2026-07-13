extends Node

func _on_BtnSingle_pressed():
	Navigator.change_scene(SceneRoutes.GAME)


func _on_BtnMulti_pressed():
	#get_tree().change_scene('res://Lobby.tscn')
	#queue_free()
	pass
