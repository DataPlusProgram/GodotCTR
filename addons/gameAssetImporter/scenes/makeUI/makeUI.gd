@tool
extends Window


signal instance
signal diskInstance

@onready var paths = $h/v1/paths/v/v
@onready var cats = $h/v2/cats
@onready var previewNode = $h/v3/preview
@onready var previewWorld = $h.get_node("%SubViewport")
@onready var previewWorld2DContainer = $h.get_node("%SubViewportContainer2D")
@onready var previewWorld2D = previewWorld2DContainer.get_node("SubViewport")
@onready var previewWorldContainer = $h.get_node("%SubViewportContainer")
@onready var texturePreview = $h.get_node("%texturePreview")
@onready var gameList : ItemList = $h/v1/Panel/gameList
@onready var initialRot = Vector2(0,0)
@onready var editedNode = null
@onready var nameLabel = $h/v1/paths/v/h/gameNameEdit

@onready var optionsPanel = $h/v3/options
@onready var creditsButton =$h/v1/paths/v/HBoxContainer/creditsButton
@onready var instanceButton : Button = $h/v2/ui/instanceButton
@onready var importButton : Button = $h/v2/ui/importButton
@onready var fileWaiter = $resourceWaiter
@export var playMode = false

var pathScenePacked : PackedScene = preload("res://addons/gameAssetImporter/scenes/makeUI/path.tscn")

var threadedQueue : Dictionary[Thread,Array] = {}

var cur = null
var curName = ""
var curTree : Tree = null
var pEnt = null
var curEntTxt = ""
var curMeta = ""
var cat = ""
var loaders = []
var editorInterface = null
var gameToLoaderNode ={}
var gameToLoaderNodeDisk ={}
var gameToHistory = {}
var previousFiles = {}
var midiPlayer = null
var curGameName = ""
const destPath = "res://game_imports/"
var inspector = null



		

func _ready():
	
	
	EGLO.fetchTimingsDebug(get_tree())
	
	if playMode:
		$h/v2.visible = false
		$h/v3.visible = false
		$h.get_node("%loadButton").visible = false
		$h/v1/paths/v/HBoxContainer/playButton.visible = true
		$h/v1/paths/v/HBoxContainer/playButton.grab_focus()
	else:
		$h/v2.visible = true
		$h/v3.visible = true
		$h.get_node("%loadButton").visible = true
		$h.get_node("%playButton").visible = false

	$h.get_node("%soundFontPath").pathSet.connect(soundFontSet)
	
	gameList.clear()
	var preLoadLoader = false
	
	var loaders : PackedStringArray  = getLoaders(preLoadLoader)
	
	print("here are loaders:",loaders)
	
	var a = Time.get_ticks_msec()
	
	if preLoadLoader:#use threaded loading
		
		var breakFlag = false
		var loaderWait = loaders.duplicate()
		
		while !loaders.size() != 0:
			for i in loaderWait:
				if ResourceLoader.load_threaded_get_status(i) == ResourceLoader.THREAD_LOAD_LOADED:
					loaderWait.erase(i)
				OS.delay_msec(1)
		
		var loadersLoaded : Array[PackedScene]= []
		for i in loaders:
			loadersLoaded.append(ResourceLoader.load_threaded_get(i))
		
		instantiateLoadersPreloaded(loadersLoaded)
	else:
		instantiateLoaders(loaders)
	
	
	print_debug("loader instance time:",Time.get_ticks_msec()-a)
	makeHistoryFile()
	
	if gameList.get_selected_items().is_empty():
		if gameList.get_item_count() > 0:
			gameList.select(0)
			_on_gameList_item_selected(0)
	
	
	
	previewWorld.get_node("CameraTopDown").current = false
	previewWorld.get_node("Camera3D").current = true


	
	
	if texturePreview.texture == null:
			texturePreview.texture = ImageTexture.new()
			
			
	$h.get_node("%soundFontPath").setPathText(SETTINGS.getSetting(get_tree(),"soundFont"))
	
	gameList.configSelected.connect(rightClickConfig)

func rightClickConfig(configName):
	var textEdit : Window = load("res://addons/gameAssetImporter/scenes/textWindow/textWindow.tscn").instantiate()
	textEdit.title = configName
	add_child(textEdit)
	
	var path = "user://"+configName+".console"
	
	if FileAccess.file_exists(path):
		var content := FileAccess.get_file_as_string(path)
		textEdit.text = content
		
	
	textEdit.popup_centered()
	textEdit.closeWindowSignal.connect(commandEditClose)
	

func commandEditClose(textEdit : TextEdit,configName : String):
	var text := textEdit.text
	
	if text.is_empty():
		return
	
	var path = "user://"+configName+".console"
	
	
	
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)

func instantiateLoaders(loaders : Array[String]):
	
	var instancedLoaders = []
	
		
	
	for i : String in loaders:
		
		var loaded : PackedScene = load(i)
		var inst : Node = loaded.instantiate()
		
		processLoaderInstance(inst)
	
	

func instantiateLoadersPreloaded(loaders : Array[PackedScene]):
	for i : PackedScene in loaders:
		var inst = i.instantiate()
		
		processLoaderInstance(inst)
				
func processLoaderInstance(inst : Node):
	
	for gameName in inst.getConfigs():
		initGame(gameName,inst.scene_file_path)
		gameToHistory[gameName] = []
			
		var reqs = inst.getReqs(gameName)
			
		if reqs != null:
			for reqIdx in reqs.size():
				var req = reqs[reqIdx]
				gameToHistory[gameName].append([req["UIname"],"",[]])
		else:
			var dir = DirAccess.open("res://")
			dir.remove("history.cfg")
			gameToHistory.erase(gameName)
	

func setStyles():
	var bgStyle : StyleBoxFlat = Panel.new().get_theme_stylebox("panel").duplicate()
	
	if get_tree().has_meta("baseControl"):
		bgStyle = get_tree().get_meta("baseControl").get_theme_stylebox("panel").duplicate()
	
	
	if bgStyle.bg_color.v < 0.5:
		bgStyle.bg_color.v += 0.13
	else:
		bgStyle.bg_color.v -= 0.1
	
	#$h/v1/paths.set("theme_override_styles/panel",bgStyle)
	#$h/v1/Panel.set("theme_override_styles/panel",bgStyle)
	#$h/v1/paths.modulate
	$Panel.set("theme_override_styles/panel",bgStyle)
	
	
	var lineEditStyle = get_tree().get_meta("baseControl").get_theme_stylebox("panel").duplicate()
	

