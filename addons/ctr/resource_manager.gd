@tool
extends Node


@onready var parent := get_parent()
@onready var imageLoader = $"../imageLoader"
@onready var modelLoader = $"../modelLoader"
@onready var mapLoader = $"../mapLoader"
@onready var entityCreator = $"../entityLoader"

func createModelThreaded(modelName : String,params = {},resultStorage = [],textureData = []):
	
	var specificAnims = []
	
	#if params.has("specificAnims"):
	#	specificAnims = params["specificAnims"]

	if modelName.find(":") != -1:
		return parent.loadModelFromFile(modelName)
	return modelLoader.createModelThreaded(modelName,params,resultStorage,textureData)

func fetchModel(modelName : String, params : Dictionary):
	
	if parent.toDisk:
		breakpoint
	
	
	
	
	if modelName.find(":") != -1:
		return parent.loadModelFromFile(modelName,params)
	return modelLoader.createModel(modelName,null,params)
	
func loadModelFromFile(filepath : String,params : Dictionary):
	
	
	
	if filepath.get_extension().to_lower() != "ctr":
		return
	
	var fileData := FileAccess.get_file_as_bytes(filepath)
	var dir = filepath.get_base_dir()
	var textureData : Array[Dictionary] = []
	
	if FileAccess.file_exists(dir + "/shared.vrm"):
		var bytes = FileAccess.get_file_as_bytes(dir + "/shared.vrm")
		textureData = imageLoader.getVRMdata(bytes,dir + "/shared.vrm")
		

	if FileAccess.file_exists(dir + "/shared.mpk"):
		var bytes = FileAccess.get_file_as_bytes(dir + "/shared.mpk")
		parent.parseMpk(bytes)
		
#	parseCTR(d : PackedByteArray,textureData:Array[Dictionary] = [],customStartOffset := 0,specificAnimation := []):
	var model =  modelLoader.parseCTR(fileData,textureData,0,params)
	model.set_meta("path",filepath)
	#ENTG.saveNodeAsScene(model)
	return model
