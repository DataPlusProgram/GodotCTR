extends Control

signal racerSelectedSignal
var runningX = 0

var racerEntries = [
	{"name": "crash", "modelPath": "bigfile/models/racers/hi/crash.ctr", "iconName": "crash", "iconImage": null},
	{"name": "cortex", "modelPath": "bigfile/models/racers/hi/cortex.ctr", "iconName": "cortex", "iconImage": null},
	{"name": "tiny", "modelPath": "bigfile/models/racers/hi/tiny.ctr", "iconName": "tiny", "iconImage": null},
	{"name": "coco", "modelPath": "bigfile/models/racers/hi/coco.ctr", "iconName": "coco", "iconImage": null},
	{"name": "ngin", "modelPath": "bigfile/models/racers/hi/ngin.ctr", "iconName": "ngin", "iconImage": null},
	{"name": "dingo", "modelPath": "bigfile/models/racers/hi/dingo.ctr", "iconName": "dingo", "iconImage": null},
	{"name": "polar", "modelPath": "bigfile/models/racers/hi/polar.ctr", "iconName": "polar", "iconImage": null},
	{"name": "pura", "modelPath": "bigfile/models/racers/hi/pura.ctr", "iconName": "pura", "iconImage": null},
	{"name": "pinstripe", "modelPath": "bigfile/models/racers/hi/pinstripe.ctr", "iconName": "pinstripe", "iconImage": null},
	{"name": "papu", "modelPath": "bigfile/models/racers/hi/papu.ctr", "iconName": "papu", "iconImage": null},
	{"name": "roo", "modelPath": "bigfile/models/racers/hi/roo.ctr", "iconName": "roo", "iconImage": null},
	{"name": "joe", "modelPath": "bigfile/models/racers/hi/joe.ctr", "iconName": "komodojoe", "iconImage": null},
	{"name": "ntropy", "modelPath": "bigfile/models/racers/hi/ntropy.ctr", "iconName": "ntropy", "iconImage": null},
	{"name": "pen", "modelPath": "bigfile/models/racers/hi/pen.ctr", "iconName": "penguin", "iconImage": null},
	{"name": "fake", "modelPath": "bigfile/models/racers/hi/fake.ctr", "iconName": "fakecrash", "iconImage": null}
]


var toLoad : Array[String] = []

var textureData
var loadingModels : Array = []
var resourceManager : Node = null
var imageLoader : Node = null
var icons : Array[Image] = []
var curSelectIdx = 0
var prevSelectIdx = 0

@onready var selector := $selector
@onready var grid := $GridContainer
@onready var colSize = grid.columns
@onready var previewWorld := $Panel/SubViewportContainer2/SubViewport
@onready var marker  = previewWorld.get_node("Marker3D")
@export var loader : Node

var targetPost = Vector3.ZERO

func _ready():
	
	loader = get_parent().get_node("loader")
	
	if loader == null:
		return
	
	textureData = loader.modelLoader.loadSharedVRMInISO()
	resourceManager =loader.get_node("resourceManager")
	loadChar("crash")
	
	if loader == null:
		return
	
	
	
	imageLoader = loader.imageLoader
	
	for i : Dictionary in racerEntries:
		var fname = i["iconName"].get_file().split(".")[0]
		i["iconImage"] = imageLoader.fetchTexture(fname)
		
		var icon = addIcon(i["iconImage"])
		icon.set_meta("info",i)
		
	

func _input(event):
	
	if selector == null:
		return
	
	
	
	
	var numRacers =  grid.get_child_count()
	
	if numRacers == 0:
		return
	
	var racersPerRow = grid.columns
	
	if Input.is_action_just_pressed("ui_left"):
		

		if (curSelectIdx) % colSize == 0:
			curSelectIdx += colSize 
			selector.global_position = grid.get_child(curSelectIdx-1).global_position
		
		curSelectIdx -= 1
		
	if Input.is_action_just_pressed("ui_right"):
		
		
		if (curSelectIdx +1) % colSize == 0:
			curSelectIdx -= colSize 
			selector.global_position = grid.get_child(curSelectIdx+1).global_position
		
		
		
		curSelectIdx += 1
		
		
		
		
	
	
	if Input.is_action_just_pressed("ui_down"):
			curSelectIdx += racersPerRow
	
	if Input.is_action_just_pressed("ui_up"):
			curSelectIdx -= racersPerRow
	
	if Input.is_action_just_pressed("ui_select"):
		racerSelected()
	
	curSelectIdx = curSelectIdx % grid.get_child_count()
	
	if curSelectIdx < 0:
		curSelectIdx += numRacers
		
	
	
func _process(delta: float) -> void:
	
	marker.rotation.y -= delta * 3
	
	if selector == null:
		return
	
	

	
	if grid.get_child_count() == 0:
		return
	
	
	
	
	var curIcon = grid.get_child(curSelectIdx)
	
	
	if curSelectIdx != prevSelectIdx:
		var info = curIcon.get_meta("info")
		loadChar(info["name"])
		updatePreview()

		
		
	
	selector.position.x= move_toward(selector.position.x,curIcon.global_position.x,delta*2000)
	selector.position.y = move_toward(selector.position.y,curIcon.global_position.y,delta*2000)
	
	prevSelectIdx = curSelectIdx

func updatePreview():
	
	var curIcon = grid.get_child(curSelectIdx)
	var curInfo = curIcon.get_meta("info")
	for i in marker.get_children():
		i.visible = i.name == curInfo["name"]
		
		
		
	pass

func _physics_process(delta: float) -> void:
	
	size = get_viewport_rect().size
	
	if resourceManager == null:
		return
	
	loadNext()
	
	for i in loadingModels:
		if !i["model"].is_empty():
			
			var model = i["model"]
			loadingModels.erase(i)
			
			if model == null:
				continue
			
			model[0].name = i["name"]
			model[0].visible = false
			
			previewWorld.get_node("Marker3D").add_child(i["model"][0])
			updatePreview()
			
	var t = 3

func racerSelected():
	var curIcon = grid.get_child(curSelectIdx)
	var info = curIcon.get_meta("info")
	emit_signal("racerSelectedSignal",info["name"])
	queue_free()

func loadChar(charString):
	
	var entry = null
	
	for i in racerEntries:
		if i["name"] == charString:
			entry = i
	
	
	if entry.has("model"):
		return

	var storage = []
	entry["model"] = storage
	textureData
	loadingModels.append(entry)
	
	resourceManager.createModelThreaded(entry["modelPath"],["idle"],storage,textureData)

	
	
func loadNext():
	
	for i in 3:
		
		if toLoad.size() == 0:
			break
		
		if loadingModels.size() >= 1:
			break
		
		var racer = toLoad.pop_front()
		var storage = []
		loadingModels[racer] = storage
		resourceManager.createModelThreaded(racer,storage,textureData)

func addIcon(icon):
	
	if icon == null:
		return
	

	
	var node := TextureRect.new()
	node.mouse_entered.connect(iconHover.bind($GridContainer.get_child_count()))
	node.gui_input.connect(iconInput.bind($GridContainer.get_child_count()))
	node.custom_minimum_size = Vector2(88,52)
	node.texture = ImageTexture.create_from_image(icon)
	$GridContainer.add_child(node)
	
	return node


func iconHover(idx : int):
	curSelectIdx = idx
	

func iconInput(ev : InputEvent,idx):
	if !ev is InputEventMouseButton:
		return
	
	
	if ev.button_index == 1:
		var curIcon = grid.get_child(curSelectIdx)
		var info = curIcon.get_meta("info")
		emit_signal("racerSelectedSignal",info["name"])
		queue_free()
	