func getLoaders(loadThem = false) -> Array[String]:
	var loadersPaths : Array[String] = []
	
	
	if !ENTG.doesDirExist("res://addons"):
		print("Addons folder not found")
		return loadersPaths
	
	
	var dirsInAddonFolder = ENTG.getDirsInDir("res://addons")
	
	if dirsInAddonFolder.is_empty():
		print("Addons folder is emnpty")
	
	print("dirs in addons folder:",dirsInAddonFolder)
	
	for i in dirsInAddonFolder:
		
		var ret : Array[String] = []
		var dir = DirAccess.open("res://addons/"+i)
		
		
		var files = dir.get_files()
	
		for filePath : String in files:
			if filePath.find("_Loader") != -1:
				filePath = filePath.replace(".remap","")#this appears in exported
				
				if filePath.get_extension() != "tscn":
					continue
				
				loadersPaths.append("res://addons/"+ i +"/" +filePath)
				
				if loadThem:
					ResourceLoader.load_threaded_request("res://addons/"+ i +"/" +filePath)
		 
	return loadersPaths


func getFromConfig(path):
	var f : FileAccess = FileAccess.open(path,FileAccess.READ)
	var ret = f.get_as_text()
	
	if ret.is_empty(): return null
	return ret
	


func initGame(gameName,gameParam):
	gameList.add_item(gameName)
	gameList.set_item_metadata(gameList.get_item_count()-1,gameParam)

	

func _process(delta: float) -> void:
	
	
	
	
	instanceButton.disabled = !fileWaiter.waitingForFiles.is_empty()
	importButton.disabled = !fileWaiter.waitingForFiles.is_empty()
	
	if playMode:
		size = (get_parent().get_viewport().size)
		borderless =true


func _on_loadButton_pressed():
	loaderInit()
	
	
	if cur != null and is_instance_valid(cur):
		if inspector == null:
			inspector = Inspector.new()
			inspector.theme = load("res://addons/object-inspector/inspector_theme.tres")
			inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
			optionsPanel.add_child(inspector)
			
		inspector.set_object(cur)
		
	
		


func validatePaths():
	
	
	for i in paths.get_children():
		var iPath = i.getPath()
		if i.required == true and iPath.is_empty():
			i.setErrorText("*required")
			return false
		
		
		if iPath.contains("."):
			if !FileAccess.file_exists(iPath):
				i.setErrorText("Invalid path (File not found: %s)" % [iPath])
				return false
		
		else:
			if !DirAccess.dir_exists_absolute(iPath):
				i.setErrorText("Invalid path (File not found: %s)" % [iPath])
				return false
			
			
		i.setErrorText("")
		return true

func loaderInit(fast = false):
	var param = []
	
	if !validatePaths():
		return
	
	for i in paths.get_children():
		param.append(i.getPath())
	
	if cur == null:
		return
	
	
	if !playMode:
		var oldCur = cur
		cur = load(cur.scene_file_path).instantiate()
		add_child(cur)
		oldCur.queue_free()
		cur.params = [param,curGameName]
		cur.initialize(param,curGameName.to_lower(),(nameLabel.text).to_lower())
		
		
	else:
		cur.params = [param,curGameName]
		cur.initialize(param,curGameName.to_lower(),(nameLabel.text).to_lower())
	
	
	
	createLocalCache()
	for i in paths.get_children().size():
		var child = paths.get_child(i)
		
		if gameToHistory[curName].size() == i:
			gameToHistory[curName].append([])
		
		
		gameToHistory[curName][i] =[child.getLabelText(),child.getPath(),gameToHistory[curName][i-1][2]]
		
		var historyTriple : Array = gameToHistory[curName][i]
		
		if !historyTriple[2].has(child.getPath()):
			if historyTriple[2].size() > 3:
				historyTriple[2].resize(3)
				historyTriple[2].pop_front()
			historyTriple[2].append(child.getPath())
	updateHistoryFile()
	
	
	if fast:
		return

	if is_instance_valid(curTree):
		curTree.queue_free()
	
	var all = getCategories()
	var tree = createTree()
	curTree = tree
	

	var meta
	
	if all.has("meta"):
		meta = all["meta"]
		all.erase("meta")
	
	for i in all:
		populateTree(tree,i,[],meta)
	
	if get_node_or_null("%TreeSearch") != null:
		%TreeSearch.tree = tree
	

func initializeThreaded(arr):
	var cur = arr[0]
	var param = arr[1]
	var gameName = arr[2]
	
	cur.initialize(param,nameLabel.text.to_lower())

func createTree():
	
	var tree = Tree.new()
	
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.set_hide_root(true)
	var root = tree.create_item()
	#tree.create_item(root)
	cats.add_child(tree)
	
	tree.connect("item_selected", Callable(self, "itemSelected"))
	
	tree.item_collapsed.connect(collapseOrExpand)
	return tree

func collapseOrExpand(item):
	var itemText : String = item.get_text(0)
	
	
	var categories =  getCategories()
	
	
	if !itemText.is_empty():
		if categories.has(itemText):
			itemSelected(item)
			
func populateSection(tree : Tree,item : TreeItem,subItems,meta):
	var itemName = item.get_text(0)
	tree.release_focus()
	
	var subItemKeys = []
	
	if subItems is Dictionary:
		subItemKeys = subItems.keys()
		#subItemKeys.sort()
	else:
		subItemKeys = subItems 
		#subItemKeys.sort()
	
	for i in subItemKeys:
		var subItem = tree.create_item(item)
		subItem.set_meta("cat",itemName)
		subItem.set_text(0,i)
		
		if meta != null:
			if meta.has(i):
				for m in meta[i].keys():
					subItem.set_meta(m,meta[i][m])
		subItem.collapsed = true
		
		if itemName == "fonts" or itemName == "themes":
			subItem.set_meta("info",subItems[i])
			continue
		
		if typeof(subItems) == TYPE_DICTIONARY :
			
			##if typeof(subItems[i]) == TYPE_DICTIONARY:
			#	breakpoint
			if typeof(subItems[i]) != TYPE_STRING:
				var subsubkey = subItems[i]
				#subsubkey.sort()
				for j in subItems[i]:
					var subItem2 = tree.create_item(subItem)
					#subItem2.set_meta("cat",itemName)
					subItem2.set_meta("cat",itemName + "/" + i )
					subItem2.set_text(0,j)
	

func populateTree(tree : Tree,itemName,subItems,meta):
	var root = tree.get_root()
	var item = tree.create_item(root)
	
	
	item.collapsed = true
	item.set_text(0,itemName)
	
	var dummyItem = tree.create_item(item)

	
	for i in subItems:
		
		
		var subItem = tree.create_item(item)
		subItem.set_meta("cat",itemName)
		subItem.set_text(0,i)
		
		if meta != null:
			if meta.has(i):
				for m in meta[i].keys():
					subItem.set_meta(m,meta[i][m])
		subItem.collapsed = true
		
		if itemName == "fonts" or itemName == "themes":
			subItem.set_meta("info",subItems[i])
			continue
		
		if typeof(subItems) == TYPE_DICTIONARY :
			if typeof(subItems[i]) != TYPE_STRING:
				for j in subItems[i]:
					var subItem2 = tree.create_item(subItem)
					
					subItem2.set_meta("cat",itemName + "/" + i )
					subItem2.set_text(0,j)
				
				
