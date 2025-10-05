extends Control


signal levelSelectedSignal
@onready var mapList: VBoxContainer = %mapList
@onready var loader = get_parent().get_node("loader")
var icons : Dictionary[String,Image]
var iconLoaderThread : Thread
var pIconDictSize = 0
var curMapHover : String = ""

func _on_visibility_changed() -> void:
	if visible == false:
		return
		
	 

func _physics_process(delta: float) -> void:
	
	if icons.size() != pIconDictSize:
		
		if icons.has(curMapHover):
			%previewImage.texture = ImageTexture.create_from_image(icons[curMapHover])
		elif icons.has("movie1"):
			%previewImage.texture = ImageTexture.create_from_image(icons["movie1"])
		else:
			return
		
		
	
	pIconDictSize = icons.size()

func iconsThreadWrapper(mapPath : String):
	icons = loader.mapLoader.getIconsFromMap("bigfile/levels/menu_models/data.lev")
	
	
	
func initialize():
	
	#icons = loader.mapLoader.getIconsFromMap("bigfile/levels/menu_models/data.lev")
	
	iconLoaderThread = Thread.new()
	iconLoaderThread.start(iconsThreadWrapper.bind("bigfile/levels/menu_models/data.lev"))
	
	#%previewImage.texture = ImageTexture.create_from_image(icons["asphalt1"])
	
	var allMapPaths = loader.getAllMapNames()
	
	var levelInternalNameToExternal = loader.levelInternalNameToExternal
	var allMapNames = []
	
	for i : String in allMapPaths:
		
		if i.find("level") ==- 1:
			continue
		
		if i.find("relic") !=- 1:
			continue
			
			
		if i.find("battle") != -1:
			continue
			
			
		var internalName = i
		
		var str = "levels/tracks/"
		if i.find(str) != -1:
			internalName = i.substr(i.find(str)+str.length())
		
		elif i.find("levels/battle/") != -1:
			str = "levels/battle/"
			internalName = i.substr(i.find(str)+str.length())
		
		elif i.find("levels/adventure/") != -1:
			str = "levels/adventure/"
			internalName = i.substr(i.find(str)+str.length())
		
		elif i.find("player_select") != -1:
			pass
		elif i.find("menu_models") != -1:
			pass
			
		else:
			continue
		#	i.find("")
			
			
		
		internalName =  internalName.substr(0,internalName.find("/"))
		
		var displayName = internalName
		
		if levelInternalNameToExternal.has(internalName):
			displayName = levelInternalNameToExternal[internalName]
		
		var button := Button.new()
		button.mouse_entered.connect(mapHover.bind(internalName,button))
		button.mouse_exited.connect(mapUnHover.bind(internalName,button))
		button.pressed.connect(mapSelected.bind(i))
		button.custom_minimum_size.x = 500
		button.text = displayName
		mapList.add_child(button)
		

func mapHover(mapName,button):
	
	curMapHover = mapName
	
	EGLO.playGrowAnimForNode(button,Vector2.ONE*1.1)
	
	if icons.has(mapName):
		%previewImage.texture = ImageTexture.create_from_image(icons[mapName])
	elif icons.has("movie1"):
		%previewImage.texture = ImageTexture.create_from_image(icons["movie1"])
	else:
		return


func mapUnHover(mapName,button):
	EGLO.playShrinkAnimForNode(button,Vector2.ONE)
	
func mapSelected(mapName):
	emit_signal("levelSelectedSignal",mapName)
