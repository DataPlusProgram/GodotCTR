extends Node

var modelLoaders : Dictionary[String,PackedScene] = {
	"ctr" : preload("res://addons/ctr/CTR_Loader.tscn")
}

var parsingFunctions  : Dictionary[String,Node]= {
	
}

var curModel = null
var rewriteDict = {}
var texturesToUpdate = {}
@onready var animsList = %AnimsList


func _physics_process(delta: float) -> void:
	var anims : AnimationPlayer = getAnimPlayer(curModel)
	
	if anims == null:
		return
	anims.deterministic = true
	anims.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	#print(anims.current_animation, ":",anims.is_playing())
	#if anims.is_playing():
	#	print(anims.current_animation_position)
	

func _ready() -> void:

	var popupMenu : PopupMenu = %menuButtonOpen.get_popup()
	popupMenu.id_pressed.connect(_on_menu_button_open_pressed)
	popupMenu.id_focused.connect(_on_menu_button_focus)
	for extStr in modelLoaders:
		var entry = modelLoaders[extStr]
		var inst = modelLoaders[extStr].instantiate()
		add_child(inst)
		parsingFunctions[extStr] = inst

	
	var args = OS.get_cmdline_args()
	if args.is_empty():
		return
	
	var filePath = args[0].replace("\\","/")
	if !FileAccess.file_exists(filePath):
		print("File not found:",args)
		return
	
	
	
	var loader = parsingFunctions["ctr"]
	var theModel = loader.createModel(filePath)
	
	await get_parent().ready
	setModel(theModel)

	


func _on_menu_button_open_pressed(id : int) -> void:
	if id == 0:
		$"../FileDialog".popup()
	
	if id == 1: 
		$"../FileDialogISO".popup()
		
	if id == 2:
		$"../FileDialogBIG".popup()

func _on_menu_button_focus(id : int) -> void:
	breakpoint
	
func animFinished(anim):
	pass

func setModel(model):
	%AnimsList.clear()
	get_parent().subViewport.add_child(model)
	
	if curModel != null:
		curModel.queue_free()
	
	curModel = model
	
	if curModel.get_node_or_null("wheels") !=  null:
		curModel.get_node_or_null("wheels").visible = %ShowWheelsCheckbox.button_pressed
	
	var anims : AnimationPlayer = getAnimPlayer(curModel)
	
		
	if anims != null:
		%noAnimLabel.visible = false
		$"../HBoxContainer/VSplitContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer".visible = true
		anims.animation_finished.connect(animFinished)
		populateAnims(anims)
	else:
		%noAnimLabel.visible = true
		$"../HBoxContainer/VSplitContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer".visible = false
	
	if model.has_meta("textureLayouts"):
		var textureLayouts : Array[Dictionary] = model.get_meta("textureLayouts")
		
		populateTextureLayout(textureLayouts)
	
	
	
	
func populateTextureLayout(textureLayouts : Array[Dictionary]):
	
	for i in %TextureLayouts.get_children():
		i.queue_free()
	
	
	var loader = parsingFunctions["ctr"]
	
	for tl in textureLayouts:
	
		var tlUI = load("res://addons/ctr/scenes/textureLayoutUI/textureLayoutUI.tscn").instantiate()
		tlUI.textureLayout = tl

		var fold := FoldableContainer.new()
		
		fold.title = "Texture layout %s" % [textureLayouts.find(tl)]
		fold.add_child(tlUI)
		
		var image : Image= null
		
		if tl.has("image"):
			image = tl["image"]
			var colors = loader.imageLoader.readPalleteFromTextureLayout(tl)
			
			tlUI.colors = colors
			tlUI.get_node("%Texture").texture = ImageTexture.create_from_image(image)
			tlUI.vrmChagnedSignal.connect(textureLayoutVRMchanged.bind(tlUI))
			tlUI.paletteChangedSignal.connect(textureLayoutPaletteChanged.bind(tlUI))
		
		tlUI.valueChangedSignal.connect(textureLayoutValueChanged.bind(tlUI))
		
		var path : String = loader.imageLoader.getVrmPathFromRect(tl["rect"])
		tlUI.get_node("%VRMpath").text = path
		%TextureLayouts.add_child(fold)
	