func itemSelected(itemOveride = null):
	
	if !fileWaiter.waitingForFiles.is_empty():
		return
	
	await get_tree().physics_frame
	
	var item : TreeItem= curTree.get_selected()
	
	if itemOveride != null:
		item = itemOveride
	
	cat = "misc"
	var txt = item.get_text(0)
	
	
	
	if item.collapsed == true:
		clearEnt()
		
	
	#populateTree(curTree,txt,[],)
	
	previewWorldContainer.visible = false
	$h.get_node("%soundFontPath").visible = false
	$h.get_node("%fontPreview").visible = false
	curEntTxt = txt
	curMeta = {}
	
	
	if item.has_meta("cat"):
		cat = item.get_meta("cat")
	
	var categoryHierarchy = cat.split("/")

	for key in item.get_meta_list():
		if key != "__focus_rect":
			curMeta[key] = item.get_meta(key)
	
	
	
	
	if item.get_child_count() > 0:
		var cText = item.get_child(0).get_text(0)
		if cText == "":
			var allEntries = getAllInCategory(item.get_text(0))
			item.remove_child(item.get_child(0))
			populateSection(curTree,item,allEntries,curMeta)
	
	if categoryHierarchy.has("entities"):
		previewWorldContainer.visible = true
		clearEnt()
		

		var ent  = ENTG.spawn(cur.get_tree(),txt,{},Vector3.ZERO,Vector3.ZERO,nameLabel.text.to_lower(),previewWorld,false,false,get_tree().root)

		pEnt = ent
		
		if ent is Node2D:
			ent.ready.connect(ent.reparent.bind(previewWorld2D))
			previewWorld2DContainer.visible = true
			previewWorld2D.get_node("Camera2D").make_current() 
			
			
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print(previewWorld.get_node("CameraTopDown").current ,",",previewWorld.get_node("Camera3D").current )
			previewWorld.get_node("CameraTopDown").current = false
			previewWorld.get_node("Camera3D").current = true
	
	elif cat == "maps":
		previewWorldContainer.visible = true
		clearEnt()

		previewWorld.get_node("CameraTopDown").current = true
		previewWorld.get_node("Camera3D").current = false
		
		var mapNode = null
		
		if cur.has_method("createMapPreview"):
			mapNode = cur.createMapPreview(txt,curMeta,false,get_tree().get_root())
			
			
		else:
			mapNode = cur.createMap(txt)
		
		if mapNode.get_parent() != null:
			mapNode.get_parent().remove_child(mapNode)
		
		if mapNode != null:
			
			if mapNode.has_meta("boundingBox"):
				if mapNode.has_meta("center"):
					var bb = mapNode.get_meta("boundingBox")
					
					var fovRad = deg_to_rad(75.0)
					var camHeight = (max(bb.x,bb.z) / 2.0) / tan(fovRad / 2.0)
					
				#	previewWorld.get_node("CameraTopDown").position.y = #camHeight - 10
					previewWorld.get_node("CameraTopDown").dist = camHeight
					mapNode.position = - mapNode.get_meta("center")
					
			
			pEnt = mapNode
			previewWorld.add_child(mapNode)
			
		

	elif cat == "sounds":
		var sound = cur.createSound(txt,curMeta)
	
		var player = $h.get_node("%audioPreview")
		clearEnt()
		
		player.stream = cur.createSound(txt,curMeta)
		player.play()
		player.volume_db = -10
		
	elif cat == "textures" or categoryHierarchy.has("textures"):
		clearEnt()
		if categoryHierarchy.size() <2:
			return
		#if !cur.has_method("createTexture"):
		#	return
		var resType = categoryHierarchy[categoryHierarchy.size()-1]
		var x 
		if cur.resourceTypeToCreateFunction[resType].get_argument_count() == 1:
			x = cur.resourceTypeToCreateFunction[resType].call(curEntTxt)
		else:
			x = cur.resourceTypeToCreateFunction[resType].call(curEntTxt,{})
		#var x =  cur.createTexture(curEntTxt,curMeta)
		
		if x == null:
			return
		
		if "textureFiltering" in cur:
			if cur.textureFiltering == false: 
				texturePreview.texture_filter  = DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
			else:
				texturePreview.texture_filter  = DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		
		
		if x.get_class() == "AnimatedTexture":
			texturePreview.texture = x
			return


		
		
		if texturePreview.texture == null:
			texturePreview.texture = ImageTexture.new()
		
		
		if x is Texture:
			texturePreview.texture.image = x.get_image()
		
		if x is Image:
			texturePreview.texture.image = x
			
		if x is Sprite2D:
			texturePreview.texture.image = x.texture.image
			
	elif cat == "game modes":
		clearEnt()
		if cur.has_method("createGameModePreview"):
			var x = cur.createGameModePreview(txt,curMeta)
			texturePreview.texture = cur.createGameModePreview(txt,curMeta)
	
	elif cat == "fonts":
		
		var pToDisk = cur.toDisk
		cur.toDisk = false
		var font = cur.fetchFont(txt)
		cur.toDisk = pToDisk
		$h.get_node("%fontPreview").visible = true
		$h.get_node("%fontPreview").set("theme_override_font_sizes/font_size",16)
		$h.get_node("%fontPreview").add_theme_font_override("font",font)
	
	elif cat == "models":
		
		previewWorldContainer.visible = true
		clearEnt()
		
		var model 
		
		
		#if cur.has_method("createModelThreaded"):
			#var resultStorage = []
			#var thread = cur.createModelThreaded(txt,resultStorage) 
			#threadedQueue[thread] = resultStorage
			#return
		
		model = cur.createModel(txt) 
		
		if model != null:
			pEnt = model
			previewWorld.add_child(model)
		
	elif categoryHierarchy.has("mus") or categoryHierarchy.has("midi"):
		
		if midiPlayer == null:
				
			midiPlayer = ENTG.createMidiPlayer(SETTINGS.getSetting(get_tree(),"soundFont"))
			previewNode.add_child(midiPlayer)
				
		
		if categoryHierarchy.has("mus"):
			var midiData :  PackedByteArray= cur.createMidi(txt)
			ENTG.setMidiPlayerData(midiPlayer,midiData)
			midiPlayer.play()
			$h.get_node("%soundFontPath").visible = true
		
		elif categoryHierarchy.has("midi"):
			var midiData : PackedByteArray= cur.createMidi(txt)
			ENTG.setMidiPlayerData(midiPlayer,midiData)
			midiPlayer.play()
			$h.get_node("%soundFontPath").visible = true

			
		

func fetchLoader(loaderPath):
	pass

