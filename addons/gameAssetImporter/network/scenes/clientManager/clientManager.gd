class_name ClientManager
extends Node2D

var peer : PacketPeerUDP 

signal  serverJoined

const rttBufferSize = 10
var rttBuffer : PackedInt32Array = []
var awatingRTT : bool = false
var lastRTT = 0 
var networkInstanceableScenes : PackedStringArray
var networkPaths : PackedStringArray
var networkedNodes : Dictionary = {}
func _ready():
	multiplayer.connected_to_server.connect(serverConnected)

func joinServer(ip,port):
	peer = NETG.joinServer(get_tree(),ip,port)
	
	var err = peer.put_packet([1])
	lastRTT = Time.get_ticks_msec()
	awatingRTT = true


func serverConnected(server):
	server = multiplayer.multiplayer_peer.get_peer(1)
	breakpoint

func _process(delta: float) -> void:
	while peer.get_available_packet_count() > 0:
		var m = peer.get_packet()
		
		if awatingRTT == true:
			
			if rttBuffer.size() == rttBufferSize:
				emit_signal("serverJoined")
				awatingRTT = false
				peer.put_packet([1,1])#packet size of 2 will call initialization on server
			
			var thisRtt = Time.get_ticks_msec()-lastRTT
			lastRTT = Time.get_ticks_msec()
			rttBuffer.append(thisRtt)
			peer.put_packet([1])
			continue
		parsePacket(m)
		#print(m)

func _physics_process(delta: float) -> void:
	getGameState()
	pass

func getGameState():
	var arr : PackedByteArray= []
	
	
	#for i in networkedNodes():
	#	arr += getStateRecursive(i)
	print(arr)
	

func getAvgRTT():
	var avg : float = 0.0
	for i in rttBuffer:
		avg += i
		
	avg/= rttBuffer.size()
	return avg
	

func parsePacket(data : PackedByteArray):
	
	var buffer = StreamPeerBuffer.new()
	buffer.put_data(data)
	buffer.seek(0)
	
	var nFrame = buffer.get_u16()
	
	
	if buffer.get_size() == 2:
		#print("received frame:",nFrame)
		return
		
		
	print("received frame:",nFrame)

	var numSpawn = buffer.get_u8()
	var numSync = buffer.get_u8()
	
	if numSpawn >0:
		buffer.get_u8()
	
	
	var toSpawn = []
	
	for i in numSpawn:
		var sceneAndParent = [buffer.get_u16(),buffer.get_u16(),buffer.get_u16(),buffer.get_u8()]
		toSpawn.append(sceneAndParent)
	
	for i : Array in toSpawn: 
		var path = networkInstanceableScenes[i[0]]
		var parent = networkPaths[i[1]]
		
		var scene = load(path).instantiate()
		scene.clientManager = self
		var networkId = i[2]
		networkedNodes[networkId] = scene 
		if i[3] == 1:
			scene.isNetworkOwner = true
			scene.networkId = networkId
		var parentNode = get_node(parent)
		parentNode.add_child(scene)
	
	
	if numSync > 1:
		numSync = 1
	for i in numSync:
		var objectId = buffer.get_16()#get the nework object index
		var targetNode = networkedNodes[objectId]#todo: error case
		#var t = buffer.get_data(buffer.get_size()-buffer.get_position())
		#var err = t[0]#todo: dont proc on error
		
		#var streeamBuffer := StreamPeerBuffer.new()
		#streeamBuffer.put_data(buffer.data_array)
		#streeamBuffer.seek(0)
		
		targetNode.syncState(buffer)
		
func sendInput(bytes : StreamPeerBuffer):
	#print("sending frame:",Engine.get_physics_frames()," : ",bytes.data_array)
	var err = peer.put_packet(bytes.data_array)
	if err != OK:
		breakpoint
	
