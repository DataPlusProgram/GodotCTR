extends CharacterBody3D

@onready var model: Node3D# = get_node_or_null("visual/crash")
@onready var wheels : Node3D# = get_node_or_null("visual/crash/wheels")
@onready var animPlayer : AnimationPlayer #= $"visual/crash/@AnimationPlayer@387"
@export var turn_speed: float = 3.0
@export var acceleration: float = 5.0
@export var max_speed: float = 10.0


var onGround = false
var pOnGround = false
var isReady = false

var turningStage : float = 0 
var turningStageSpeed = 0.5
var dir : Vector3
var isReversing := false

func  _ready() -> void:
	model =get_node_or_null("visual").get_child(1)
	
	
	wheels = model.get_node("wheels")
	
	
	for i in model.get_children():
		if i is AnimationPlayer:
			animPlayer = i
	
	isReady = true


func _process(delta: float) -> void:
	
	
	if Input.is_action_pressed("accelerate"):  dir.z = 1 
	if Input.is_action_pressed("backward"): dir.z = -1
	if Input.is_action_pressed("jump"): dir.y = -1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("turnLeft"):dir.x = -1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("turnRight"):dir.x =  1

func _physics_process(delta: float) -> void:
	
	if !isReady:
		return
		
	var groundNormal = $movement.groundNormal
	
	if  groundNormal.length() != 0 and groundNormal.length() != INF:
		var angle = acos(groundNormal.dot(Vector3.UP))
		model.rotation.x =  -angle
		

	var xz = XZ(velocity)
	
	var dirSign = sign(dir.x)
	
	if dir.x != 0:
		if xz.length() >= 0.5:
			$visual.rotation.y -= dirSign * turn_speed * delta
		turningStage += dirSign * turningStageSpeed
	else:
		if turningStage > 0: turningStage -= turningStageSpeed
		if turningStage < 0: turningStage += turningStageSpeed
	
	setTurnState(turningStage)
	
	if dir.z == 1:
		if !isReversing:
			hideAllModels()
			#$crash/reverse.visible = true
			#animPlayer.play("reverse")
				
			isReversing = true
	
	if wheels != null:
		wheels.steerAngle = remap(clampf(turningStage,-4,4), -4,4, -45, 45)
	
	
	velocity += $movement.dirToAccVehicle(-$visual.transform.basis.z,$visual.transform.basis.x,dir,delta)
	
	dir = Vector3.ZERO
	#velocity.z = 0.01
	
	
	var t =$movement.move(delta)
	

func hideAllModels():
	for i in model.get_children():
		if i is Node3D and i.name != "wheels":
			i.visible = false

func setTurnState(value):
	turningStage = value
	turningStage = clampf(turningStage,-10,10)
	
	hideAllModels()
	
	if !model.get_node("turn").visible:
		model.get_node("turn").visible = true
		
	
	var turningStageInt : int = roundi(turningStage)
	
	
	var prevFrame = model.get_node("turn").get_node_or_null("frame " +str(10 + turningStageInt - 1))
	var curFrame = model.get_node("turn").get_node_or_null("frame " +str(10 + turningStageInt))
	var nextFrame = model.get_node("turn").get_node_or_null("frame " +str(10 + turningStageInt+1))
	

	
	if prevFrame: prevFrame.visible = false
	if nextFrame: nextFrame.visible = false
	if curFrame: curFrame.visible = true
	
func XZ(vector : Vector3) -> Vector2:
	return Vector2(vector.x,vector.z)