func _on_gameList_item_selected(index: int):#game selected
	
	if gameList == null:
		return
	
	if !fileWaiter.waitingForFiles.is_empty():
		return
		
	clearEnt()
	$h.get_node("%playButton").text = "Play"
	$h.get_node("%playButton").disabled = false
	
	var gameLoader  = gameList.get_item_metadata(index)
	var gameName : String = gameList.get_item_text(index)
	curGameName = gameName
	curName = gameName
	nameLabel.text = gameName.to_lower()
	
	if !gameToLoaderNode.has(gameName):
		var loader = gameLoader
		
		if loader is not PackedScene:
			loader = load(loader).instantiate()
		else:
			loader = loader.instantiate()
			
		add_child(loader)
		gameToLoaderNode[gameName] = loader

	
	
	for i : Node in cats.get_children():
		i.queue_free()
	
	clearEnt()
		
	
	cur = gameToLoaderNode[gameName]
	
	for i in paths.get_children():
		i.queue_free()
	
	
	var reqs : Array = cur.getReqs(gameName)
	
	if gameToHistory.has(gameName):
		var initReqs : Array = reqs.duplicate(true)
		reqs = []
		for savedReq : Array in gameToHistory[gameName]:
			var uiName : String = savedReq[0]
			
			for reqDef : Dictionary in initReqs:
				var thisReqDef : Dictionary = reqDef.duplicate(true)
				
				if reqDef["UIname"] == uiName:
					reqs.append(thisReqDef)
					
					if reqDef["required"] == false:
						var count : int = 0
						for i in reqs:
							if i["UIname"] == uiName:
								count +=1
								if count > 1:
									thisReqDef["extra"] = true
				
				
	
	var i : int = 0
	
	for rIdx in reqs.size():
		var r : Dictionary = reqs[i]
		var UIname : String = "path"
		var required : bool= true
		var ext : Array= [""]
		var multi : bool = false 
		var fileNames : Array= []
		var hints : Array = []
		var extra : bool = false
		if r.has("UIname") : UIname = r["UIname"]
		if r.has("required") : required = r["required"]
		if r.has("ext") : ext = r["ext"]
		if r.has("multi") : multi = r["multi"]
		if r.has("fileNames"): fileNames = r["fileNames"]
		if r.has("hints"): hints = r["hints"]
		if r.has("extra"): extra = r["extra"]
		
		
		var node : Node = pathScenePacked.instantiate()
		node.signalNewPathCreated.connect(newPathCreated)
		node.removedSignal.connect(pathRemoved)
		node.enterPressed.connect(_on_playButton_pressed)
		node.required = required
		node.many = multi
		paths.add_child(node)
		node.setText(UIname)
		
		
		if extra:
			node.showDeleteButton()
			
		if ext.is_empty():
			node.setAsDir()
		else:
			node.setExt(ext)
			
		
		if !fileNames.is_empty():
			
			var exts = []
			
			
			for e in ext:
				exts.append(e.replace("*.",""))
			
			if OS.has_feature("android"):
				
				var t= OS.get_data_dir()
				
				var test = findFiles(fileNames,hints,exts,OS.has_feature("android"))
				breakpoint
			
			node.popupStrings = findFiles(fileNames,hints,exts,false)

			
		i+=1
		
		if gameToHistory.has(gameName):
			if !gameToHistory[gameName].is_empty():
				var savedPaths : Array = gameToHistory[gameName]
				
				if rIdx < savedPaths.size():
				
					var historyPath : String = gameToHistory[gameName][rIdx][1]
						
					if historyPath.find(".") != -1:
						if doesFileExist(historyPath):
							node.setPathText(historyPath)
							
					elif ENTG.doesDirExist(historyPath):
						node.setPathText(historyPath)
				
				for path in savedPaths:
					
					if node.getLabelText() != path[0]:
						continue
					
					for recentPath in path[2]:
						if !node.popupStrings.has(recentPath) and node.getPath() != recentPath:
							node.popupStrings.append(recentPath)
					
					if path[1] == "":
						if node.getPathCount() > 0:
							node.setPathText(node.popupStrings[0])
					else:
						break

			else:
				breakpoint 
		
	if cur.has_method("getCredits"):
		creditsButton.visible = true
	else:
		creditsButton.visible = false

				





func _on_debugButton_pressed():
	var l = load("res://addons/gameAssetImporter/scenes/entityDebug/entityDebugDialog.tscn").instantiate()
	add_child(l)
	l.popup_centered_ratio(0.4)


func clearEnt() -> void:
	if pEnt != null and is_instance_valid(pEnt):
		pEnt.queue_free()
		pEnt = null
	
	
	if ENTG.fetchMidiPlayer(get_tree()) != null:
		ENTG.fetchMidiPlayer(get_tree()).stop()
	
	if midiPlayer != null:
		midiPlayer.stop()
	
	texturePreview.texture  = null

	

func findFiles(files,hints,ext,androidTest):
	
	var filesLower = []
	var ret = []
	var found = []
	
	
	for f in files:
		filesLower.append(f.to_lower())
	
	var a = Time.get_ticks_msec()
	
	var t = getDrives()
	
	
	var allFiles = []
	
	if androidTest:
		if DirAccess.dir_exists_absolute(t[1]):
			allFiles = allInDirectory2(t[1], ext)
			breakpoint
		
		
	allFiles = getAllFlat2("res://",ext,["/game_imports","/addons","/dbg"])
	
	SETTINGS.setTimeLog(get_tree(),"get all files time",a,str(files),"makeUI")

	for f in allFiles:
		var fn = f.get_file().to_lower()
		
	
		if filesLower.has(fn):
			ret.append(f)
			found.append(fn)
	
	
	for i in hints:
		var target = i.split(",")[0]
		var postFix = i.split(",")[1]
		
		if target == "steam":
			var steamDirs = steamUtil.findSteamDir()
			
			for dir in steamDirs:
				var path = dir + postFix
				if !steamUtil.doesDirExist(path):
					continue
				
				if files.size() == 1:
					if files[0].is_empty():
						ret.append(path)
						return ret
				for f in files:
					
					if doesFileExist(path+ "/" + f):
						if found.has(f.to_lower()):
							continue
						ret.append(path+ "/" + f)
						found.append(f.to_lower())
						
						
						if found.size() == files.size():
							return ret
		
		if target == "program files":
			var dirs = findProgramFilesDir()
			for j in dirs:
				for f in files:
					if ENTG.doesDirExist(j + postFix + "/" + f):
						ret.append(j + postFix + "/" + f)
						
						found.append(f.to_lower())
						
						if found.size() == files.size():
							return ret
			
		
	
	for i in ret.size():
		ret[i] = ProjectSettings.localize_path(ret[i])
	
	return ret

static func findProgramFilesDir() -> Array[String]:
	var ret : Array[String] = []
	var drives : Array[String] = getDrives()
	
	for i : String in drives:
		if ENTG.doesDirExist(i + "/Program Files (x86)/"):
			ret.append(i + "/Program Files (x86)/")
		
	return ret

