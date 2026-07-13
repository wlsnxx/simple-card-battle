extends Node

const SERVER_IP = '127.0.0.1'
const SERVER_PORT = 9999
const MAX_PLAYERS = 2

var networkId = -1
var otherId = -1
var peer

func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

func create_server():
	peer = ENetMultiplayerPeer.new()
	var res = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if res != OK:
		print("ERROR create server")
		return
		
	multiplayer.multiplayer_peer = peer
	
	networkId = multiplayer.get_unique_id()
	set_multiplayer_authority(networkId)
	print(networkId)
	
func connect_to_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
func close_connection():
	networkId = -1
	otherId = -1
	
	if has_node("/root/Main"):
		get_node("/root/Main").queue_free()
	
	multiplayer.multiplayer_peer = null
	
	
func _player_connected(id): #Cliente contecatndo ao servidor
	print("Pid: " + str(id))
	otherId = id
	peer.get_host().refuse_new_connections(true)
	get_tree().change_scene_to_file('res://Main.tscn')
	
	
func _player_disconnected(id):
	get_tree().change_scene_to_file('res://Lobby.tscn')
	close_connection()
	print("PLR DISCONNECT")
	
func _connected_ok(): 
	networkId = multiplayer.get_unique_id()
	otherId = 1 #o servidor
	get_tree().change_scene_to_file('res://Main.tscn')
	print("SERVER CONNECT")
	
func _server_disconnected():
	print("SERVER DISCONNECT")
	pass # Server kicked us, show error and abort
	
func _connected_fail():
	print("FAIL!")
	