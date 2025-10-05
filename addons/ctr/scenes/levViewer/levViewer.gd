extends Control

var spheres = []


@onready var flagsInspector =  %QuadFlags/GridContainer

@onready var curSelected : Variant = null : set = updateInspector
@onready var loader = $ctrLoader
@onready var mapLoader = $ctrLoader.mapLoader
@onready var mapScaleFactor = mapLoader.mapScaleFactor
var curSelectedQuadIdx = null
var outline = null
var curMapPath = ""
var rewriteDict : Dictionary = {}
var rewriteNextFrame = false
var vertexColorEditingAllowed = false
var levFile : FileAccess = null

enum QuadFlags {
	None = 0,
	Invisible = 1 << 0,
	MoonGravity = 1 << 1,
	Reflection = 1 << 2,
	Kickers = 1 << 3,
	OutOfBounds = 1 << 4,
	NeverUsed = 1 << 5,
	TriggerScript = 1 << 6,
	Reverb = 1 << 7,
	KickersToo = 1 << 8,
	MaskGrab = 1 << 9,
	TempleDoor = 1 << 10,
	CollisionTrigger = 1 << 11,
	Ground = 1 << 12,
	Wall = 1 << 13,
	NoCollision = 1 << 14,
	InvisibleTriggers = 1 << 15,
	All = -1
}

@onready var gizmo3d : Node3D = $VBoxContainer2/HSplitContainer/ViewportContainer/SubViewport/Gizmo3D

func _ready() -> void:
	
	%MenuButtonOpen.get_popup().id_pressed.connect(openFileButtonPressed)
	%MenuButtonMap.get_popup().id_pressed.connect(mapMenuButtonPressed)
	%MenuButtonView.get_popup().id_pressed.connect(viewMenuButtonPressed)
	gizmo3d.transform_changed.connect(curTransformChanged)
	gizmo3d.mode = gizmo3d.ToolMode.MOVE# | gizmo3d.ToolMode.SCALE | gizmo3d.ToolMode.ROTATE
	for i in flagsInspector.get_children():
		if i is not CheckBox:
			continue
			
		i.toggled.connect(rewriteQuadNextFrame)
		
	
	for i : int in %QuadColors.get_child_count():
		%QuadColors.get_child(i).color_changed.connect(colorChanged.bind(i,%QuadColors.get_child(i)))
		%QuadColors.get_child(i).picker_created.connect(pickerCreated.bind(%QuadColors.get_child(i)))
		#i.gui_input.connect(quadColorIput.bind(i))
	
	var pop : PopupMenu = %MenuButtonView.get_popup()
	pop.hide_on_state_item_selection = false
	updateInspector(curSelected)
	

func gizmoMoved():
	
	if curSelected == null:
		return
	
	
	setInspectorPosRotValue(Vector3(curSelected.position.x,curSelected.position.y,curSelected.position.z),Vector3(curSelected.rotation.x,curSelected.rotation.y,curSelected.rotation.z))

func setFlagsUI(flags : int):
	%Reverb.button_pressed = (flags & QuadFlags.Reverb != 0)
	%NoCollision.button_pressed = (flags & QuadFlags.NoCollision != 0)
	%IsGround.button_pressed = (flags & QuadFlags.Ground != 0)
	%Invisible.button_pressed = (flags & QuadFlags.Invisible != 0)
	%Wall.button_pressed = (flags & QuadFlags.Wall != 0)
	%CollisionTrigger.button_pressed = (flags & QuadFlags.CollisionTrigger != 0)
	%MaskGrab.button_pressed = (flags & QuadFlags.MaskGrab != 0)
	%FallBoost.button_pressed = (flags & QuadFlags.Kickers != 0)
	%FallBoost2.button_pressed = (flags & QuadFlags.KickersToo != 0)
	%MoonGravity.button_pressed = (flags & QuadFlags.MoonGravity != 0)
	%TriggerScript.button_pressed = (flags & QuadFlags.TriggerScript != 0)
	%OutOfBounds.button_pressed = (flags & QuadFlags.OutOfBounds != 0)
	%Reflection.button_pressed = (flags & QuadFlags.Reflection != 0)
	%InvisibleTrigger.button_pressed = (flags & QuadFlags.InvisibleTriggers != 0)
	%TempleDoorOpen.button_pressed = (flags & QuadFlags.TempleDoor != 0)
	


func rewriteQuad(nop= 0):
	var map = getMap()
	
	if map is WorldEnvironment:
		return
	
	if curSelectedQuadIdx == null:
		return
	
	var t  =map.get_meta_list()
	var baseOffset = 0
	
	if map.has_meta("offsetInIso"):
		baseOffset = map.get_meta("offsetInIso")

	var header =map.get_meta("header")
	var quadBlocksOffset =map.get_meta("quadBlocksOffset")
	var curQuadOffset = baseOffset + quadBlocksOffset + 92*curSelectedQuadIdx
	var flagOffset = curQuadOffset + 18
	var terrainTypeOffset =curQuadOffset + 56
	
	#var flagOffset = curQuadOffset + 18
	#var file : FileAccess
	#if levFile == null:
	#	file = loader.iso.ISOfile
	#else:
#		file = levFile
#	file.seek(flagOffset)

	
	var flags = getFlagValueFromUI()

	
	rewriteDict[quadBlocksOffset + (92 * curSelectedQuadIdx) + 18] = flags & 0xFF               # Low byte
	rewriteDict[quadBlocksOffset + (92 * curSelectedQuadIdx) + 19] = (flags >> 8) & 0xFF        # High byte
	
	
	rewriteDict[quadBlocksOffset + (92 * curSelectedQuadIdx) + 56] = %TerrainType.get_item_index(%TerrainType.selected)# checkpoint
	rewriteDict[quadBlocksOffset + (92 * curSelectedQuadIdx) + 62] = %CheckPointIdx.value # checkpoint
	
	rewriteVertColor(%TL.color,int(%TL.text),0)
	rewriteVertColor(%TM.color,int(%TM.text),0)
	rewriteVertColor(%TR.color,int(%TR.text),0)
	
	rewriteVertColor(%ML.color,int(%ML.text),0)
	rewriteVertColor(%MM.color,int(%MM.text),0)
	rewriteVertColor(%MR.color,int(%MR.text),0)
	
	rewriteVertColor(%BL.color,int(%BL.text),0)
	rewriteVertColor(%BM.color,int(%BM.text),0)
	rewriteVertColor(%BR.color,int(%BR.text),0)
	
	
	#for i in %QuadColors.get_child_count():
	#	var c = %QuadColors.get_child(i)#0 1 6
	#	rewriteVertColor(c.color,int(c.text),i)
	
	var blocksInfo = getMap().get_meta("blocksInfo")
	var blockInfo : Dictionary = blocksInfo[curSelectedQuadIdx]
	
	

	blocksInfo[curSelectedQuadIdx]["terrainFlag"]  = %TerrainType.selected
	blocksInfo[curSelectedQuadIdx]["quadFlags"] = flags
	blocksInfo[curSelectedQuadIdx]["checkpoint id"] = %CheckPointIdx.value


func eraseSpheres():
	for i in spheres:
		if is_instance_valid(i):
			i.queue_free()
			
	spheres = []


func setSpawnsVis(vis : bool):
	for i in get_children():
		if i.has_meta("startSpawn"):
			i.visible = vis

func eraseArrows():
	for i in get_children():
		if i.has_meta("startSpawn"):
				i.queue_free()
		
func clickedOn(object):
	
	var par = object.get_parent()
	if curSelected != null:
		if "setColor" in curSelected:
			curSelected.setColor(Color.WHITE)

	eraseSpheres()
	
	var meta = par.get_meta_list()
	
	
	if par.has_meta("startSpawn"):
		curSelected = par
		if "setColor" in curSelected:
			curSelected.setColor(Color.RED)
		return
	
	if par.has_meta("instance"):
		curSelected = par
		
		
		if is_instance_valid(outline):
			outline.queue_free()
		
		if par is MeshInstance3D:
			outline = EGLO.drawAABBoultine(par)
		else:
			outline = EGLO.drawAABBoultine(par.get_child(0).get_child(0))
		
		outline.reparent(par)
		
		return
	
	if "id" in par:
		
		par.get_parent().selectModeFromId(par.id) #gizmo handles this
		

		return
		
	if is_instance_valid(outline):
		outline.queue_free()
	
	var verts = getVerticesFromArraymesh(par.global_position,par.mesh)
	for v in verts:
		var curShere = EGLO.drawSphere(get_parent(),v,Color.RED,1.0)
		spheres.append(curShere)
	
	
	
	curSelected = object
	
	

func getFlagValueFromUI():
	var flags = 0
	if %Reverb.button_pressed:
		flags |= QuadFlags.Reverb
	if %NoCollision.button_pressed:
		flags |= QuadFlags.NoCollision
	if %IsGround.button_pressed:
		flags |= QuadFlags.Ground
	if %Invisible.button_pressed:
		flags |= QuadFlags.Invisible
	if %Wall.button_pressed:
		flags |= QuadFlags.Wall
	if %MaskGrab.button_pressed:
		flags |= QuadFlags.MaskGrab
	if %TempleDoorOpen.button_pressed:
		flags |= QuadFlags.TempleDoor
	if %FallBoost.button_pressed:
		flags |= QuadFlags.Kickers
	if %FallBoost2.button_pressed:
		flags |= QuadFlags.KickersToo
	if %MoonGravity.button_pressed:
		flags |= QuadFlags.MoonGravity
	if %TriggerScript.button_pressed:
		flags |= QuadFlags.TriggerScript
	if %OutOfBounds.button_pressed:
		flags |= QuadFlags.OutOfBounds
	if %Reflection.button_pressed:
		flags |= QuadFlags.Reflection
	if %InvisibleTrigger.button_pressed:
		flags |= QuadFlags.InvisibleTriggers
	if %CollisionTrigger.button_pressed:
		flags |= QuadFlags.CollisionTrigger
		
	return flags

func getMap():
	
	if %SubViewport.get_child_count() == 4:
		return null
	
	if %SubViewport.get_child(0) is WorldEnvironment:
		return null
	
	return %SubViewport.get_child(0)


func showPositionProperties():
	%PositionContainer.visible = true
	%PositionLabel.visible = true
	%RotationLabel.visible = true
	%RotationContainer.visible = true

func hideQuadProperties():
	%PositionContainer.visible = false
	%RotationContainer.visible = false
	%PositionLabel.visible = false
	%RotationLabel.visible = false
	%QuadFlags.visible = false
	%TerrainTypeContainer.visible =false
	%ColorsContainer.visible = false
	%blockIdx.visible = false
	$%CheckPointContainer.visible = false
	%TextuesContainer.visible = false
	%TextureOffsetContainer.visible = false
	%TextureLowLod.visible = false
	


func hideInstanceProperties():
	%instanceName.visible = false
	%ModelContainer.visible = false
	%PositionContainer.visible = false
	%PositionLabel.visible = false
	%RotationContainer.visible = false
	%RotationLabel.visible = false
	