static func getDrives() -> Array[String]:
	var ret : Array[String] = []
	
	for i in DirAccess.get_drive_count():
		ret.append(DirAccess.get_drive_name(i))
		
	return ret

static func getAllFlat(path,filter = null):
	var ret = []
	var all = allInDirectory2(path,filter)
	
	for i in all:
		if i.find(".") == -1:
			ret += getAllFlat(path + "/" + i,filter)
		
		else:
			ret.append(path + "/" + i)
			
	return ret

static func getAllFlat2(path: String, filter: PackedStringArray = [],ingoreDir = "",maxDepth = -1) -> Array:
	var ret = []
	var stack = [path]
	
	while stack.size() > 0:
		var current_path = stack.pop_back()
		
		var skip = false
		
		for i in ingoreDir:
			if current_path.find(i) != -1:
				skip = true
				break
		
		if skip:
			continue
		
		var entries = allInDirectory2(current_path, filter)
		
		for entry in entries:
			var full_path = current_path + "/" + entry
			
			if entry.find(".") == -1:
				stack.append(full_path)  
			else:
				ret.append(full_path) 
	
	return ret

	
static func allInDirectory(path,filter=[]):
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return []
		
	dir.list_dir_begin()  # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			
			if file.find(".") == -1:
				files.append(file)
			else:
				#if filter != null:
				if !filter.is_empty():
					for i in filter:
						var ext = file.split(".")
						ext = ext[ext.size()-1].to_lower()
						if ext.find(i)!= -1:
							files.append(file)
				else:
					files.append(file)
					

	dir.list_dir_end()

	return files
	

static func allInDirectory2(path: String, filter: Array = []) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return []  # Return empty array if directory cannot be opened
	
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break  # End of directory contents
		if file.begins_with("."):
			continue  # Skip hidden files and directories
		
		if file.find(".") == -1:
			# If no dot in the name, assume it's a directory
			files.append(file)
		else:
			# Handle files with extensions
			if filter.is_empty():
				files.append(file)  # Add all files if no filter is provided
			else:
				var ext = file.get_extension().to_lower()
				if ext in filter:
					files.append(file)
	
	dir.list_dir_end()
	return files



func _on_instanceButton_pressed():
	

	if curEntTxt.is_empty():
		return
		
	
	var targetTree = get_tree()
	
	var returnCache = ENTG.fetchEntityCaches(targetTree,nameLabel.text,true)
	
	var localCache = getLocalCache(targetTree,"",editedNode)
	
	if localCache == null:
		createLocalCache()
		localCache = getLocalCache(targetTree,"",editedNode)
		
	
	
	if returnCache == null:
		return
	
	if cat == "game modes":
		var mode = cur.createGameMode(curEntTxt)
		emit_signal("instance",mode,null)
		return
	
	if cat ==  "maps":
		var pGameName = cur.gameName
		cur.gameName = curName
		#ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur,editedNode)
		var map = cur.createMap(curEntTxt,curMeta,returnCache)
		
		cur.gameName = pGameName
		
		
		returnCache = copyDependentEntitiesToCacheAuto(targetTree)
		return emit_signal("instance",map,returnCache)
	
	if cat == "models":
		
		previewWorldContainer.visible = true
		clearEnt()
		
		var model = cur.createModel(curEntTxt,{}) 
		return emit_signal("instance",model,returnCache)
	
	if cat == "textures":
		var image = cur.createTexture(curEntTxt,curMeta)
		
		if image == null:
			return
			
		var type : String = image.get_class()
		var texture = null
		
		if type == "Image":
			texture = ImageTexture.new()
			texture.image = image
			
		if type == "AnimatedTexture":
			texture = image
		
		
		var ret = Sprite2D.new()
		
		ret.texture = texture
		
		if "textureFiltering" in cur:
			if cur.textureFiltering == false:
				ret.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			else:
				ret.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		return emit_signal("instance",ret,returnCache)
	
	
	ENTG.updateEntitiesOnDisk(targetTree)


	var ent = ENTG.fetchEntity(curEntTxt,{},targetTree,nameLabel.text,false,false,targetTree.get_root())
	
	var depends = []
	

	if ent.has_meta("entityDepends"):
		depends = ent.get_meta("entityDepends")
		returnCache = copyDependentEntitiesToCache(targetTree,ent,depends)
		
	emit_signal("instance",ent,returnCache)
	

func copyDependentEntitiesToCacheAuto(targetTree):
	var cacheSrc =  ENTG.fetchEntityCaches(targetTree,"",false,get_tree().get_root())[0]
	var cacheDest = ENTG.fetchEntityCaches(targetTree,"",false,editedNode)[0]
	var visited = []
	var procArray : PackedStringArray = []
	
	for ent in cacheSrc.get_children():
		if ent.has_meta("entityDepends"):
			for depEnt in ent.get_meta("entityDepends"):
				if !procArray.has(depEnt):
					procArray.append(depEnt)
	
	
	recursiveMove(cacheSrc,cacheDest,procArray,visited)
	return cacheDest
		#copyDependentEntitiesToCache(visited)
	
	
func getLocalCache(targetTree,gamename,editedNode):
	var caches =  ENTG.fetchEntityCaches(targetTree,"",false,editedNode)
	
	if caches.size() == 0:
		return null

	
	return caches[0]


func createLocalCache() -> Node:
	var cache : Node= ENTG.createEntityCacheForGame(get_tree(),false,nameLabel.text,cur,editedNode)
	cache.tree_exited.connect(ENTG.clearEntityCaches.bind(get_tree()))
	return cache
	
func copyDependentEntitiesToCache(targetTree,ent,depends,visited = []):
	var cacheSrc =  ENTG.fetchEntityCaches(targetTree,"",false,get_tree().get_root())[0]
	var cacheDest = getLocalCache(targetTree,"",editedNode)
	
	
	if ent.has_meta("entityDepends"):
		depends = ent.get_meta("entityDepends")
		recursiveMove(cacheSrc,cacheDest,depends,visited)
	
	return cacheDest
	

func recursiveMove(source : Node,dest : Node,entStrArr,visited = []):
	
	
	for entStr in entStrArr:
		entStr = entStr.to_lower()
		if visited.has(entStr):
			continue
		
		var entity = source.get_node_or_null(entStr)
		
		
		if entity == null:
			continue
		
		
		if !dest.has_node(entStr):
			entity.reparent(dest)
		
		visited.append(entStr)
		
		if entity.has_meta("entityDepends"):
			var depends = entity.get_meta("entityDepends")
			recursiveMove(source,dest,depends,visited)
		
	

	
func getTree():
	if  editedNode != null:
		return editedNode
	
	return get_tree()
		
		