func textureLayoutValueChanged(tlUI : Node):
	var tl : Dictionary = tlUI.textureLayout
	var offset = tl["offset"]
	var pageX =  int(tlUI.get_node("%pagelX").value)
	var pageY =  int(tlUI.get_node("%pagelY").value)
	var palX = int(tlUI.get_node("%palX").value)
	var palY = int(tlUI.get_node("%palY").value)


	var buf = (pageY & 1) << 4 | (pageX & 0xF)
	var buffBytes := EGLO.get16AsBytes(buf)
	
	var bufPal = ((palY & 0x3FF) << 6) | (palX & 0x3F)
	var bytesPal = EGLO.get16AsBytes(bufPal)

	rewriteDict[offset+0] =  tlUI.get_node("%uv1x").value
	rewriteDict[offset+1] =  tlUI.get_node("%uv1y").value
	rewriteDict[offset+4] =  tlUI.get_node("%uv2x").value
	rewriteDict[offset+5] =  tlUI.get_node("%uv2y").value
	rewriteDict[offset+6] =  buffBytes[0]
	rewriteDict[offset+7] =  buffBytes[1]
	rewriteDict[offset+8] =  tlUI.get_node("%uv3x").value
	rewriteDict[offset+9] =  tlUI.get_node("%uv3y").value
	rewriteDict[offset+10] = tlUI.get_node("%uv4x").value
	rewriteDict[offset+11] = tlUI.get_node("%uv4y").value
	
	
	

	
	
	
func textureLayoutVRMchanged(tlUI: Node):
	var tl : Dictionary = tlUI.textureLayout
	texturesToUpdate[tlUI] = true
	

func textureLayoutPaletteChanged(tlUI : Node):
	var tl : Dictionary = tlUI.textureLayout
	texturesToUpdate[tlUI] = true
	return
	#var tl : Dictionary = tlUI.textureLayout
	#var colors : PackedColorArray = tlUI.getColors()
	#
	#var loader = parsingFunctions["ctr"]
	#var imageLoader = loader.imageLoader
	#
	#var paletteBytes: PackedByteArray = imageLoader.colorArrayToPaletteBytes(colors)
	#var path : String= tlUI.get_node("%VRMpath").text
	#
	#var palettePosA = tl["pallete"]
	#var tlVrmRect = tl["rect"]
	#
	#var palStartOffset =palettePosA.y*2048 + palettePosA.x*32
	#var isoFileF = loader.iso.ISOfile.file
	#
	#
	#if isoFileF == null:#CTR File
		#var f = FileAccess.open(path,FileAccess.READ_WRITE)
		#
		#if f == null:
			#EGLO.showMessage(self,"Path not found: %s"%path)
			#return
		#
		#imageLoader.writePaletteToVRM(f,palettePosA,paletteBytes)


func _on_file_dialog_file_selected(path: String) -> void:
	
	rewriteDict = {}
	texturesToUpdate = {}
	
	var ext = path.get_extension()
	
	%ListPanel.visible = false
	setModel(parsingFunctions[ext].createModel(path,{"debug":true}))
	

func getAnimPlayer(node:Node) -> AnimationPlayer:
	if node == null:
		return
	
	for i : Node in node.get_children():
		if i is AnimationPlayer:
			return i
			
	return null

func populateAnims(anims : AnimationPlayer):
	for anim in anims.get_animation_list():
		animsList.add_item(anim)
	


func _on_play_button_pressed() -> void:
	#_on_is_loop_toggled(%isLoop.button_pressed)
	var animPlayer := getAnimPlayer(curModel)
	
	if animPlayer == null:
		return
	
	var curAnim = animsList.get_item_text(animsList.get_selected_id())
	
	animPlayer.play(curAnim)
	
	pass # Replace with function body.


func _on_file_dialog_iso_file_selected(path:  String) -> void:
	
	rewriteDict = {}
	texturesToUpdate = {}
	
	var loader = parsingFunctions["ctr"]
	ENTG.initializeLader(get_tree(),loader,[path],"ctr","ctr")
	var allModelNames = ENTG.getAllModels(get_tree(),"ctr")
	
	
	
	%ItemList.clear()
	
	for i in allModelNames:
		%ItemList.add_item(i)
	
	%ListPanel.visible = true



