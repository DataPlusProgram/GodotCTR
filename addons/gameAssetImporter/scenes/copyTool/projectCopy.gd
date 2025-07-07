extends Control

var ignorePatterns

@onready var forceGodotProjectInclude = %forceProject

func _ready() -> void:
	
	%path/h/pathTxt.text = "res://"




func copyDir(src: String, dest: String) -> void:
	

	var srcDir := DirAccess.open(src)
	srcDir.include_hidden = true
	if srcDir == null:
		printerr("Can't open source folder")
		return
	
	
	
	DirAccess.make_dir_recursive_absolute(dest)
	

	var destDir := DirAccess.open(dest)
	if destDir == null:
		var err = DirAccess.get_open_error()
		printerr("Can't open dest folder")
		return
	
	srcDir.list_dir_begin()
	var entry  = srcDir.get_next()
	
	while entry  != "":
		var srcPath = src + "/" + entry
		var destPath = dest  + "/" + entry
		
		
		if is_ignored(srcPath):
			entry = srcDir.get_next()
			continue
		

		
		if srcDir.current_is_dir():
			copyDir(srcPath, destPath)
	
		elif FileAccess.file_exists(srcPath):
			
			var file = FileAccess.open(srcPath, FileAccess.READ)
			if file == null:
				breakpoint
			
			var content = file.get_buffer(file.get_length())
			file.close()
			
			#DirAccess.copy_absolute(srcPath,destPath)
			var outFile = FileAccess.open(destPath, FileAccess.WRITE)
			if outFile == null:
				breakpoint
				
			outFile.store_buffer(content)
			outFile.close()
		else:
			breakpoint
		entry = srcDir.get_next()
		

func loadGitignore(path: String ):
	
	var ignorePatterns := []

	var file := FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.begins_with("#") or line == "":
			continue

		ignorePatterns.append(line)
	file.close()
	
	return ignorePatterns
	

func is_ignored(path: String) -> bool:
	

	
	if forceGodotProjectInclude.pressed:
		if path.get_file() == "project.godot":
			return false
	
	for pattern in ignorePatterns:
		if pattern.begins_with("!"):
			continue # skip negations for now

		# Match wildcard (*.import)
		if pattern.find("*") != -1:
			var glob_pattern = pattern.replace("*", ".*")
			var regex = RegEx.new()
			regex.compile("^" + glob_pattern + "$")
			if regex.search(path):
				return true
		# Match by folder or file
		elif path.ends_with(pattern) or path.contains("/" + pattern):
			return true
	return false


func _on_addon_dir_button_pressed() -> void:
	
	OS.shell_open(%addonsPath.text)	
	pass # Replace with function body.


func _on_sym_text_pressed() -> void:
	var cmd = 'mklink /D "%s/" ""' % [%addonsPath.text]
	DisplayServer.clipboard_set(cmd)
	pass # Replace with function body.


func _on_copy_button_pressed() -> void:
	%CopyButton.disabled = true

	var sourcePath = %path.get_node("h/pathTxt").text
	var destPath = %path2.get_node("h/pathTxt").text
	
	sourcePath = ProjectSettings.globalize_path(sourcePath)
	
	
	
	if FileAccess.file_exists(sourcePath+".gitignore"):
		ignorePatterns =loadGitignore(sourcePath+".gitignore")
	
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
	 
	
	copyDir(sourcePath,destPath+root)
	
	var dialogue = EGLO.showOption(self,"Copy complete","Ok","Open Directory")
	dialogue.canceled.connect(OS.shell_open.bind(destPath+root))
	
	%CopyButton.disabled = false
