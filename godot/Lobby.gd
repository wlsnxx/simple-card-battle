extends Control

func _on_BtnHost_pressed():

	$LblIP.visible = true
	$LblIP.text = "IP: " + str(IP.get_local_addresses()[1])
	
	$VBoxContainer/BtnHost.disabled = true	
	$VBoxContainer/BtnJoin.visible = false
	
	
	Network.create_server()
	
func _on_BtnJoin_pressed():
	Network.connect_to_server()
	#get_tree().change_scene('res://Main.tscn')
	
func _on_BtnVoltar_pressed():	
	Network.networkId = -1
	Network.close_connection()
	get_tree().change_scene_to_file('res://Menu.tscn')	