func patchModel():
	
	var path = curModel.get_meta("path")
	var loader = parsingFunctions["ctr"]
	
	var isoFileF = loader.iso.ISOfile.file
	#tl2
	if isoFileF == null:#CTR File
		var f = FileAccess.open(path,FileAccess.READ_WRITE)
		
		if f == null:
			EGLO.showMessage(self,"Path not found: %s"%path)
			return
		
		for offset in rewriteDict:
			f.seek(offset)
			f.store_8(rewriteDict[offset])
		
		for i in texturesToUpdate:
			patchModelTextures(i)
		
		f.close()
		rewriteDict = {}
		texturesToUpdate = {}
		return
		
	var iso : ISO = loader.iso
	
	
	var bigfileOffset = loader.bigfileRootOffset
	var isoFile : ISOFileWrapper = loader.iso.ISOfile
	
	var entries = loader.modelFiles
	
	var fileEntry = entries[path]

	var ctrOffset = bigfileOffset+fileEntry[1] * 2048

	for offset in rewriteDict:
		
		isoFile.seek(ctrOffset+offset)
		isoFile.store_buffer([rewriteDict[offset]])
	
	for i in texturesToUpdate:
		patchModelTextures(i)
	
	
	EGLO.showMessage(self,"Done")
	rewriteDict = {}
	texturesToUpdate = {}
	

func patchModelTextures(tlUI : Node):
	
	
	var tl : Dictionary = tlUI.textureLayout
	var loader = parsingFunctions["ctr"]
	var imageLoader = loader.imageLoader
	
	var isoFileF = loader.iso.ISOfile.file
	var path : String = imageLoader.getVrmPathFromRect(tl["rect"])
	var bytes : PackedByteArray = tlUI.getBytes()
	
	var colors : PackedColorArray = tlUI.getColors()
	var paletteBytes: PackedByteArray = imageLoader.colorArrayToPaletteBytes(colors)
	
	if isoFileF == null:#standalone CTR File
		var file = FileAccess.open(path,FileAccess.READ_WRITE)
		if !bytes.is_empty():
			imageLoader.modifyVRM(file,tl["rect"],bytes,false)
		imageLoader.writePaletteToVRM(file,tl["pallete"],paletteBytes)
		return
	
	var bigfileOffset = loader.bigfileRootOffset
	var entries = loader.textureFiles
	var fileEntry = entries[path]

	var vrmOffset = bigfileOffset+fileEntry[1] * 2048
	loader.iso.ISOfile.seek(vrmOffset)
	imageLoader.modifyVRM(loader.iso.ISOfile,tl["rect"],bytes,false)

	imageLoader.writePaletteToVRM(loader.iso.ISOfile,tl["pallete"],paletteBytes)
	
		

func _on_item_list_item_selected(index:  int) -> void:
	var str = %ItemList.get_item_text(index)
	var loader = parsingFunctions["ctr"]
	

	setModel(loader.createModel(str,{"debug":true}))
	


func _on_is_loop_toggled(toggled_on:  bool) -> void:
	var anims : AnimationPlayer = getAnimPlayer(curModel)
	var curAnimStr = %AnimsList.get_item_text(%AnimsList.get_selected_id())
	var anim = anims.get_animation(curAnimStr)
	if toggled_on:
		anim.loop_mode = Animation.LOOP_LINEAR
	else:
		anim.loop_mode = Animation.LOOPED_FLAG_NONE
	


func _on_file_dialog_big_file_selected(path:  String) -> void:
	
	rewriteDict = {}
	texturesToUpdate = {}
	
	var loader = parsingFunctions["ctr"]
	var file := FileAccess.open(path,FileAccess.READ)
	loader.parseBigFile(file)
	
	var allModelNames = loader.getAllModels()
	
	for i in allModelNames:
		%ItemList.add_item(i)
	
	%ListPanel.visible = true





func _on_show_wheels_checkbox_toggled(toggled_on:  bool) -> void:
	var wheels = curModel.get_node_or_null("wheels")
	
	if wheels == null:
		return
	
	wheels.visible = toggled_on
		
	