func getSettingsAsText() -> String:
	
	var selectedGame : String = ""
	
	if !gameList.get_selected_items().is_empty():
		selectedGame = gameList.get_item_text(gameList.get_selected_items()[0])
	
	var settingsDict : Dictionary = {
		
		"savedToPath":gameToHistory,
		"selectedGame": selectedGame,
		"previousFiles": previousFiles
	}
	return var_to_str(settingsDict)

func makeHistoryFile() -> void:
	
	if !doesFileExist("history.cfg"):
		var f : FileAccess = FileAccess.open("history.cfg",FileAccess.WRITE)
		if f == null:
			print("could not make history file")
			return
			
		f.store_string(getSettingsAsText())
		f.close()
	
	var f : FileAccess= FileAccess.open("history.cfg",FileAccess.READ_WRITE)
	var savedSettingsDict =  str_to_var(f.get_as_text())
	
	
	
	if typeof(savedSettingsDict) != TYPE_DICTIONARY:
		f.store_string(getSettingsAsText())
		f.close()
		return

	var gameHistoryDict : Dictionary = savedSettingsDict["savedToPath"]
	
	for gameName : String in gameHistoryDict.keys():
		
		if !gameToHistory.has(gameName):
			continue
		
		for pathIdx : int in gameHistoryDict[gameName].size():
			
			
			
			var curGameHistory : Array = gameHistoryDict[gameName]
			var pathStr : String = curGameHistory[pathIdx][1]
			
			if pathStr.is_empty():
				continue
			
			var labelText : String = curGameHistory[pathIdx][0]
			var recents : Array = curGameHistory[pathIdx][2]
			

			if pathStr.find(".") != -1:
				if doesFileExist(pathStr):
					if gameToHistory[gameName].size() == pathIdx:
						gameToHistory[gameName].append(["","",[]])
					
					
					gameToHistory[gameName][pathIdx][0]= labelText
					gameToHistory[gameName][pathIdx][1]= pathStr
					gameToHistory[gameName][pathIdx][2] = recents
					
			else:
				if ENTG.doesDirExist(pathStr):
					gameToHistory[gameName][pathIdx][0]= labelText
					gameToHistory[gameName][pathIdx][1]= pathStr
					gameToHistory[gameName][pathIdx][2] = recents
					
	
	
	
	if !savedSettingsDict["selectedGame"].is_empty():
		var target : String = savedSettingsDict["selectedGame"]
		for i : int in gameList.get_item_count():
			if gameList.get_item_text(i)== target:
				gameList.select(i)
				_on_gameList_item_selected(i)
				break
			
		
		
	f.close()
	
func updateHistoryFile():
	if !doesFileExist("history.cfg"):
		var f = FileAccess.open("history.cfg",FileAccess.WRITE)
		if f!= null:
			f.close()
	
	var f = FileAccess.open("history.cfg",FileAccess.WRITE)
	
	if f == null:
		print_debug("cannot upen history")
		return
	f.store_string(getSettingsAsText())
	f.close()


func createHistDict():
	var dict = {}
		
	for i in gameToLoaderNode.keys():
		dict[i] = ""
	
	
	return dict

static func doesFileExist(path : String) -> bool:
	var ret = FileAccess.file_exists(path)
	return ret


var oldName = ""
var pToDisk = null



func createMapThreaded(arr):
	var mapName = arr[1]
	var cur = arr[0]
	#var map = mapThread.start(cur,"createMap",entStr,Thread.PRIORITY_HIGH)
	var map = cur.createMap(mapName,curMeta)
	
	ENTG.recursiveOwn(map,map)
	var ps = PackedScene.new()

	
	for i in map.get_children():
		#if i.name == "Entities":
		#	i.get_parent().remove_child(i)
		
		#if i.name == "SectorSpecials":
		#	i.get_parent().remove_child(i)
			
		#if i.name == "Geometry":
		#	i.get_parent().remove_child(i)
		
		#if i.name == "Interactables":
		#	i.get_parent().remove_child(i)
		
		pass
	
	
	ps.pack(map)

	var destPath = "res://game_imports/"+cur.gameName+"/maps/"+curEntTxt+".tscn"
	
	
	for i in map.get_children():#this is needed to stop ghost nodes
		map.remove_child(i)
	

	
	#OS.delay_msec(2000)
	ResourceSaver.save(ps,destPath)
	
	#OS.delay_msec(2000)
	
	map.queue_free()
	#
	emit_signal("diskInstance",ResourceLoader.load(destPath).instantiate())
	


func _on_importButton_pressed():
	oldName = cur.gameName
	
	if curEntTxt.is_empty():
		return
	
	if "toDisk" in cur:#loader has this var. Once set on every resource fetch will save to disk:
		pToDisk  = cur.toDisk
		cur.toDisk = true
		
	cur.gameName = oldName.split("_")[0]
	
	importHead()
	

func importHead():
	
	if cur.has_method("getReqDirs"):
		createDirectories(nameLabel.text,cur.getReqDirs())
	else:
		createDirectories(nameLabel.text)
	
	var categoryHierarchy = cat.split("/")
	
	if cat == "maps":
		var resEntries = cur.getMapDepends(curEntTxt)
		
		for i in resEntries:
			
			if i.is_empty():
				continue
			
			if i[0] == "entity":
				for entityName in i[1]:
					resEntries += ENTG.getEntityResourceEntries(cur,entityName)
		
		saveAllEntriesToDisk(resEntries,true)
		fileWaiter.queuedSaves.append(saveMapToDisk.bind(curEntTxt))
		
		#cur.createMapResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	elif cat == "game modes":
		curMeta["destPath"] = "res://game_imports/"+cur.gameName
		var entries = cur.getAllGameModeEntries(curEntTxt)
		
		var fontEntries = cur.getAllFontEntries()
		
		for fontName in fontEntries:
			entries += fontEntries[fontName]
		
		var entityEntries = cur.getEntityDict()
		
		
		for entName in entityEntries:
			var entResDeps = ENTG.getEntityResourceEntries(cur,entName)
			entries += entResDeps
			
		
		fileWaiter.queuedSaves.append(saveEntitiesToDisk.bind(entityEntries.keys()))
		fileWaiter.queuedSaves.append(saveModeToDisk.bind(curEntTxt))
		saveAllEntriesToDisk(entries)
		
		
		
		
	elif categoryHierarchy.has("midi") or categoryHierarchy.has("mus"):
		var entries = getEntry(curEntTxt,cur.getAllMusicEntries())
		saveAllEntriesToDisk(entries)
		

	elif cat == "textures" or categoryHierarchy.has("textures"):
		
		var resType = categoryHierarchy[categoryHierarchy.size()-1]
		
		saveAllEntriesToDisk([[resType,curEntTxt]])
		
	elif cat == "fonts":
		var fontEntries = cur.getAllFontEntries()
		var entries = fontEntries[curEntTxt]
		saveAllEntriesToDisk(entries,true)
		fileWaiter.queuedSaves.append(saveFontToDisk.bind(curEntTxt))
		
	elif cat == "models":
		breakpoint
	
	elif cat == "themes":
		curMeta["destPath"] = "res://game_imports/"+cur.gameName +"/themes/"
		var theme = cur.createThemeDisk(curEntTxt,curMeta)
	else:
		var visited = []
		var entries = ENTG.getEntityResourceEntries(cur,curEntTxt,visited)
		saveAllEntriesToDisk(entries,true)
		
		fileWaiter.queuedSaves.append(saveEntitiesToDisk.bind(visited))
		
	

	
	
	
