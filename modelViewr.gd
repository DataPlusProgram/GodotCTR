extends Node

var modelLoaders : Dictionary[String,PackedScene] = {
	"ctr" : preload("res://addons/ctr/CTR_Loader.tscn")
}

var parsingFunctions  : Dictionary[String,Node]= {
	
}

var curModel = null

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
	

	$"../MenuBar/menuButtonOpen".get_popup().id_pressed.connect(_on_menu_button_open_pressed)
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
	
	
		
		

func _on_file_dialog_file_selected(path: String) -> void:
	
	var ext = path.get_extension()
	
	%ListPanel.visible = false
	setModel(parsingFunctions[ext].createModel(path))
	

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
	
	var loader = parsingFunctions["ctr"]
	ENTG.initializeLader(get_tree(),loader,[path],"ctr","ctr")
	var allModelNames = ENTG.getAllModels(get_tree(),"ctr")
	
	for i in allModelNames:
		%ItemList.add_item(i)
	
	%ListPanel.visible = true



func _on_item_list_item_selected(index:  int) -> void:
	var str = %ItemList.get_item_text(index)
	var loader = parsingFunctions["ctr"]
	setModel(loader.createModel(str))
	


func _on_is_loop_toggled(toggled_on:  bool) -> void:
	var anims : AnimationPlayer = getAnimPlayer(curModel)
	var curAnimStr = %AnimsList.get_item_text(%AnimsList.get_selected_id())
	var anim = anims.get_animation(curAnimStr)
	if toggled_on:
		anim.loop_mode = Animation.LOOP_LINEAR
	else:
		anim.loop_mode = Animation.LOOPED_FLAG_NONE
	


func _on_file_dialog_big_file_selected(path:  String) -> void:
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
		
	
