extends Control

@export var dependantChildren = ["characterSelect"]


@onready var loader = get_node("loader")
@onready var levelSelect =  get_node("LevelSelect")
@onready var flag: ColorRect = $Flag

var flagMoving = false
var mapStorage : Array = []
var entStorage : Array = []

var ent : Node3D = null
var entThread : Thread = null
var playerCharacterName : String



func _ready():
	get_node("CharacterSelect").racerSelectedSignal.connect(racerSelected)
	levelSelect.levelSelectedSignal.connect(levelSelected)
	get_node("LevelSelect").visible = false


func _process(delta: float) -> void:
	if flagMoving:
		flag.position.x -= 2000 *delta
	else:
		flag.position.x = 0

func _physics_process(delta: float) -> void:
	if !mapStorage.is_empty() and !entStorage.is_empty():
		gotoMap(mapStorage.pop_front())

func initialize():
	breakpoint

func racerSelected(path):

	playerCharacterName = path

	entThread = ENTG.fetchEntityThreaded(playerCharacterName,{},get_tree(),"",false,entStorage)
	get_node("LevelSelect").visible = true
	get_node("LevelSelect").initialize()
	


func gotoMap(map : Node):
	$AnimationPlayer.play("flagMoveLeft")
	$"/root".add_child(map)
	
	flagMoving = true
	
	var startPosArr  = map.get_meta("startPos")
	var startRotArr = map.get_meta("startRot")
	var ent = entStorage[0]
	ent.position = startPosArr[0]
	map.add_child(ent)
	
	for i in startPosArr.size():
		var mesh = CSGBox3D.new()
		var circle = CSGSphere3D.new()
		
		circle.radius = 0.1
		circle.position.z = -0.8
		mesh.add_child(circle)
		
		mesh.position = startPosArr[i]
		mesh.rotation_degrees = startRotArr[i]
		
	   # print(mesh.rotation_degrees)
		
		map.add_child(mesh)
	
	var vis = ent.get_node("visual") 
	#rot.y = -rot.y 
	vis.rotation = startRotArr[0] 
	
	#vis.rotation.y += deg_to_rad(90+45)
#	vis.rotation = Vector3(deg_to_rad(rot.x),deg_to_rad(rot.y+180),deg_to_rad(rot.z))
	
	
	#flag.visible = false
	
	


func levelSelected(levelPath):
	#ENTG.fetchEntityThreaded(playerCharacterName,{},get_tree(),"",false,entStorage)
	#pass
	#var map = ENTG.createMap(levelPath,get_tree(),"")
	levelSelect.visible = false
	ENTG.createMapThreaded(levelPath,get_tree(),"",mapStorage)
	


#func startRace(mapPath : string):
#	breakpoint
