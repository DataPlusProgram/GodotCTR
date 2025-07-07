@tool
extends Node3D



@onready var par = $"../"
@export var zoomSens : float = 1
@export var zoomMin : float = 1
@export var zoomMax : float = 100
@export var clickOnly = false
@export var middleMouseZoom = false
@export var hijackParentYaw = false
@export var allowPan = false
@export var current = false
@export var collides = false
@export var yawRange = Vector2(-88,88)
@export var initialRot = Vector2(0,0)
@export var offset = Vector2(0,0)
@export var processInput = true
@export var fov = 70: set = fovChange
@export var dist = 14
@export var lock := false
@export var freeView := false

var rotH : float = 0.0
var rotV : float = 0.0
var beingCaputred := false
@export var sensH : float  = 0.25
@export var sensV : float = 0.25


@export var movementSens : float = 3.0

@export var controllerSensH  :float  = 0.25
@export var controllerSensV : float  = 0.25



var rotationChildrenX = []
var rotationChildrenY = []
var rotationChildrenXprocess = []
var rotationChildrenYprocess = []
var facingDirChildren = []

var pYawTransform : Transform3D= Transform3D.IDENTITY
var pPitchTransform : Transform3D = Transform3D.IDENTITY

var pYaw
var pPitch

var prevTime : int
var nextTime : int



@onready var yaw : Node3D = $h
@onready var pitch : Node3D = $h/v
@onready var cam = $h/v/Camera3D

func _ready():

	position.x = offset.x
	position.y = offset.y
	
	if !InputMap.has_action("lookUp"): InputMap.add_action("lookUp")
	if !InputMap.has_action("lookDown"): InputMap.add_action("lookDown")
	if !InputMap.has_action("lookLeft"): InputMap.add_action("lookLeft")
	if !InputMap.has_action("lookRight"): InputMap.add_action("lookRight")
	
	if !InputMap.has_action("forward"): InputMap.add_action("forward")
	if !InputMap.has_action("backward"): InputMap.add_action("backward")
	if !InputMap.has_action("left"): InputMap.add_action("left")
	if !InputMap.has_action("right"): InputMap.add_action("right")
	
	if !InputMap.has_action("raise"): InputMap.add_action("raise")
	if !InputMap.has_action("lower"): InputMap.add_action("lower")
	


func attachNodeRotation( node : Node):
	pitch.remote_path =pitch.get_path_to(node)
	
func _input(event):
	if processInput == false:
		return
	
	if lock:
		return
	

	if !(event is InputEventMouseButton) and !(event is InputEventMouseMotion):
		return
	
	
	if event is InputEventMouseButton:
		
		if event.button_index == 4:
			dist = max(zoomMin,dist-zoomSens)
		
		if event.button_index == 5:
			dist = min(zoomMax,dist+zoomSens)
		
			
	if event is InputEventMouseMotion:
		
		
		
		if (clickOnly and Input.is_mouse_button_pressed(2)) or !clickOnly:
				
			rotH += -event.relative.x * sensH
			rotV += -event.relative.y * sensV
			

		
			
		if allowPan and Input.is_mouse_button_pressed(3):
			position.x += (event.relative.x * sensH)
			position.y += -event.relative.y * sensV 
			

			



func fovChange(ifov):
	if ifov != null and cam != null:
		cam.fov = ifov

func _process(delta):
	
	if Input.is_action_pressed("lookUp"):
		var strength = Input.get_action_strength("lookUp",true)
		rotV += strength * controllerSensV
	
	if Input.is_action_pressed("lookDown"):
		var strength = Input.get_action_strength("lookDown")
		rotV -= strength * controllerSensV
		
	if Input.is_action_pressed("lookLeft"):
		var strength = Input.get_action_strength("lookLeft")
		rotH += strength * controllerSensH
		
	if Input.is_action_pressed("lookRight"):
		var strength = Input.get_action_strength("lookRight")
		rotH -= strength * controllerSensH
	
	

	yaw.rotation_degrees.y = (rotH * sensH) + initialRot.x
	pitch.rotation_degrees.x = (rotV * sensV) + initialRot.y
	
	for i in rotationChildrenXprocess:
		if is_instance_valid(i):
			i.rotation.x = pitch.rotation.x
			#
	
	
	if freeView:
		if Input.is_action_pressed("forward"):
			position += -cam.global_basis.z * movementSens * delta * max(1,dist)

		if Input.is_action_pressed("backward"):
			position += cam.global_basis.z * movementSens * delta *  max(1,dist)
			
		if Input.is_action_pressed("left"):
			position -= cam.global_basis.x * movementSens * delta *  max(1,dist)
			
		if Input.is_action_pressed("right"):
			position +=cam.global_basis.x * movementSens * delta *  max(1,dist)
		
		if Input.is_action_pressed("raise"):
			position +=cam.global_basis.y * movementSens * delta *  max(1,dist) * 0.8
		
		if Input.is_action_pressed("lower"):
			position -=cam.global_basis.y * movementSens * delta *  max(1,dist)* 0.8

	pingTransforms()
 
func _physics_process(delta):
	
	
	sensH = SETTINGS.getSetting(get_tree(),"mouseSens")
	sensV = SETTINGS.getSetting(get_tree(),"mouseSens")
	
	rotV = clamp(rotV,yawRange.x/sensV,yawRange.y/sensV)
	yaw.rotation_degrees.y = (rotH * sensH) + initialRot.x
	pitch.rotation_degrees.x = (rotV * sensV) + initialRot.y
	
	cam.position.z = dist
	cam.current = current
	
	
	for i in facingDirChildren:
		if !is_instance_valid(i):
			facingDirChildren.erase(i)
	
	for i in facingDirChildren:
		i.facingDir = -yaw.basis.z
				
	pingTransforms()
	
	nextTime = Time.get_ticks_msec()
	prevTime = nextTime
	
	pYawTransform = yaw.transform
	pPitchTransform = pitch.transform
	
	
	if (clickOnly and Input.is_mouse_button_pressed(2)):
		if ! beingCaputred:
			beingCaputred = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if beingCaputred and !Input.is_mouse_button_pressed(2):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		beingCaputred = false

func getCamera():
	return $h/v/Camera3D

func getPos():
	return $h/v/Camera3D.global_position

func attach(par):
	if get_parent() != null:
		get_parent().remove_child(self)
		
	par.add_child(self)

var pRot = Vector3.ZERO

func pingTransforms():
	if !is_inside_tree():
		return
	
	for i in rotationChildrenX:
		if is_instance_valid(i):
			i.rotation.x = pitch.rotation.x
			
		#
	for i in rotationChildrenY:
		if is_instance_valid(i):
			i.rotation.y = yaw.rotation.y
			
	$h.force_update_transform()
	$h/v.force_update_transform()
	$h/v/Camera3D.force_update_transform()
	
			
	