func showQuadProperties():
	%QuadFlags.visible = true
	%blockIdx.visible = true
	%TerrainTypeContainer.visible =true
	%ColorsContainer.visible = true
	$%CheckPointContainer.visible = true
	%TextureOffsetContainer.visible = true
	%TextuesContainer.visible = true
	%TextureLowLod.visible = true
	
func updateInspector(object : Object):
	

	curSelected = object
	
	
	
	if curSelected == null:
		
		eraseSpheres()
		curSelectedQuadIdx = null
		hideQuadProperties()
		hideInstanceProperties()
		return
	
	
	
	%RayCast3D.clear_exceptions()
	
	#curSelected.print_tree_pretty()
	#if curSelected is StaticBody3D:
		#%RayCast3D.add_exception(curSelected)
	#elif curSelected.get_child(0) is StaticBody3D:
		#%RayCast3D.add_exception(curSelected.get_chlid(0))
	#else:
		#breakpoint
	
	
	if curSelected.has_meta("startSpawn"):
		gizmo3d.clear_selection()
		gizmo3d.select(curSelected)
			
		curSelectedQuadIdx = null
		setInspectorSpawn(curSelected)
		
	elif curSelected.has_meta("instance"):
		
		
		gizmo3d.clear_selection()
		gizmo3d.select(curSelected)
		
		setInspectorInstance(object)
	else:
		gizmo3d.clear_selection()
		setInspectorQuad(object)
  
	 
	await get_tree().physics_frame
	%Inspector.custom_minimum_size = %Inspector.size
	

func setInspectorPosRotValue(pos : Vector3,rot : Vector3):
	
	%X.value = pos.x  / mapLoader.mapScaleFactor
	%Y.value =  pos.y / mapLoader.mapScaleFactor
	%Z.value = pos.z / mapLoader.mapScaleFactor
	
	return
	%RX.value = rot.x / mapLoader.rotScaleFactor
	%RY.value = rot.y/ mapLoader.rotScaleFactor
	%RZ.value = rot.z/ mapLoader.rotScaleFactor
	

func setInspectorSpawn(object : Object):
	hideQuadProperties()
	hideInstanceProperties()
	showPositionProperties()
	
	
	setInspectorPosRotValue(Vector3(object.position.x,object.position.y,object.position.z),Vector3(object.rotation.x,object.rotation.y,object.rotation.z))
	#%X.value = object.position.x / mapLoader.mapScaleFactor
	#%Y.value =  object.position.y/  mapLoader.mapScaleFactor
	#%Z.value = object.position.z/  mapLoader.mapScaleFactor
	#
	#
	#%RX.value = object.rotation.x / mapLoader.mapScaleFactor
	#%RY.value =  object.rotation.y/  mapLoader.mapScaleFactor
	#%RZ.value = object.rotation.z/  mapLoader.mapScaleFactor
	#
	
	await get_tree().physics_frame
	%X.get_line_edit().caret_column= 0

func setInspectorInstance(object : Object):
	hideQuadProperties()
	hideInstanceProperties()
	showPositionProperties()
	
	
	%blockIdx.visible = true
	%instanceName.visible = true
	var instanceArray = getMap().get_meta("instances")
	var instanceIdx = object.get_meta("instance")
	
	
	setInspectorPosRotValue(Vector3(object.position.x,object.position.y,object.position.z),Vector3(object.rotation.x,object.rotation.y,object.rotation.z))
	#%X.value = object.position.x / mapLoader.mapScaleFactor
	#%Y.value =  object.position.y/  mapLoader.mapScaleFactor
	#%Z.value = object.position.z/  mapLoader.mapScaleFactor
	#
#
	#%RX.value = object.rotation.x / mapLoader.mapScaleFactor
	#%RY.value =  object.rotation.y/  mapLoader.mapScaleFactor
	#%RZ.value = object.rotation.z/  mapLoader.mapScaleFactor
	
	var instance : Dictionary = instanceArray[instanceIdx]
	
	%blockIdx.text = "instance %s" % instanceIdx
	%instanceName.text = instance["name"]
	%ModelContainer.visible = true
	var test = object.name
	
	var modelName = object.get_meta("modelName")
	
	var itemId = 0
	
	
	for i in %ModelSelect.get_item_count():
		if %ModelSelect.get_item_text(i) == modelName:
			itemId = i
			break
	%ModelSelect.select(itemId)
	await get_tree().physics_frame
	
	


