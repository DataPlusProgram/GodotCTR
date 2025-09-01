@tool
extends Node

@export var onlyShowHighLod : bool= true

@onready var imageLoader = $imageLoader
@onready var modelLoader = $modelLoader
@onready var mapLoader = $mapLoader
@onready var entityCreator = $entityLoader
@onready var resourceManager = $resourceManager
@onready var iso : ISO = $IsoReader
@onready var mutex = Mutex.new()

var fileNames : PackedStringArray = []
var entriesOffsets : PackedInt32Array = []
var entriesSizes : PackedInt32Array = []
var bigfileRootOffset: int = 0
var bigfileCount : int = 0
var textureFiles : Dictionary [String,Array]
var modelFiles : Dictionary [String,Array]
var levelFiles : Dictionary [String,Array]
var textureLayoutsDict : Dictionary = {}
var toDisk : bool= false
var standaloneBigfile : FileAccess = null

var scaleFactor : Vector3 = Vector3.ZERO
var gameName : String

var cachedSharedVrmData = null
var params
var config

@onready var resourceTypeToCreateFunction : Dictionary = {
	"vrm" : imageLoader.createVRM
}

var version = VERSION.USA

enum VERSION {
	USA,
	PAL,
	BETA14
}

var levelInternalNameToExternal = {
	"proto8": "Dingo Canyon",
	"proto9": "Dragon Mines",
	"desert2": "Blizzard Bluff",
	"island1": "Crash Cove",
	"temple1": "Tiger Temple",
	"temple2": "Papu's Pyramid",
	"tube1": "Roo's Tubes",
	"blimp1": "Hot Air Skyway",
	"sewer1": "Sewer Speedway",
	"cave1": "Mystery Caves",
	"castle1": "Cortex Castle",
	"labs1": "N.Gin Labs",
	"ice1": "Polar Pass",
	"space": "Oxide Station",
	"coco1": "Coco Park",
	"arena2": "Tiny Arena",
	"secret1": "Slide Coliseum",
	"secret2": "Turbo Track"
}

var levelNameToSettings = {
	
	}

var cups = {
	"Wumpa Cup": ["Crash Cove", "Blizzard Bluff", "Tiger Temple", "Coco Park"],
	"Crystal Cup": ["Dingo Canyon", "Roo's Tubes", "Sewer Speedway", "Dragon Mines"],
	"Nitro Cup": ["Papu's Pyramid", "Mystery Caves", "Cortex Castle", "Tiny Arena"],
	"Crash Cup": ["N.Gin Labs", "Polar Pass", "Hot Air Skyway", "Slide Coliseum"]
}

func getReqs(configName):
	var base = {
		"UIname" : "CTR File:",
		"required" : true,
		"ext" : ["*.iso","*.bin"],
		"multi" : false,
		"fileNames" : [""],
		"hints" : []
	}
	
	if configName == "CTR EU": #don't put non-node path supported characters here
		return [base]
		
	return [base]




func initialize(args,config,gameName):

	self.gameName = gameName
	
	var ret : Array = iso.initialize(args[0])
	
	
	if ret.is_empty():
		return -1
	
	var allFiles = ret[0].keys()
	

	parseBigFile(iso.ISOfile,allFiles)
	
	
		
	if version == VERSION.BETA14:
		return
	
	var t = fileNames.find("bigfile/packs/shared.mpk")
	
	
	
	iso.ISOfile.seek((entriesOffsets[t] * 2048) + bigfileRootOffset )
	var data := iso.ISOfile.get_buffer(entriesSizes[t])
	parseMpk(data)
	

func parseMpk(d : PackedByteArray):
	var data := StreamPeerBuffer.new()
	data.put_data(d)
	data.seek(0)
	
	var size = data.get_u32()
	var size2 = data.get_u32()
	data.seek(4)
	
	var hasTable = (size >> 31) == 0
	size &= ~(1 << 31)
	
	if !hasTable:
		breakpoint
	
	var contentData = data.get_partial_data(size)[1]
	var numEntries = data.get_u32()/4
	var patchTable : PackedInt32Array = []
	patchTable.resize(numEntries)
	
	for i in numEntries:
		patchTable[i] = data.get_u32()
	
	data.seek(4)
	var texOffset = data.get_32()
	var firstModel = data.get_u32()
	var numModels = (firstModel - 4) / 4 - 1;
	data.seek(8)
	
	var modelOffsets : PackedInt32Array = []
	var modelNames = []
	modelOffsets.resize(numModels)
	
	for i in numModels:
		modelOffsets[i] = (data.get_u32())
	
	for i in modelOffsets:
		data.seek(i+4)
		modelNames.append(data.get_partial_data(16)[1].get_string_from_ascii())
		
		
	data.seek(texOffset)
	
	textureLayoutsDict.merge(getTexturesMPK(data))
	

	
	
	
func getAllGameModes():
	return {"main":"res://addons/ctr/scenes/mainMode/mainMode_template.tscn"}
	
	
	