var mapThread = Thread.new()


func saveAllEntriesToDisk(resourceEntries,blocking =true):
	var procced = {}
	for entry in resourceEntries:
		
		
		if entry.is_empty():
			continue
		
		
		
		if entry[0] == "font":
			var fontEntries = cur.getAllFontEntries()
			
			for fontName in fontEntries:
				for subEntry in fontEntries[fontName]:
					saveAllEntriesToDisk([subEntry])
			
			continue
		
		if !(entry[1] is Array) and !(entry[1] is PackedStringArray):
			saveToDiskFunction(entry,blocking)
		else:
			var typeName = entry[0]
			var params = {}
			
			if entry.size() > 2:
				params = entry[2]
			
			for i in entry[1]:
				saveToDiskFunction([typeName,i,params],blocking)
			
			

func saveToDiskFunction(resourceEntry,blocking):
	
	if resourceEntry[0] == "entity":
		return
	
	var f: Callable = cur.resourceTypeToCreateFunction[resourceEntry[0]]
	
	var extension = ".png"
	var path = "textures"
	var params = {}
	var resources = []
	
	
	if resourceEntry[1] is PackedStringArray:
		resources = resourceEntry[1]
	else:
		resources = [resourceEntry[1]]
	
	
	if resourceEntry.size() == 3:
		params = resourceEntry[2]
	
	if params.has("extension"):
		extension = params["extension"]
	
	if "resourceTypeDefaultSaveDir" in cur:
		if cur.resourceTypeDefaultSaveDir.has(resourceEntry[0]):
			path =  cur.resourceTypeDefaultSaveDir[resourceEntry[0]]
	
	if params.has("path"):
		path = params["path"]
	
	
	
	
	for i in resources:
		
		
		var filePath = "res://game_imports/"+cur.gameName+"/"+path+"/"+i.get_file().split(".")[0]+extension
	#	var filePath = "res://game_imports/"+cur.gameName+"/"+path+"/"+i+extension
		
		filePath = filePath.replace("\\","--")
		
		var ret = null
		
		
		if f.get_argument_count() == 1:
			ret = f.call(i)
		else:
			ret = f.call(i,params)
		
		
		
		if ret == null:
			continue
		
		if ret is PackedByteArray:#if editor isn't importing the file the is this even nessecary?
			var file = FileAccess.open(filePath,FileAccess.WRITE)
			file.store_buffer(ret)
			file.close()
			continue
		
		elif ret is ImageTexture:
			ret.get_image().save_png(filePath)
		else:
			ResourceSaver.save(ret,filePath)
		
		if blocking:
			fileWaiter.addFileToWaitList(filePath)

func getEntry(id : String,entries):
	
	
	for entry : Array in entries:
		
		var type : StringName = entry[0]
		var params = {}
		
		if entry.size() == 3:
			params = entry[2]
		
		if entry[1] is Array:
			var find = entry[1].find(id)
			
			if find != -1:
				return [[entry[0],entry[1][find],params]]
			
		else:
			breakpoint
		
		breakpoint
	breakpoint

func _physics_process(delta):
	
	if texturePreview != null:
		texturePreview.visible = false
	
		if texturePreview.texture != null:
			var t = texturePreview.texture.get_class()
			if texturePreview.texture.get_class() != "AnimatedTexture":
				if texturePreview.texture.image != null:
					texturePreview.visible = true
			else:
				texturePreview.visible = true
	
	
	if cats != null:
		if cats.get_child_count() > 0:
			setOptionsVisibility(true)
				
		else:
			setOptionsVisibility(false)
	else:
		setOptionsVisibility(false)
	
	
	if previewNode.get_node_or_null("Camera3D") != null:
		previewWorld.get_node("StaticBody3D").visible = previewWorld.get_node("Camera3D").current
		
		
	if !is_instance_valid(curTree):
		$h/v2/ui/instanceButton.visible = false
		$h/v2/ui/importButton.visible = false
	else:
		$h/v2/ui/instanceButton.visible = true
		$h/v2/ui/importButton.visible = true
		
	
	var keys = threadedQueue.keys()
	
	
	for thread : Thread in threadedQueue.keys():
		var result = threadedQueue[thread]
		if result.is_empty():
			continue
		
		clearEnt()
		pEnt = result[0]
		previewWorld.add_child(result[0])
		threadedQueue.erase(thread)



func gameListGrabFocus():
	gameList.grab_focus()


func saveModeToDisk(modeStr):
	var mode = cur.createGameMode(modeStr)
	var destPath = "res://game_imports/"+cur.gameName+"/modes/"+modeStr+".tscn"
	ENTG.saveNodeAsScene(mode,destPath)
	#breakpoint

func saveMapToDisk(mapStr):
	var map : Node = cur.createMap(mapStr)
	
	var destPath = "res://game_imports/"+cur.gameName+"/maps/"+curEntTxt+".tscn"
	
	
	
		#map.remove_child(i)
	
	#map.remove_child(map.get_node("Entities"))
	#map.remove_child(map.get_node("Surrounding Skybox"))
	#map.remove_child(map.get_node("Geometry"))
	#map.remove_child(map.get_node("Interactables"))

	for i in map.get_children():
		print(i.name)
	
	ENTG.saveNodeAsScene(map,destPath)
	
	emit_signal("diskInstance",load(destPath).instantiate())

func saveFontToDisk(fontStr):
	var destPath = "res://game_imports/"+cur.gameName+"/fonts/"+fontStr+".tscn"
	var font = cur.fetchFont(fontStr)
	ResourceSaver.save(font,destPath)
	

func saveEntitiesToDisk(ents : Array):
	for entStr in ents:
		saveEntityToDisk(entStr)

func saveEntityToDisk(entStr):
	var ent = ENTG.fetchEntity(entStr,{},get_tree(),nameLabel.text,true)
	
	if ent != null:
		if ent.get_parent() != null:
			ent.get_parent().remove_child(ent)
	
	ENTG.updateEntitiesOnDisk(get_tree())
	emit_signal("diskInstance",ent)



