@tool
extends Node


@onready var parent := get_parent()
@onready var imageLoader = $"../imageLoader"
@onready var modelLoader = $"../modelLoader"
@onready var mapLoader = $"../mapLoader"
@onready var entityCreator = $"../entityLoader"

func createModelThreaded(modelName : String,specificAnims = [],resultStorage = [],textureData = []):
	if modelName.find(":") != -1:
		return parent.loadModelFromFile(modelName)
	return modelLoader.createModelThreaded(modelName,specificAnims,resultStorage,textureData)

func fetchModel(modelName : String):
	
	if parent.toDisk:
		breakpoint
		
	if modelName.find(":") != -1:
		return parent.loadModelFromFile(modelName)
	return modelLoader.createModel(modelName)
	
func loadModelFromFile(filepath : String):
	
	
	if filepath.get_extension().to_lower() != "ctr":
		return
	
	var fileData := FileAccess.get_file_as_bytes(filepath)
	var dir = filepath.get_base_dir()
	var textureData = []
	
	if FileAccess.file_exists(dir + "/shared.vrm"):
		var bytes = FileAccess.get_file_as_bytes(dir + "/shared.vrm")
		textureData = imageLoader.getVRMdata(bytes)
		

	if FileAccess.file_exists(dir + "/shared.mpk"):
		var bytes = FileAccess.get_file_as_bytes(dir + "/shared.mpk")
		parent.parseMpk(bytes)
		
		
	var model =  modelLoader.parseCTR(fileData,textureData)
	#ENTG.saveNodeAsScene(model)
	return model