func getTexturesMPK(data : StreamPeerBuffer):
	var unk : int = data.get_32()
	var numTextures : int = data.get_32()
	var textureOffset : int = data.get_32()
	var numGroups : int = data.get_32()
	var pionterGroups : int = data.get_32()
	
	var textureLayouts = {}
	
	for i in numTextures:
		var ret = parseIcon(data)
		textureLayouts[ret[0]] = ret[1]
	
	return textureLayouts
	
	

func parseIcon(data : StreamPeerBuffer):
	var iconName : String = data.get_partial_data(16)[1].get_string_from_ascii()
	var index = data.get_u32()
	var textureLayout = imageLoader.parseTextureLayout(data)
	return [iconName,textureLayout]
	
	
func getAllTextureEntries():
	return {"vrm":textureFiles.keys()}
	
	
func getAllModels():
	for i in modelFiles.keys():
		print(i)
	return modelFiles.keys()
	


func createMap(mapName,params : Dictionary = {},parentCache : Node = null):
	return mapLoader.createMap(mapName)

func createModelThreaded(modelName : String,specificAnims,resultStorage):
	resourceManager.createModelThreaded(modelName,resultStorage)


func createModel(modelName : String,params = {}):
	return resourceManager.fetchModel(modelName,params)


func getAllCategories():
	return ["entities","maps","models","textures","game modes"]

func getConfigs():
	return ["CTR"]

func _ready() -> void:
	
	
	return
	var file = FileAccess.open("res://CTRS/JakDax_pack.xdelta",FileAccess.READ)
	var header = file.get_buffer(4)
	var hdrIndicator = file.get_8()
	var secondaryCompressorId = file.get_8()
	return
	
	
	
func getAllMapNames():
	var mapNames : Array  = levelFiles.keys()
	
	if onlyShowHighLod:
		var filteredMapNames = []
		
		for i : String in mapNames:
			i = i.to_lower()
			if i.find("/2p/") == -1 : 
				if i.find("/4p/") == -1:
					filteredMapNames.append(i)
					
			mapNames = filteredMapNames
	
	return mapNames

func getEntityDict():
	var gSheet : gsheet = load("res://addons/ctr/resources/ctrEntites.tres") 
	var entites = gSheet.getAsDict()
	
	var retDict = {}
	
	for i in entites.keys():
		var cur = entites[i]
		var entStr = cur["name"]
		retDict[entStr] = cur
		
	
	
	return retDict

func getResourceManager() -> Node:
	return self

func getEntityCreator() -> Node:
	return entityCreator

func loadModelFromFile(filepath : String,params : Dictionary = {}):
	return resourceManager.loadModelFromFile(filepath,params)




func loadFileNames(allFiles):
	
	if allFiles.find("SCES_021.05") != -1:
		version = VERSION.PAL
	elif bigfileCount == 609:
		version = VERSION.BETA14
	
	var filePath = "res://addons/ctr/bigfileUSA.txt"
	
	if version == VERSION.PAL:
		filePath ="res://addons/ctr/bigfileEU.txt"
	
	if version == VERSION.BETA14:
		filePath = "res://addons/ctr/bigfileBeta14.txt"
	
	var file := FileAccess.open(filePath, FileAccess.READ)

	
	var t = Time.get_ticks_msec()
	var lineNum = 0
	while !file.eof_reached():
		
		var line : String = file.get_line()
		line = ("bigfile/"+line).to_lower()
	
		
		
		
		if line.get_extension() == "ctr":
			modelFiles[line] = [entriesSizes[lineNum],entriesOffsets[lineNum]]
		
		elif line.get_extension() == "vrm":
			textureFiles[line] = [entriesSizes[lineNum],entriesOffsets[lineNum]]
		elif line.get_extension() == "lev":
			levelFiles[line] = [entriesSizes[lineNum],entriesOffsets[lineNum]]
		
	
		
		fileNames.append(line)
		lineNum += 1
	
	
		
		

func parseBigFile(file: ISOFileWrapper,allFiles):
	var t = Time.get_ticks_msec()
	
	var filePath 
	
	if file.binMode == file.BIN_MODE.BUFFER:
		filePath = file.binFilePath
	else:
		filePath = file.file.get_path()
	
	if filePath.to_lower().find("bigfile") == -1:
		var size = iso.seekToFileAndReturnSize("BIGFILE.BIG")
		bigfileRootOffset = iso.ISOfile.get_position()
	#else:
	#	standaloneBigfile = file
		
	var magic = file.get_32()
	var numFiles = file.get_32()
	
	
	
	
	bigfileCount = numFiles
	entriesOffsets.resize(numFiles)
	entriesSizes.resize(numFiles)
	
	for i in numFiles:
		entriesOffsets[i]= file.get_32()
		entriesSizes[i] = file.get_32()
		
	loadFileNames(allFiles)
	
