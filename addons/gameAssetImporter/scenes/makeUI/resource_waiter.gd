@tool
extends Node

var waitingForFiles : Array[String] = []
var queuedSaves : Array[Callable]
var pngImportTemplate : String = ""
var emitPrimed = false
var counter = 0


@onready var parent = get_parent()
@onready var isEditor = Engine.is_editor_hint()

func _physics_process(delta):
	
	if waitingForFiles.is_empty():
		return
	
	
	
	counter += delta
	
	if counter <= 1:
		return
	
	print(waitingForFiles)
	
	waitingForFileTick()
	counter = 0
	


func waitingForFileTick():
	

	var onceMore = true

	if isEditor:
		if !parent.editorInterface.get_resource_filesystem().is_scanning():
			parent.editorInterface.get_resource_filesystem().scan()
	
	while waitingForFiles.size() > 0 and onceMore:
		onceMore = false
		
		var file = waitingForFiles.pick_random()
		if ENTG.doesFileExist(file):
			waitingForFiles.erase(file)
			onceMore = true
 
		
	if waitingForFiles.size() == 0:
		for i : Callable in queuedSaves:
			i.call()
		
		queuedSaves.clear()
		 
		if "toDisk" in parent.cur:
			parent.cur.toDisk = parent.pToDisk
		

func addFileToWaitList(path):
	#var file = File.new()
	
	var p = getImportPath(path)
	
	if waitingForFiles.has(p):
		return
	
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	var pre = "res://.godot/imported/" + fileHash.split("-",false)[0] + ".png-"  + fileHash.split("-")[1] + ".md5" #the file in super.import for filename-md5Code 
	#var pre = "res://.godot/imported/" + fileHash.split("-",false)[0] + ".png-"  + fileHash.split("-")[1] + ".md5"
	

	if FileAccess.file_exists(pre):
		DirAccess.remove_absolute(pre)

	
	#if !imageBuilder.skyboxTextures.has(path.get_file()):
	#	createImportFile(path)
	#else:
	createImportFilePNG(path)
		
	
	waitingForFiles.append(p)
	
func createImportFile(path : String):
	
	if pngImportTemplate.is_empty():
		var file = FileAccess.open("res://addons/gameAssetImporter/importSettingsGodot4.txt", FileAccess.READ)
		pngImportTemplate = file.get_as_text()
		file.close()
	
	#var fileName = path.get_basename().get_file()
	var fileName = path.get_file()
	var fileHash = fileName + "-" + path.md5_text()

	
	#var id = ResourceUID.create_id()
	var id = ResourceUID.create_id_for_path(path)
	var content = pngImportTemplate
	content = content % [ResourceUID.id_to_text(id),fileHash,path,fileHash]
	ResourceUID.add_id(id,path)
	
	

	var file = FileAccess.open(path+".import",FileAccess.WRITE)
	
	file.store_string(content)
	file.close()
	
	

func createImportFilePNG(path : String):
	if pngImportTemplate.is_empty():
		var file = FileAccess.open("res://addons/gameAssetImporter/importSettingsGodot4.txt", FileAccess.READ)
		pngImportTemplate = file.get_as_text()
		file.close()
	
	path = path.replace("\\","--")
	
	#var fileName = path.get_basename().get_file()
	var fileName = path.get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	
	
	
	#var id = ResourceUID.create_id()
	var id = ResourceUID.create_id_for_path(ENTG.getCtexPath(path))
	var content = pngImportTemplate
	var a = ResourceUID.id_to_text(id)
	
	if a == null or path == null or fileHash == null:
		breakpoint
	
	
	content = content % [a,fileHash,path,fileHash]
	
	ResourceUID.add_id(id,path)
	
	
	
	
	var file : FileAccess = FileAccess.open(path+ ".import",FileAccess.WRITE)
	file.store_string(content)
	file.close()
	
	



func getImportPath(path):
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + ".png-" + path.md5_text()
	return ".godot/imported/" + fileHash + ".ctex"
	