func createDirectories(gameName, dirs = ["textures","materials","sounds","sprites","textures/animated","entities","fonts","maps","themes"]):

	
	var directory = DirAccess.open("res://")
	
	
	var split = (destPath+gameName).lstrip("res://")

	if split.length() > 0:
		var subDirs = split.split("/")
		
		for i in subDirs.size():
			var path = "res://"
			for j in i+1:
				directory = directory.open(path)
				path += subDirs[j] + "/"
				createDirIfNotExist(path,directory)
				
			directory =directory.open(path)
	
	
	directory.open(destPath+nameLabel.text)
	
	for i in dirs:
		var initDir = directory.get_current_dir()
		
		var subs = i.split("/")
		
		
		if subs.size() == 1:
			createDirIfNotExist(i,directory)
		else:
			createDirIfNotExist(subs[0],directory)
			createDirIfNotExist(i,directory)
		
		directory.open(initDir)
	

	
	if cur.has_method("getEntityDict"):
		var e = cur.getEntityDict()
		for ent in e:
			if "category" in e[ent]:
				createDirIfNotExist(destPath+nameLabel.text+"/entities/" + e[ent]["category"],directory)
	

	
	var directoriesToCreate : Array = []
	
	

	for dir in directoriesToCreate:
		createDirIfNotExist("entities/"+dir,directory)
	

	
func createDirIfNotExist(path : String,dir : DirAccess):
	var t = dir.get_current_dir()

	#if !dir.dir_exists_absolute(path):
	#	dir.make_dir(path)
	if !dir.dir_exists(path):
		dir.make_dir(path)
		


func waitForDirToExist(path):
	var waitThread = Thread.new()
	
	waitThread.start(Callable(self, "waitForDirToExistTF").bind(path))
	waitThread.wait_to_finish()
	
func waitForDirToExistTF(path):
	var dir = DirAccess.open(path)
	while !dir.dir_exists(path):

		OS.delay_msec(10)
	

func setOptionsVisibility(visible):
	if optionsPanel == null:
		return
		
	for i in optionsPanel.get_children():
		i.visible = visible


func _on_playButton_pressed():
	
	if cur == null:
		return
	
	if !validatePaths():
		return
			
	loaderInit()
	
	var all =  []
	
	if cur.has_method("getAllGameModes"):
		all = cur.getAllGameModes()
	
	var noGameMode = false
	
	if all.is_empty():
		noGameMode = true
		
	if noGameMode:
		$h.get_node("%playButton").text = "No game mode implemented"
		$h.get_node("%playButton").disabled = true
		return
		
	var gamdeModeName = all.keys()[0]

	var mode = createGameMode(gamdeModeName)
	get_tree().get_root().add_child(mode)
	printCaches()
	ENTG.removeEntityCacheForGame(get_tree(),curGameName)
	printCaches()
	ENTG.createEntityCacheForGame(get_tree(),false,nameLabel.text,mode.get_node("loader"),get_tree())
	
	var configName = gameList.get_item_text(gameList.get_selected_items()[0])
	var path = "user://"+configName+".console"
	
	if FileAccess.file_exists(path):
		var cmdStr = FileAccess.get_file_as_string(path)
		var cmds = cmdStr.split("\n")
		
		var console = EGLO.fetchConsole(get_tree())
		for i in cmds:
			if i[0] != "#":
				console.execute(i)
		
	queue_free()
	
	


func createGameMode(gameModeName):
	var loaderFilePath = cur.scene_file_path
	
	var gameModeLoader : Node = load(loaderFilePath).instantiate()
	get_tree().get_root().add_child(gameModeLoader)
	gameModeLoader.params = cur.params
	gameModeLoader.name = "loader"
	gameModeLoader.initialize(cur.params[0],cur.config,cur.params[1])
	
	var modes = cur.getAllGameModes()
	var gameModePath : String = modes[gameModeName]#meta["path"]
#	var newLoader = 
	
	var ret = ENTG.sceneBasedInstance(gameModePath,gameModeLoader.getResourceManager(),gameModeLoader.getEntityCreator())
	gameModeLoader.reparent(ret)
	
	return ret

func _on_close_requested():
	print("close request")
	hide()

func soundFontSet(path):
	if midiPlayer != null:
		midiPlayer.soundfont = path
		
	SETTINGS.setSetting(get_tree(),"soundFont",path)
	
func newPathCreated(creator : Node,created : Node):
	pass
			
func pathRemoved(pathNode):
	var curEntry : Array = gameToHistory[curGameName]
	var targetPAth = pathNode.getPath()
	
	for i in paths.get_child_count():
		if paths.get_child(i) == pathNode:
			curEntry.remove_at(i)
			return

func getFilesInDir(dirPath : String) -> Array[String]:
	var ret : Array[String] = []
	var dir = DirAccess.open(dirPath)
	
	var files = dir.get_files()
	
	for filePath : String in files:
		if filePath.find("_Loader") != -1:
			return [filePath]

	
	return ret

func getAllInCategory(categoryName : String):
	
	if categoryName == "entities":
		return ENTG.getEntitiesCategorized(get_tree(),curGameName)
	elif categoryName == "sounds":
		return cur.getAllSounds()
	elif categoryName == "maps":
		return cur.getAllMapNames()
	elif categoryName == "music":
		return cur.getAllMusic()
	elif categoryName == "fonts":
		return cur.getAllFonts()
	elif categoryName == "textures":
		return cur.getAllTextureEntries()
	elif categoryName == "game modes":
		return cur.getAllGameModes()
	elif categoryName == "themes":
		return cur.getAllThemes()
	elif categoryName == "models":
		return cur.getAllModels() 
	


func _on_loader_options_pressed() -> void:
	ENTG.showObjectInspector(cur)


func _on_credits_button_pressed() -> void:
	if cur == null:
		return
		
	var creds = cur.getCredits()
	var credList: Window = load("res://addons/godotWad/scenes/credits/creditsWindow.tscn").instantiate()
	credList.get_child(0).values = creds
	get_tree().get_root().add_child(credList)
	credList.popup_centered_ratio()
	
func printCaches():
	for i in ENTG.fetchEntityCaches(cur.get_tree(),nameLabel.text.to_lower()):
		if i.is_inside_tree():
			print(i.get_path())
		else:
			print("orphan")
		
		i.print_tree_pretty()
	
	print("---")

func getCategories():
	
	var categories : PackedStringArray = []
	
	if cur.has_method("getExtraCategories"):
		categories = cur.getExtraCategories()
	
	if cur.has_method("getAllFontEntries"):
		categories.insert(0,"fonts")
	
	if cur.has_method("getAllThemes"):
		categories.insert(0,"themes")
	
	if cur.has_method("getAllGameModes"):
		categories.insert(0,"game modes")
	
	if cur.has_method("getAllTextureEntries"):
		categories.insert(0,"textures")
		
	if cur.has_method("getAllModels"):
		categories.insert(0,"models")
	
	if cur.has_method("getAllMapNames"):
		categories.insert(0,"maps")
		
	if cur.has_method("getEntityDict"):
		categories.insert(0,"entities")
		
	
	
	return categories
