extends Control

var networkManager = null

signal serverCreated 
signal clientCreated

var waitingOnRtTT= false

	
	


func _on_server_button_pressed() -> void:
	networkManager = load("res://addons/gameAssetImporter/network/scenes/serverManager/serverManager.tscn").instantiate()
	$"/root".add_child(networkManager)
	networkManager.createServer(int(%portText.text))
	#var ip = IP.get_local_interfaces()
	var ipAddr = ""
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and ip.begins_with("192.") and "." in ip:
			ipAddr = ip
	
	%ipLabel.text = ipAddr
	$Control.visible = false
	
	emit_signal("serverCreated",networkManager)

func _on_client_button_pressed() -> void:
	networkManager = load("res://addons/gameAssetImporter/network/scenes/clientManager/clientManager.tscn").instantiate()
	$"/root".add_child(networkManager)
	networkManager.joinServer(%ipText.text,int(%portText.text))
	$Control.visible = false
	
	networkManager.serverJoined.connect(emitClientCreatedSignal)


func emitClientCreatedSignal():
	#emit_signal("clientCreated")
	emit_signal("clientCreated",networkManager)
	
