extends Node
@onready var console = $"../.."
@onready var consoleRoot : Window =  $"../../../"


func close():## Hides the console
	consoleRoot.hide()


func clear():## Clears console output
	%logText.text = ""

func cls():## Clears console output
	clear()

func quit():## Closes the game
	get_tree().quit()

func tree():
	return EGLO.getTreeStructure($"/root")




func clearhistory():#Clears console history
	$"../..".history.clear()


## Lists all methods
func help():
	var retStr = ""
	var scriptNodes = %execute.get_children()
	
	
	for i in scriptNodes:
		var funcEntries = i.get_script().get_script_method_list()
		var funcColor = "cyan"
		retStr += "[color=" + funcColor +"]" +i.get_script().resource_path.get_file().split(".")[0] +"[/color]" + "\n"
		for function in funcEntries:
			retStr += "\t" + function.name + "\n"
	
	
	return retStr


func wireframe():
	if get_tree().get_root().debug_draw != Viewport.DEBUG_DRAW_WIREFRAME:
		get_tree().get_root().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	else:
		get_tree().get_root().debug_draw = Viewport.DEBUG_DRAW_DISABLED

func loader():## Opens MakeUI
	var node = load("res://addons/gameAssetImporter/scenes/makeUI/makeUI.tscn").instantiate()
	get_tree().get_root().add_child(node)

func inventory():
	var player1 = ENTG.getPlayers(get_tree())[0]
	var inventory = player1.inventory
	var retStr = ""
	
	for key in inventory.keys():
		retStr += key + ":" + str(inventory[key]) + "\n"
		
	return retStr
	

func standaloneloader():## Opens MakeUI
	var node = load("res://addons/gameAssetImporter/scenes/standaloneMenu/standaloneMenu.tscn").instantiate()
	get_tree().get_root().add_child(node)

## Spanws an entity
func spawn(entStr,gameStr = ""):
	entStr = entStr.to_lower()
	var players = get_tree().get_nodes_in_group("player")
	
	for i in players:
		if i.get_node_or_null("gunManager/shootCast") != null:
			var cast : RayCast3D = i.get_node_or_null("gunManager/shootCast")
			var point = cast.get_collision_point()
			
			var ent = ENTG.spawn(get_tree(),entStr,point,Vector3.ZERO,gameStr)
			if ent == null:
				print('Failed to spawn ' + entStr)
			return
	
	print('Failed to spawn ' + entStr)

## Mutes all sounds
func mute():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80)

## Lists every entity
func getentitylist(gameStr) -> String:
	gameStr = gameStr.to_lower()
	var dict = ENTG.getEntityDict(get_tree(),gameStr)
	var runningStr = ""
	
	for str in dict.keys():
		print(str)
		runningStr += str + "\n"
		
	return runningStr



func kill():## Kills the player
	for i in get_tree().get_nodes_in_group("player"):
		if i.has_method("takeDamage"):
			i.takeDamage({"amt":99999})


## Lists connected gamepads
func getinputs():
	var retStr = ""
	var inputs = Input.get_connected_joypads()
	
	for i in inputs:
		retStr += str(i) + ": " + Input.get_joy_name(i) + "\n"
		#var t3 = 3
		#retStr + Input.get_joy_info(i)["raw_name"] + "\n"
	
	return retStr

## Moves console to its own Window
func popout():
	consoleRoot.visible = false
	consoleRoot.force_native = true
	consoleRoot.visible = true
	

func nogravity():
	var player = get_tree().get_nodes_in_group("player")[0]
	player.movement.gravity = 0
	player.velocity.y = 0


func teleportorigin():
	var player = get_tree().get_nodes_in_group("player")[0]
	player.position = Vector3.ZERO

func position():
	var player = get_tree().get_nodes_in_group("player")[0]
	return str(player.position)

## Opens entity debug UI
func entdbg():
	var entDebugMenu = load("res://addons/gameAssetImporter/scenes/entityDebug/entityDebugDialog.tscn").instantiate()
	add_child(entDebugMenu)

## Opens timings UI
func timings():
	var timingsDebugMenu :=EGLO.fetchTimingsDebug(get_tree())
	#var timingsDebugMenu = load("res://addons/gameAssetImporter/scenes/timingsDebug/timingsDebugWindow.tscn").instantiate()
	timingsDebugMenu.visible = true
	#add_child(timingsDebugMenu)

## Deletes all saved timing data
func cleartimings():
	if FileAccess.file_exists("user://performanceTmings.csv"):
		DirAccess.remove_absolute("user://performanceTmings.csv")

func timingdir():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func opentimings():
	OS.shell_open(ProjectSettings.globalize_path("user://performanceTmings.csv"))

func orphans():
	print("--------")
	print_orphan_nodes()

func map(mapName:String):
	var map = ENTG.createMap(mapName,get_tree(),"")
	
	if map == null:
		return "map [color='red']%s[/color] not found" % [mapName]
	
	if !map.is_inside_tree():
		get_tree().get_root().add_child(map)
	
	for cMap in get_tree().get_nodes_in_group("level"):
		if cMap != map:
			cMap.queue_free()
	
func maplist():
	return mapnames()

func mapnames():
	return ENTG.printMapNames(get_tree(),"")

func clearentitycache():
	ENTG.clearEntityCaches(get_tree())
	
