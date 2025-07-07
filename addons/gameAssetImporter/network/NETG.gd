extends Node

class_name NETG

#const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

func createNetworkManager():
	var node = load("res://addons/gameAssetImporter/network/networkManager.tscn").instantiate()
	return node

static func createServer(tree:SceneTree,port : int,maxConnections = MAX_CONNECTIONS) ->  PacketPeerUDP:
	var server : PacketPeerUDP = PacketPeerUDP.new()
	
	
	var err = server.bind(port)
	
	if err != OK:
		breakpoint
	
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_server(port, MAX_CONNECTIONS)
	#
	#if error:
		#return error
		#
	#tree.get_root().multiplayer.multiplayer_peer = peer
	
	
	return server

static func joinServer(tree,ip,port):
	
	var server : PacketPeerUDP = PacketPeerUDP.new()
	if server.set_dest_address(ip, port) != OK:
		print("Failed to set destination address")
		return
	
	
	return server
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_client(ip,port)
	#tree.get_root().multiplayer.multiplayer_peer = peer
	#
	#return error
	

static func isHost(tree : SceneTree):
	return tree.get_root().multiplayer.is_server()
