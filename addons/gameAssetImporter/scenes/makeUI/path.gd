@tool
extends Control

signal pathSet
signal signalNewPathCreated
signal removedSignal
signal enterPressed

var required = false
@export var many = true
@export var text : String = "" : set = setPathText

var popupStrings : PackedStringArray = []
var popupMenu : PopupMenu = null
var isReady = false

@onready var childDialog : FileDialog = $FileDialog




func _ready():
	$h/Button2.visible = false
	$ErrorText.visible = false
	var t = ""
	
	popupMenu = load("res://addons/gameAssetImporter/scenes/makeUI/optionList.tscn").instantiate()
	popupMenu.visibility_changed.connect(popVisChange)
	popupMenu.connect("id_pressed", Callable(self, "optionPathSelect"))
	popupMenu.ready.connect(func() : popupMenu.visible = false)
	get_tree().get_root().call_deferred("add_child",popupMenu)
	
	
	if !Engine.is_editor_hint():
		recursiveOnTop(childDialog)
		
		
	isReady = true
	


func popVisChange():
	pass

func setText(txt):
	$h/Label.text = txt

func getLabelText():
	return($h/Label.text)

func setExt(arr):
	
	if arr.has("/"):
		$FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_ANY
		arr.erase("/")
	else:
		$FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
	
	
	$FileDialog.filters = arr
	
	

func setAsDir():
	$FileDialog.mode = FileDialog.FILE_MODE_OPEN_DIR


func _on_Button_pressed():
	var text : String =$h/pathTxt.text
	childDialog.root_subfolder = ""
	
	
	if !text.is_empty():
		var path =text.substr(0,text.rfind("/")) + "/"
		
		path = ProjectSettings.globalize_path(path)
		
		if path == "desktop/":
			path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
			childDialog.current_dir = path
		
		elif DirAccess.dir_exists_absolute(path):
			childDialog.current_dir = path
	
	childDialog.popup_centered_ratio(0.5)


func _on_FileDialog_file_selected(path):
	if !OS.has_feature("standalone"):
		path = ProjectSettings.localize_path(path)
	setPathText(path)
	

func getPath():
	return $h/pathTxt.text

func setPathText(txt):
	text = txt
	if !isReady:
		await ready
	
	
	
	var test = $h
	var test2 = $h/pathTxt
	$h/pathTxt.text = txt
	$ErrorText.text = ""
	emit_signal("pathSet",txt)



func setErrorText(txt):
	$ErrorText.text = "[color=red] "+txt

func _draw():
	updatePopupPos()


func updatePopupPos():
	if popupMenu == null:
		return
	
	
	var vp = get_viewport()
	var vp2 = get_tree().get_root().get_viewport()
	
	
	
	popupMenu.position.y += $h/Button3.size.y
	if "position" in vp:
		popupMenu.position += vp.position
	
	#var rect = popupMenu.position
	
	
	if Engine.is_editor_hint():
		return
	
	var w = size.x
		
	var xRes = get_viewport().size.x
	if (popupMenu.position.x + w )> xRes:
		var diff = (popupMenu.position + popupMenu.size).x - xRes
		popupMenu.position.x -= diff


	
	
func recursiveOnTop(node):
	if "always_on_top" in node:
		node.always_on_top = true
			
	for i in node.get_children(true):
		recursiveOnTop(i)



func _physics_process(delta):
	

	if $ErrorText.text.is_empty():
		$ErrorText.visible = false
	else:
		$ErrorText.visible = true
	
	#if $ErrorText.visible and !getPath().is_empty():
	#	$ErrorText.visible = false
	
	
	
	var x = $h/pathTxt.text
	if !$h/pathTxt.text.is_empty() and many:
		$h/Button2.visible = true
		
	
	if popupStrings.size() == 0:
		$h/Button3.disabled = true
	else:
		$h/Button3.disabled = false
	

func _on_Button3_pressed():
	
	
	popupMenu.clear()
	
	for i in popupStrings:
		popupMenu.add_item(i)
	


	popupMenu.visible = true
	
	popupMenu.position =  $h/Button3.global_position
	updatePopupPos()

	

func optionPathSelect(id):
	setPathText(popupMenu.get_item_text(id))

func getPathCount():
	return popupStrings.size()

func _on_Button2_pressed():
	var dupe = self.duplicate()
	var oldDialog = dupe.get_node("FileDialog")
	oldDialog.get_parent().remove_child(oldDialog)
	oldDialog.queue_free()
	
	var newDialogue : FileDialog = $FileDialog.duplicate(14)
	newDialogue.dir_selected.connect(dupe._on_FileDialog_dir_selected)
	newDialogue.file_selected.connect(dupe._on_FileDialog_file_selected)
	dupe.add_child(newDialogue)
	dupe.name = "FileDialog"
	dupe.setText(getLabelText())
	dupe.setPathText("")
	get_parent().add_child(dupe)
	dupe.showDeleteButton()
	emit_signal("signalNewPathCreated",self,dupe)


func _on_FileDialog_dir_selected(dir):
	setPathText(dir)



func _on_path_txt_text_submitted(new_text):
	emit_signal("enterPressed")
	pass # Replace with function body.


func _on_path_txt_text_changed(path):
	emit_signal("pathSet",path)

func _on_delete_self_pressed():
	emit_signal("removedSignal",self)
	queue_free()

func showDeleteButton():
	$h/deleteSelf.visible = true
