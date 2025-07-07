class_name ServerManager
extends Control


@export var port : int = 7777




var inputFrames : PackedByteArray = []
var networkedNodes : Dictionary = {}
var networkInstanceableScenes : PackedStringArray
var networkPaths : PackedStringArray
var clientInitalizationFunction : Callable = Callable.create(self,"dummyFunction")
var server : PacketPeerUDP


enum SPAWN_TYPE{
	SPAWN_SCENE,
	SPAWN_ENTITY
}


func  dummyFunction():
	return

var pathsToSpawn = {}
var statesToSerialize = []
var networkFrame = 0
#signal playerConnectedSignal(peer_id)
#signal playerDisconnectedSignal(peer_id)
#signal serverDisconnectedSignal

signal serverReceivedConnection
signal receivedClientConnection

@onready var tree : SceneTree = get_tree()

var clientList = {}
var rollback = false
func _ready():
	
	
	#get_tree().node_added.connect(nodeAdded)
	var allNoodes = EGLO.getChildrenRecursive($/root)
	
	#multiplayer.peer_connected.connect(receivedConnection)
	multiplayer.peer_disconnected.connect(playerDisconnected)
	#multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(serverConnected)
	#multiplayer.connection_failed.connect(_on_connected_fail)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	#init()
	pass


	

func createServer(port):
	server = NETG.createServer(tree,port)
	return server
	
	
	

func serverConnected(id):
	if id != 1:
		breakpoint
	#SyncManager.add_peer(1)
	
#func receivedConnection(id : int):
	#if rollback:
		#SyncManager.add_peer(id)
	#
	#
	#clientList[id] = multiplayer.multiplayer_peer.get_peer(id)
	#
	#if multiplayer.is_server():
		#emit_signal("serverReceivedConnection",id)
	#else:
		#emit_signal("receivedClientConnection",id)
	#

func playerDisconnected(id : int):
	print("player out:",id)
	

func serverPlayerJoined(id : int):
	await get_tree().create_timer(2.0).timeout
	
func serverClose():
	tree.reload_current_scene()
	
	

func getNetworkId():
	var id = 0
	for i in 65536:
		if !networkedNodes.has(i):
			id = i
			
			break
	
	return id

#func nodeAdded(node : Node):
	#
	#if node.has_method("tick"):
		#networkedNodes.append(node)
		#node.set_physics_process(false)
	#print("hi")
	

func _process(delta: float) -> void:
	pass


		
func _physics_process(delta: float) -> void:
	
	if server == null:
		return
	
	networkFrame = (networkFrame+1) % 65536
	
	while server.get_available_packet_count() > 0:
		var packet = server.get_packet()
		var ip = server.get_packet_ip()
		var port = server.get_packet_port()

		if packet.size() == 1:#ack rtt
			server.set_dest_address(ip, port)
			server.put_packet([1])
			continue
		
		if !clientList.has(ip):#add ip to list
			#var udp = PacketPeerUDP
			pathsToSpawn[ip] = []
			clientInitalizationFunction.call(ip)
			clientList[ip] = {}
		else:
			#var packetData = server.get_packet()
			if !packet.is_empty():
				parseClientInput(packet)
			else:#got empty packet
				breakpoint
			#	breakpoint
		
	
	
	for i in clientList:
		var ip = server.get_packet_ip()
		var port = server.get_packet_port()
		var clientPathsToSpawn = pathsToSpawn[i]
		
		
		var packetData = createPacket(clientPathsToSpawn,statesToSerialize)
		server.set_dest_address(ip, port)
		server.put_packet(packetData)
			
		pathsToSpawn[ip] = []
	statesToSerialize = []
	
	for networkId in networkedNodes.keys():
		var data := StreamPeerBuffer.new()
		data.put_16(networkId)
		networkedNodes[networkId].serializeState(data)
		statesToSerialize.append(data.data_array)

var requestId = 0
	
func spawnPath(ip,sceneIdx,path,clientOwnsInput = false):#index of netwrok secne and index of path
	
	pathsToSpawn[ip].append([sceneIdx,path,clientOwnsInput,requestId])
	requestId += 1
	return requestId-1
	

	

func createPacket(scenesToSpawn = [],statesToSync = []):
	var buffer := StreamPeerBuffer.new()
	
	
	var numSpawn = scenesToSpawn.size()
	var numSync = statesToSync.size()
	
	buffer.put_16(networkFrame)
	
	if numSpawn == 0 and numSync == 0:#just send current frame number as heartbeat
		return buffer.data_array
	
	buffer.put_u8(numSpawn)
	buffer.put_u8(numSync)
	
	
	var spawnType = SPAWN_TYPE.SPAWN_SCENE
	
	if numSpawn >0:
		buffer.put_u8(spawnType)
	
	for i in numSpawn:
		var clientOwnsInput =scenesToSpawn[i][2]
		var netowrkId = spawnSceneLocally(scenesToSpawn[i][0],scenesToSpawn[i][1])
		buffer.put_u16(scenesToSpawn[i][0])
		buffer.put_u16(scenesToSpawn[i][1])
		buffer.put_u16(netowrkId)
		buffer.put_8(clientOwnsInput)
	
	for i in numSync:
		buffer.put_data(statesToSync[i])
		
	
	return buffer.data_array

func spawnSceneLocally(scenePathId,parentPathIdx):
	var path = networkInstanceableScenes[scenePathId]
	var parent = networkPaths[parentPathIdx]
	var networkId = -1
	var scene = load(path).instantiate()
	var parentNode = get_node(parent)
	parentNode.add_child(scene)
	
	if scene.has_method("serializeState"):
		scene.udpPeer = server
		networkId =  getNetworkId()
		scene.networkId = networkId
		networkedNodes[networkId] = scene
	
	return networkId
	
func parseClientInput(data):
	var buffer = StreamPeerBuffer.new()
	buffer.put_data(data)
	buffer.seek(0)
	
	var frame = buffer.get_16()
	var objectId = buffer.get_16()
	var inputData = buffer.get_8()
	
	print("input for frame %s is %s @%s" %[frame,inputData,networkFrame])
	
	if networkedNodes.has(objectId):
		networkedNodes[objectId].setInputDictFromFrame(inputData)
		
	
	
