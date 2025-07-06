extends Control

var spheres = []


@onready var flagsInspector =  $VBoxContainer2/HSplitContainer/MarginContainer/Inspector/FoldableContainer/GridContainer

var curSelectedBlock = -1

var rewriteDict : Dictionary = {}

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
	Unknown = 1 << 11,
	Ground = 1 << 12,
	Wall = 1 << 13,
	NoCollision = 1 << 14,
	InvisibleTriggers = 1 << 15,
	All = -1
}

func _ready() -> void:
	
	%MenuButton.get_popup().id_pressed.connect(openFileButtonPressed)
	for i in flagsInspector.get_children():
		if i is not CheckBox:
			continue
			
		i.toggled.connect(qaudFlagsChanged)
		
		
	pass
	

func qaudFlagsChanged(value : int):
	var map = getMap()
	var t  =map.get_meta_list()
	var baseOffset = map.get_meta("offsetInIso")
	var header =map.get_meta("header")
	var quadBlocksOffset =map.get_meta("quadBlocksOffset")
	var curQuadOffset = baseOffset + quadBlocksOffset + 92*curSelectedBlock
	var flagOffset = curQuadOffset + 18
	#var flagOffset = curQuadOffset + 18
	
	var file : ISOFileWrapper = $ctrLoader.iso.ISOfile
	file.seek(flagOffset)
	print("orig pos:",file.get_position() - baseOffset)
	var t0 = file.get_16()
	
	#rewriteDict[quadBlocksOffset + (92*curSelectedBlock) +18 ] = 0
	rewriteDict[quadBlocksOffset + (92*curSelectedBlock) +18 ] = 0
	rewriteDict[quadBlocksOffset + (92*curSelectedBlock) +19 ] = 0
	
	

func clickedOn(object):
	
	var par = object.get_parent()
	
	var verts = getVerticesFromArraymesh(par.global_position,par.mesh)

	
	for i in spheres:
		if is_instance_valid(i):
			i.queue_free()
	
	
	
	for v in verts:
		spheres.append(EGLO.drawSphere(get_parent(),v,Color.RED,1.0))
	
	updateInspector(object)
	

func getMap():
	return %SubViewport.get_child(0)

func updateInspector(object : Object):
	
	var meta = object.get_parent().get_meta_list()
	var blockIdx = object.get_parent().get_meta("blockIdx")
	var blocksInfo = getMap().get_meta("blocksInfo")
	curSelectedBlock = blockIdx 
	var flags = blocksInfo[blockIdx]["quadFlags"]
	

	%Reverb.button_pressed =  (flags & QuadFlags.Reverb != 0)
	%NoCollision.button_pressed = (flags & QuadFlags.NoCollision != 0)
	%IsGround.button_pressed = (flags & QuadFlags.Ground != 0)
	%Invisible.button_pressed = (flags & QuadFlags.Invisible != 0)
	%Wall.button_pressed = (flags & QuadFlags.Wall != 0)
	%MaskGrab.button_pressed = (flags & QuadFlags.MaskGrab!= 0)
	%TempleDoorOpen.button_pressed = (flags & QuadFlags.TempleDoor != 0)
	%FallBoost.button_pressed = (flags & QuadFlags.Kickers != 0)
	%MoonGravity.button_pressed = (flags & QuadFlags.MoonGravity != 0)
	
	%blockIdx.text = "Block Index: %s" % [blockIdx]
 	
	
	
	
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
		
		#var camera = get_viewport().get_camera_3d()
		var camera = %orbCam.cam
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

			# Move and configure the RayCast3D
		%RayCast3D.global_position = from
		%RayCast3D.target_position = to - from  # local direction vector
		%RayCast3D.force_raycast_update()

			
			
		var body : Object= %RayCast3D.get_collider()
			
		if body == null:
			return
			
		
		
		var shapeIdx = %RayCast3D.get_collider_shape()

		var owner_id = body.shape_find_owner(shapeIdx) # The owner ID in the collider.
		var shape = body.shape_owner_get_owner(shapeIdx)
			
			
		clickedOn(body)
		

func openFileButtonPressed(index):
	if index == 0:
		$FileDialog.popup()
	if index == 2:
		saveAsLev()
	if index == 3:
		overwriteISO()
		


func _on_file_dialog_file_selected(path:  String) -> void:
	$ctrLoader.initialize([path],"ctr","ctr")
	var mapNames = $ctrLoader.getAllMapNames()
	var list = %MapList
	
	for mapName in mapNames:
		var button = Button.new()
		button.pressed.connect(mapButtonPressed.bind(mapName))
		button.text = mapName
		list.add_child(button)
		
		
	
	$VBoxContainer.visible = true
	$VBoxContainer/ScrollContainer/Panel2.custom_minimum_size.y = list.size.y
	$VBoxContainer/ScrollContainer/Panel.custom_minimum_size.y = list.size.y
		

func mapButtonPressed(mapPath):
	$VBoxContainer.visible = false
	%SubViewport.get_child(0).queue_free()
	var map = $ctrLoader.createMap(mapPath)
	%SubViewport.add_child(map)
	%SubViewport.move_child(map,0)
	

func saveAsLev():
	$SaveLevDialog.popup_centered()
	
	
func patchLev(data : PackedByteArray):
	
	for offset in rewriteDict:
		var t = data[offset]
		data[offset] = rewriteDict[offset]
	
	return data

func patchISO(data : PackedByteArray):
	
	for offset in rewriteDict:
		print("now pos:",offset)
		var t = data[offset]
		data[offset] = rewriteDict[offset]
	
	return data
	
	

func _on_save_lev_dialog_file_selected(path:  String) -> void:
	var map = getMap()
	var baseOffset = map.get_meta("offsetInIso")
	var size = map.get_meta("mapSizeInBytes")
	var header =map.get_meta("header")
	
	var file : FileAccess = $ctrLoader.iso.ISOfile
	file.seek(baseOffset)
	
	var bytes = patchLev(file.get_buffer(size))
	
	
	var outFile := FileAccess.open(path,FileAccess.WRITE)
	outFile.store_buffer(bytes)
	outFile.close()



func overwriteISO():
	var file : FileAccess = $ctrLoader.iso.ISOfile
	
	file.close()
	var tringToOpenFile = file.get_path()
	var fileWriteMode = FileAccess.open(tringToOpenFile,FileAccess.READ_WRITE)
	if FileAccess.get_open_error() != 0:
		var popup := AcceptDialog.new()
		popup.dialog_text = "Failed to open file for writing\nError: " + str(FileAccess.get_open_error())
		add_child(popup)
		popup.popup_centered()
	
	var map = getMap()
	var baseOffset = map.get_meta("offsetInIso")
	fileWriteMode.seek(baseOffset)
	var size = map.get_meta("mapSizeInBytes")
	var levData = fileWriteMode.get_buffer(size)
	fileWriteMode.seek(baseOffset)
	patchISO(levData)
	
	fileWriteMode.store_buffer(levData)
	
	fileWriteMode.close()
	$ctrLoader.iso.ISOfile =fileWriteMode
	
	