func setInspectorQuad(object : Object):
	showQuadProperties()
	hideInstanceProperties()
	
	
	var blockIdx = object.get_parent().get_meta("blockIdx")
	var blocksInfo = getMap().get_meta("blocksInfo")
	var blockInfo : Dictionary = blocksInfo[blockIdx]
	var textureOffsets : Array = blockInfo["textureOffsets"]
	var lowLodTextureOffset : int = blockInfo["lowLodTextureOffset"]
	curSelectedQuadIdx = blockIdx 
	
	var flags = blockInfo["quadFlags"]
	var terrain : int = blockInfo["terrainFlag"]
	var indices = blockInfo["indices"]
	var colors= getMap().get_meta("colors")
	
	
	
	setFlagsUI(flags)
	
	%TerrainType.select(terrain)
	%CheckPointIdx.value = blockInfo["checkpoint id"]
	#testing
	%TL.color =  colors[indices[2]]
	%TM.color =   colors[indices[5]]
	%TR.color = colors[indices[0]]
	
	%ML.color =  colors[indices[8]]
	%MM.color =  colors[indices[6]]
	%MR.color =  colors[indices[4]]
	
	%BL.color =  colors[indices[3]]
	%BM.color =  colors[indices[7]]
	%BR.color =  colors[indices[1]]
	

	%TextureOffsetList.clear()
	
	for i in textureOffsets:
		%TextureOffsetList.add_item(EGLO.intToHex(i))
	
	
	%blockIdx.text = "Block Index: %s" % [blockIdx]
	
	var tlArray = getMap().get_meta("QuadTextureLayouts")[blockIdx]
	
	%TL1.texture = ImageTexture.create_from_image(tlArray[0]["image"])
	%TL2.texture = ImageTexture.create_from_image(tlArray[1]["image"])
	%TL3.texture = ImageTexture.create_from_image(tlArray[2]["image"])
	%TL4.texture = ImageTexture.create_from_image(tlArray[3]["image"])
	
	var tlLow = getMap().get_meta("QuadTextureLayoutsLow")[blockIdx]
	%TL_low.texture = ImageTexture.create_from_image(tlLow["image"])
	%LowTexOffsetLabel.text = EGLO.intToHex(lowLodTextureOffset)
func getVerticesFromArraymesh(origin : Vector3,mesh: Mesh) -> Array:
	var vertices = []
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		if arrays.size() == 0:
			continue

		var verts = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			vertices.append(origin+v)
	return vertices


