extends VBoxContainer

var ignorePatterns


func _ready() -> void:
	%addonsPath.text =  ProjectSettings.globalize_path("res://addons")
	
	populateAddons()


func populateAddons():

	var dirs = []
	var dir := DirAccess.open("res://addons")

	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				dirs.append( ProjectSettings.globalize_path("res://addons/" + file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: %s" % "res://addons")
		breakpoint
		
	$%addonsPath.popupStrings = dirs

func _on_button_pressed() -> void:
	%CopyButton.disabled = true

	var sourcePath = %path.get_node("h/pathTxt").text
	var destPath = %path2.get_node("h/pathTxt").text
	
	sourcePath = ProjectSettings.globalize_path(sourcePath)
	

	
	if destPath == "desktop":
		destPath = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	
	var destDir := DirAccess.make_dir_recursive_absolute(destPath)
	sourcePath = sourcePath.rstrip("/")
	
	var root = sourcePath.substr(sourcePath.rfind("/"))
	
	if DirAccess.dir_exists_absolute(destPath+root):
		var dia := ConfirmationDialog.new()
		dia.dialog_text = "Directory %s already exists do you wish to delete?" % [destPath+root]
		add_child(dia)
		dia.popup_centered()
		await dia.confirmed
		
		OS.move_to_trash(destPath+root)
	 
	
	%CopyButton.disabled = false

	


func _on_addon_dir_button_pressed() -> void:
	OS.shell_open(%addonsPath.text)	
	pass # Replace with function body.


func _on_sym_text_pressed() -> void:
	var cmd = 'mklink /D "%s/ ""' % [%addonsPath.text]
	DisplayServer.clipboard_set(cmd)
	pass # Replace with function body.