func _on_viewport_container_gui_input(event:  InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		if gizmo3d.hovering:
			return
		
		#var camera = get_viewport().get_camera_3d()
		var camera = %orbCam.cam
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

			# Move and configure the RayCast3D
		#%RayCast3D.global_position = from
		#%RayCast3D.target_position = to - from  # local direction vector
		#%RayCast3D.force_raycast_update()
		
		
		var results = EGLO.multiHitRaycast(%orbCam.get_world_3d(),from,to,5)
		
		if results.is_empty():
			curSelected = null
			return
	
	
		for i in results:
			var body = i.collider
			var shapeIdx = i.shape  # Same as what RayCast3D.get_collider_shape() returns
			
			#var shapeIdx = %RayCast3D.get_collider_shape()

			var owner_id = body.shape_find_owner(shapeIdx) # The owner ID in the collider.
			var shape = body.shape_owner_get_owner(shapeIdx)
			var who = shape.get_parent()
			var who2 = shape.get_parent().get_parent()
			var par = body.get_parent()
			var parPar = get_parent()
			clickedOn(body)
			
			return
		

func openFileButtonPressed(index):
	if index == 0:
		$FileDialog.popup()
	if index == 2:
		saveAsLev()
	if index == 3:
		requestOverwriteISO()
	if index == 4:
		close()

func getIsTexturesVisible():
	var popup = %MenuButtonView.get_popup()
	var isVisible = popup.is_item_checked(0)
	return isVisible

func getIsSpwansVisible():
	var popup = %MenuButtonView.get_popup()
	var isVisible = popup.is_item_checked(1)
	return isVisible

func getIsEntitiesVisible():
	var popup = %MenuButtonView.get_popup()
	var isVisible = popup.is_item_checked(2)
	return isVisible

func getIsTriggersVisible():
	var popup = %MenuButtonView.get_popup()
	var isVisible = popup.is_item_checked(3)
	return isVisible
	
func getIsInvisibleVisible():
	var popup = %MenuButtonView.get_popup()
	var isVisible = popup.is_item_checked(4)
	return isVisible

func viewMenuButtonPressed(index):
	var popup : PopupMenu = %MenuButtonView.get_popup()
	
	if index == 0:
		var checked = !popup.is_item_checked(index)
		popup.set_item_checked(index, checked)
		setTexturesVisible(checked)
	if index == 1:
		var checked = !popup.is_item_checked(index)
		popup.set_item_checked(index, checked)
		setSpawnsVis(checked)
	if index == 2:
		var checked = !popup.is_item_checked(index)
		popup.set_item_checked(index, checked)
		setEntitiesVisible(checked)
	if index == 3:
		var checked = !popup.is_item_checked(index)
		popup.set_item_checked(index, checked)
		setTriggersVisible(checked)
	if index == 4:
		var checked = !popup.is_item_checked(index)
		popup.set_item_checked(index, checked)
		setInvisibleOobjectVis(checked)
		
	
func mapMenuButtonPressed(index):
	if index == 0:
		showMapSelectList()
		
	if index == 1:
		if !curMapPath.contains("bigfile"):
			loadFromLev(curMapPath)
		else:
			loadMapBIN(curMapPath)


func optionsButonPressed(index):
	$OptionsParent

var lock = false
func requestOverwriteISO():
	if lock == true:
		return
	lock = true
	var dialoge
	
	if levFile != null:
		dialoge = EGLO.showOption(self,"Do you wish to overwrite data in %s" %  levFile.get_path(),"Yes","No")
	else:
		dialoge = EGLO.showOption(self,"Do you wish to overwrite data in %s" %  loader.iso.ISOfile.get_path(),"Yes","No")
	dialoge.confirmed.connect(overwriteISO)

func _on_file_dialog_file_selected(path:  String) -> void:
	print("file dialog select")
	
	curMapPath = ""
	if path.get_extension().to_lower() == "bin":
		var err = initializeFromIso(path)
		if err == -1:
			return
		showMapSelectList()
	else:
		loadFromLev(path)
	
	rewriteDict = {}
	

func loadFromLev(path):
	
	curMapPath = path
	
	if getMap() != null:
		getMap().queue_free()
	
	var map = loader.mapLoader.createMapFromLev(path)
	levFile = FileAccess.open(path,FileAccess.READ_WRITE)
	loadMapNode(map,false)
	

func initializeFromIso(path):
	var err = loader.initialize([path],"ctr","ctr")
	if err == -1:
		return err
	
	var iso = loader.iso
	var volumeIdOffset = iso.volumeIdOffset
	iso.ISOfile.seek(volumeIdOffset)
	var volumeText : String= iso.ISOfile.get_buffer(32).get_string_from_ascii()
	%Serial.text = volumeText.rstrip(" ")

func _physics_process(delta: float) -> void:
	
	if rewriteNextFrame:
		rewriteQuad()
		rewriteNextFrame = false
	
	if InputMap.has_action("saveHotkey"):
		if Input.is_action_just_pressed("saveHotkey"):
			requestOverwriteISO()
	

func getModelNameToOffset():
	var map = getMap()
	var modelDict = map.get_meta("modelDict")
	var nameToOffset = {}
	
	for i in modelDict.keys():
		nameToOffset[modelDict[i].name] = i
	
	return nameToOffset

func eraseLeftOvers():
	eraseSpheres()
	eraseArrows()
	
func showMapSelectList():
	

	var mapNames = loader.getAllMapNames()
	var list = %MapList
	
	
	
	for i in list.get_children():
		if i.name != "gizmo":
			i.queue_free()
		
		
	
	for mapName in mapNames:
		var button = Button.new()
		button.pressed.connect(loadMapBIN.bind(mapName))
		button.text = mapName
		list.add_child(button)
	
	var mapListContainer = %MapListContainer
	
	%MapListContainer.visible = true
	mapListContainer.get_node("Panel").custom_minimum_size.y = list.size.y
	mapListContainer.get_node("Panel2").custom_minimum_size.y = list.size.y
	
func loadMapBIN(mapPath):
	DisplayServer.window_set_title(mapPath)
	var keepPos := false
	if curMapPath == mapPath:
		keepPos = true
	
	curMapPath = mapPath
	
	if getMap() != null:
		getMap().queue_free()
	
	restoreTextureDict = {}
	var map =loader.createMap(mapPath,{"debug":true})
	loadMapNode(map,keepPos)
	setTexturesVisible(getIsTexturesVisible())
	setEntitiesVisible(getIsEntitiesVisible())
	setSpawnsVis(getIsSpwansVisible())
	setTriggersVisible(getIsTriggersVisible())
	setInvisibleOobjectVis(getIsInvisibleVisible())
	
	
func loadMapNode(map : Node,keepPos : bool):
	
	%MapListContainer.visible = false
	
	
	
	eraseLeftOvers()
	
	
	rewriteDict = {}
	
	%MenuButtonMap.disabled = false
	var  m= map.get_meta_list()
	var origin : Vector3  = map.get_meta("center")
	var startingPositions = map.get_meta("startPos")
	var startingRotations = map.get_meta("startRot")
	
	if !keepPos:
		%orbCam.position = startingPositions[0]
		%orbCam.rotation = startingRotations[0]
		%orbCam.position -=%orbCam.basis.z * 2
	
	
	for i in startingPositions.size():
		var arrow = load("res://addons/gameAssetImporter/scenes/arrow/arrow.tscn").instantiate()
		arrow.scale = Vector3.ONE *2
		arrow.position = startingPositions[i]
		arrow.rotation = startingRotations[i]
		arrow.message = str(i)
		arrow.generateCollisionSimple()
		arrow.set_meta("startSpawn",i)
		add_child(arrow)
		
	
		
	#%orbCam.cam.position.y += 10
	%SubViewport.add_child(map)
	%SubViewport.move_child(map,0)
	
	var colors = map.get_meta("colors")
	initColorPalette(colors)
	
	var modelNameToOffset= getModelNameToOffset()
	
	%ModelSelect.clear()
	
	
	for i in modelNameToOffset:
		%ModelSelect.add_item(i)
		%ModelSelect.set_item_metadata(%ModelSelect.item_count-1,modelNameToOffset[i])
	
	
	
func initColorPalette(colors : PackedColorArray):
	var levelPalette = %levelPalette
	for color in colors:
		var cRect := ColorRect.new()
		cRect.color = color
		cRect.custom_minimum_size = Vector2(4,4)
		cRect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cRect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		levelPalette.add_child(cRect)
	

func saveAsLev():
	$SaveLevDialog.popup_centered()
	
	
func patchLev(data : PackedByteArray):
	
	for offset in rewriteDict:
		var t = data[offset]
		data[offset] = rewriteDict[offset]
	
	return data

func patchISO(data : PackedByteArray):
	
	for offset in rewriteDict:
		var _a = data[offset]
		
		var _x = rewriteDict[offset]

		#if data[offset] != rewriteDict[offset]:
		#	breakpoint
		data[offset] = rewriteDict[offset]
	
	return data
	
	

func _on_save_lev_dialog_file_selected(path:  String) -> void:
	var map = getMap()
	var baseOffset = map.get_meta("offsetInIso")
	var size = map.get_meta("mapSizeInBytes")
	var header =map.get_meta("header")
	var mapColorPalette = map.get_meta("colors")
	var file : ISOFileWrapper = loader.iso.ISOfile
	file.seek(baseOffset)
	
	var bytes = patchLev(file.get_buffer(size))
	
	
	var outFile := FileAccess.open(path,FileAccess.WRITE)
	outFile.store_buffer(bytes)
	outFile.close()



func overwriteISO():
	var file = null
	var baseOffset = 0
	
	var map = getMap()
	
	if levFile == null:
		file = loader.iso.ISOfile
		baseOffset = map.get_meta("offsetInIso")
	else:
		file = levFile
	
	#var tringToOpenFile = file.get_path()

	
	file.seek(baseOffset)
	var size = 0
	if levFile != null:
		size = file.get_length()
	else:
		size = map.get_meta("mapSizeInBytes")
	var levData = file.get_buffer(size)
	file.seek(baseOffset)
	patchISO(levData)
	
	file.store_buffer(levData)
	EGLO.showMessage(self,"Done")
	lock = false
	


func _on_terrain_type_item_selected(index:  int) -> void:
	rewriteQuadNextFrame()
	
	
func quadColorIput(ev :InputEvent  ,node : ColorPickerButton):
	if ev is not InputEventMouseButton:
		return


func pickerCreated(node):
	pass

func colorChanged(color,vertIdx,caller : ColorPickerButton):
	caller.color= color
	rewriteQuadNextFrame()



func rewriteSpawnPos():
	var spawnIdx = curSelected.get_meta("startSpawn")
	#var pos = curSelected.position
	var map = getMap()
	var baseOffset = map.get_meta("offsetInIso")
	
	var startSpawnsOffset = 112
	
	var targetOffset = startSpawnsOffset + (spawnIdx*12)#vectors components are 2bytes pos(6) + rot(6)
	
	
	#x
	var buffer = StreamPeerBuffer.new()
	var pos = int(snapped(%X.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	var bytes = buffer.get_data_array()
	#var origBytes = getOrignalData(baseOffset+targetOffset,2)
	rewriteDict[targetOffset] = bytes[0]
	rewriteDict[targetOffset+1] = bytes[1]
	
	#y
	buffer = StreamPeerBuffer.new()
	pos = int(snapped(%Y.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	bytes = buffer.get_data_array()

	rewriteDict[targetOffset+2] = bytes[0]
	rewriteDict[targetOffset+3] = bytes[1]
	
	#z
	buffer = StreamPeerBuffer.new()
	pos = int(snapped(%Z.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	bytes = buffer.get_data_array()
	
	
	
	rewriteDict[targetOffset+4] = bytes[0]
	rewriteDict[targetOffset+5] = bytes[1]
	



func rewriteInstancePos():
	var instanceArray = getMap().get_meta("instances")
	var instanceIdx = curSelected.get_meta("instance")
	var instance : Dictionary = instanceArray[instanceIdx]
	var header = getMap().get_meta("header")
	var instancesOffset = header["instancesOffset"]+4
	var offset = instancesOffset +(64*instanceIdx)+ 48 
	var baseOffset : int = 0
	
	if getMap().has_meta("offsetInIso"):
		baseOffset = getMap().get_meta("offsetInIso")
	
	var buffer = StreamPeerBuffer.new()
	var pos = int(snapped(%X.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	var bytes = buffer.get_data_array()
	#var origBytes = getOrignalData(offset,2)
	
	
	rewriteDict[offset] = bytes[0]
	rewriteDict[offset+1] = bytes[1]
	
	buffer = StreamPeerBuffer.new()
	var test = %Y.value
	pos = int(snapped(%Y.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	bytes = buffer.get_data_array()
	var origBytes = getOrignalData(baseOffset+offset+2,2)
	rewriteDict[offset+2] = bytes[0]
	rewriteDict[offset+3] = bytes[1]
	#
	#z
	buffer = StreamPeerBuffer.new()
	pos = int(snapped(%Z.value,1))
	buffer.put_16(pos)
	buffer.seek(0)   
	bytes = buffer.get_data_array()
	
	rewriteDict[offset+4] = bytes[0]
	rewriteDict[offset+5] = bytes[1]
	
func rewriteInstanceName():
	var instanceArray = getMap().get_meta("instances")
	var instanceIdx = curSelected.get_meta("instance")
	var instance : Dictionary = instanceArray[instanceIdx]
	var header = getMap().get_meta("header")
	var instancesOffset = header["instancesOffset"]+4
	var offset = instancesOffset +(64*instanceIdx)
	var baseOffset = getMap().get_meta("offsetInIso")
	var origBytes = getOrignalData(offset,16)
	 
	var destStr = %instanceName.text.to_ascii_buffer()
	
	for i in 16:
		rewriteDict[offset+i] = 0
	
	
	
	for i in destStr.size():
		rewriteDict[offset+i] = destStr[i]
	
	
	
	
	
func rewriteVertColor(color,vertIdx,qIdx):
	#if !vertexColorEditingAllowed:
	#	return
	var map = getMap()
	var colors = map.get_meta("colors")
	var blocksInfo = map.get_meta("blocksInfo")
	var blockInfo : Dictionary = blocksInfo[curSelectedQuadIdx]
	var origColor = colors[blockInfo["indices"][vertIdx]]
	var vertsOffset =  map.get_meta("vertsOffset")
	var offset = vertsOffset + (blockInfo["indices"][vertIdx] * 16) + 8
	var baseOffset = 0
	
	if map.has_meta("offsetInIso"):
		baseOffset = map.get_meta("offsetInIso")
	
	
	#if color != origColor:
		#breakpoint

	var packedColor2 = loader.imageLoader.color_to_abgr8888_bytes(color)
	

	var spb = StreamPeerBuffer.new()
	spb.data_array = packedColor2
	packedColor2[3] = 0#this should mean is transparent but game treats it opaque for some reason
	spb.seek(0)
	var value = spb.get_32()  # Reads 4 bytes as a signed 32-bit integer
	
	var color2 = loader.mapLoader.getColor(value)
	
	var file  = null
	
	if levFile == null:
		var t =  loader.iso.ISOfile
		file= loader.iso.ISOfile
	else:
		file = levFile
	
	file.seek(offset+baseOffset)
	var size : int
	
	if map.has_meta("mapSizeInBytes"):
		size = map.get_meta("mapSizeInBytes")
	else:
		var filePath = levFile.get_path()
		size = levFile.get_size(filePath)
	
	var levData = file.get_buffer(size)
	
	
	var pba = [levData[offset],levData[offset+1],levData[offset+2],levData[offset+3]]
	
	rewriteDict[offset] = packedColor2[0]
	rewriteDict[offset+1] = packedColor2[1]
	rewriteDict[offset+2]= packedColor2[2]
	rewriteDict[offset+3]= packedColor2[3]
	#rewriteDict[offset+] = 0
	

func rewriteQuadNextFrame(nop = null):
	rewriteNextFrame = true

func getOrignalData(offset,size):
	var map = getMap()
	var baseOffset = 0
	
	if map.has_meta("offsetInIso"):
		baseOffset = map.get_meta("offsetInIso")
	
	if levFile != null:
		levFile.seek(baseOffset+offset)
		return levFile.get_buffer(size)
		
	loader.iso.ISOfile.seek(baseOffset+offset)
	return loader.iso.ISOfile.get_buffer(size)

func _on_check_point_idx_value_changed(value:  float) -> void:
	rewriteQuadNextFrame()




func _on_menu_button_options_pressed() -> void:
	$OptionsParent.popup_centered()
	pass # Replace with function body.


func _on_options_parent_close_requested() -> void:
	$OptionsParent.visible = false
	pass # Replace with function body.


func _on_vertex_color_allow_toggled(toggled_on:  bool) -> void:
	vertexColorEditingAllowed = toggled_on
	pass # Replace with function body.

func reverseCheckpointOrder():


	var map =  getMap()
	
	if map == null:
		return
	var quadBlocksOffset =map.get_meta("quadBlocksOffset")
	var blocksInfo = map.get_meta("blocksInfo")
	
	var maxCheckPoint = 0
	
	for i in blocksInfo:
		var curId = i["checkpoint id"]
		if curId != 255 and curId > maxCheckPoint:
			maxCheckPoint = curId
	
	for i in blocksInfo.size():
		
		var curId = blocksInfo[i]["checkpoint id"]
		if curId == 255:
			continue
		#i["checkpoint id"] = maxCheckPoint - curId
		blocksInfo[i]["checkpoint id"]= maxCheckPoint - curId
		rewriteDict[quadBlocksOffset + (92 * i) + 62] = maxCheckPoint - curId
	
func close():
	if getMap() == null:
		return
	%MenuButtonMap.disabled = true
	getMap().queue_free()
	loader.iso.close()
	levFile = null
	eraseLeftOvers()
	rewriteDict = {}
	curSelected = null


func _on_button_reverse_checkpoints_pressed() -> void:
	
	if getMap() == null:
		return
	
	reverseCheckpointOrder()
	%OptionsParent.visible = false


func _on_x_value_changed(value:  float) -> void:
	curSelected.position.x = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()
	


func _on_y_value_changed(value: float) -> void:
	curSelected.position.y = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()
	


func _on_z_value_changed(value: float) -> void:
	curSelected.position.z = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()
		
	
	


func _on_instance_name_text_submitted(new_text:  String) -> void:
	rewriteInstanceName()


func rewriteInstanceModelOffset():
	var instanceArray = getMap().get_meta("instances")
	var instanceIdx = curSelected.get_meta("instance")
	var instance : Dictionary = instanceArray[instanceIdx]
	var header = getMap().get_meta("header")
	var instancesOffset = header["instancesOffset"]+4
	var offset = instancesOffset +(64*instanceIdx)
	var baseOffset = getMap().get_meta("offsetInIso")
	var origBytes = getOrignalData(offset,16)
	 
	var destStr = %instanceName.text.to_ascii_buffer()
	
	for i in 16:
		rewriteDict[offset+i] = 0
	
	
	
	for i in destStr.size():
		rewriteDict[offset+i] = destStr[i]
		


func _on_model_select_item_selected(index: int) -> void:
	var map = getMap()
	var instanceArray = map.get_meta("instances")
	var header =map.get_meta("header")
	var instancesOffset = header["instancesOffset"]+4
	var instanceIdx = curSelected.get_meta("instance")
	var modelDict =  map.get_meta("modelDict")
	var modelOffset = %ModelSelect.get_item_metadata(index)
	var pos = curSelected.position
	var iName = curSelected.name
	var baseOffset = getMap().get_meta("offsetInIso")
	
	curSelected.queue_free()
	curSelected = mapLoader.createDebugInstance(iName ,pos,curSelected.rotation,modelDict,modelOffset,instanceIdx)
	map.add_child(curSelected)
	
	var offset = instancesOffset +(64*instanceIdx) + 16
	
	var buffer = StreamPeerBuffer.new()
	buffer.put_u32(modelOffset)
	buffer.seek(0)
	var bytes = buffer.get_data_array()
	
	var origBytes = getOrignalData(offset,4)
	
	rewriteDict[offset] = bytes[0]
	rewriteDict[offset+1] = bytes[1]
	rewriteDict[offset+2] = bytes[2]
	rewriteDict[offset+3] = bytes[3]
	
	#var spb = StreamPeerBuffer.new()
	#spb.data_array = packedColor2
	#packedColor2[3] = 0#this should mean is transparent but game treats it opaque for some reason
	#spb.seek(0)
	#var value = spb.get_32()  # Reads 4 bytes as a signed 32-bit integer
	


func _on_rx_value_changed(value: float) -> void:
	curSelected.rotation.x = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()


func _on_ry_value_changed(value: float) -> void:
	curSelected.rotation.y = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()



func _on_rz_value_changed(value: float) -> void:
	curSelected.rotation.z = value*mapScaleFactor
	
	if curSelected.has_meta("startSpawn"):
		rewriteSpawnPos()
	elif curSelected.has_meta("instance"):
		rewriteInstancePos()


func _on_serial_rewrite_button_pressed() -> void:
	var newSerial : PackedByteArray = %Serial.text.to_ascii_buffer()
	var iso = loader.iso
	var volumeIdOffset = iso.volumeIdOffset
	
	newSerial.resize(32)
	
	iso.ISOfile.seek(volumeIdOffset)
	iso.ISOfile.store_buffer(newSerial)
	
func curTransformChanged(mode, value : Vector3):
	if curSelected == null:
		return
	if mode == 2:
		%X.value = curSelected.position.x  / mapLoader.mapScaleFactor
		%Y.value =   curSelected.position.y / mapLoader.mapScaleFactor
		%Z.value =  curSelected.position.z / mapLoader.mapScaleFactor


var restoreTextureDict = {}

func setEntitiesVisible(vis):
	var map = getMap()
	
	if map == null:
		return
	
	map.get_node("entities").visible = vis

func setTexturesVisible(vis):
	var map = getMap()
	
	if map == null:
		return
	
	
	if !map.has_meta("matCache"):
		return
	
	var matCache : Dictionary = map.get_meta("matCache")
	
	if !vis:
		for image in matCache.keys():
			var mat = matCache[image]
			restoreTextureDict[image] = mat.albedo_texture
			mat.albedo_texture = null
	else:
		for image in matCache.keys():
			
			if !restoreTextureDict.has(image):
				continue
			var mat = matCache[image]
			mat.albedo_texture = restoreTextureDict[image]
			

func setTriggersVisible(vis):
	var map = getMap()
	
	if map == null:
		return
	
	var blocksInfo = getMap().get_meta("blocksInfo")
	
	for i in map.get_node("geometry").get_children():
		var blockIdx = i.get_meta("blockIdx")
		
		var blockInfo = blocksInfo[blockIdx]  
		var flags = blockInfo["quadFlags"]
		
		if (flags & QuadFlags.InvisibleTriggers != 0):
			i.visible = vis
		
func setInvisibleOobjectVis(vis):
	var map = getMap()
	
	if map == null:
		return
	
	var blocksInfo = getMap().get_meta("blocksInfo")
	
	for i in map.get_node("geometry").get_children():
		var blockIdx = i.get_meta("blockIdx")
		
		var blockInfo = blocksInfo[blockIdx]  
		var flags = blockInfo["quadFlags"]
		
		if (flags & QuadFlags.Invisible != 0):
			i.visible = vis
		


func _on_tl_1_pressed() -> void:
	var win : Window = load("res://addons/ctr/scenes/textureLayoutUI/TextureLayoutWindow.tscn").instantiate()
	
	var blockIdx = curSelected.get_parent().get_meta("blockIdx")
	var textureLayouts = getMap().get_meta("QuadTextureLayouts")[blockIdx]
	add_child(win)
	var colors = loader.imageLoader.readPalleteFromTextureLayout( textureLayouts[0])
	
	
	win.getTextureLayoutUI().colors = colors
	win.setTextureLayout(textureLayouts[0])
	
	win.popup_centered()
func showTLui(tl):
	var win : Window = load("res://addons/ctr/scenes/textureLayoutUI/TextureLayoutWindow.tscn").instantiate()
	add_child(win)
	var colors = loader.imageLoader.readPalleteFromTextureLayout( tl)
	win.getTextureLayoutUI().colors = colors
	win.setTextureLayout(tl)
	win.popup_centered()

#todo compress these to a singal function


func _on_tl_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tl = getMap().get_meta("QuadTextureLayouts")[curSelectedQuadIdx][0]
			showTLui(tl)
			


func _on_tl_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tl = getMap().get_meta("QuadTextureLayouts")[curSelectedQuadIdx][1]
			showTLui(tl)


func _on_tl_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tl = getMap().get_meta("QuadTextureLayouts")[curSelectedQuadIdx][2]
			showTLui(tl)


func _on_tl_4_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var tl = getMap().get_meta("QuadTextureLayouts")[curSelectedQuadIdx][3]
			showTLui(tl)


func _on_tl_low_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#var tl = getMap().get_meta("QuadTextureLayouts")[curSelectedQuadIdx][3]
			var tlLow = getMap().get_meta("QuadTextureLayoutsLow")[curSelectedQuadIdx]
			showTLui(tlLow)


func _on_button_pressed() -> void:
	var map = getMap()
	
	if map == null:
		return
		
	var textureLayouts : Dictionary[String,Dictionary]= map.get_meta("iconTextureLayouts")
	var window : Window = load("res://addons/ctr/scenes/textureLayoutUI/MultiTextureLayoutWindow.tscn").instantiate()
	
	$/root.add_child(window)
	
	for i in textureLayouts.values():
		loader.imageLoader.textureLayoutToImage(i)
		
	
	window.tlList = textureLayouts
	window.title = "Icons"
	window.popup_centered()
