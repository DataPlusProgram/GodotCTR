@tool
extends Node3D


@export var message : String = "" : set = setMessage
@export var length : float = 0.615 : set = setLength
@export var headLength : float = 0.615 : set = setHeadLength
@export var headThickness : float = 0.148 : set = setHeadThickness
@export var baseThickness : float = 0.06 : set = setBaseThickness
#@export var visaulScale : Vector3  = Vector3.ONE : set = setVisualScale
@export var disableMessage : bool = false
@export var color : Color = Color.WHITE : set = setColor

@export var id : String = ""
var isReady = false
var isEditor = Engine.is_editor_hint()
var collision : CollisionShape3D = null

func setMessage(msg):
	message = msg
	$Label3D.text = message


func _ready() -> void:
	if disableMessage:
		$Label3D.queue_free()
		
	if $CSGCylinder3D.material == null:
		var mat := createMaterial()
	
	isReady = true
	

func generateCollisionSimple():
	var colShape := BoxShape3D.new()
	colShape.size.x = 0.273
	colShape.size.y = 0.318
	colShape.size.z = 1.0
	var colShapeInst := CollisionShape3D.new()
	colShapeInst.shape = colShape
	var staticBody = StaticBody3D.new()
	staticBody.add_child(colShapeInst)
	collision = colShapeInst
	add_child(staticBody)

#func generateCollision():
	#var ret : Array[CollisionShape3D]
	#var body = StaticBody3D.new()
	#add_child(body)
	#
	#for i  in get_children():
		#if "bake_collision_shape" in i:
			#var colsShape = CollisionShape3D.new()
			#colsShape.shape = i.bake_collision_shape()
			#body.add_child(colsShape)
	#
	#for i  in get_children():
		#if i is not StaticBody3D:
			#continue
		#i.reparent(body)
		#
	#
	#return ret
	
	
func setHeadThickness(value : float):
	if !isReady:
		await ready
	
	value = max(0,value)
	headThickness = value
	$CSGCylinder3D2.radius = value

	
func setBaseThickness(value : float):
	
	if !isReady:
		await ready
		
	value = max(0,value)
		
	baseThickness = value
	$CSGCylinder3D.radius = value

func setColor(col : Color):
	
	color = col
	
	if !isReady: #and !isEditor:
		await ready
	
	
	if $CSGCylinder3D.material == null:
		var mat := createMaterial()
		
		$CSGCylinder3D.material = mat
		$CSGCylinder3D2.material = mat
	
	
	$CSGCylinder3D.material.albedo_color = color
	$CSGCylinder3D2.material.albedo_color = color


func createMaterial() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.no_depth_test = true
	#mat.set_depth_test(BaseMaterial3D.DepthTest.DEPTH_TEST_DEFAULT)

	return mat

func setLength(value: float):
	
	if !isReady:
		await ready
	
	value = max(0,value)
	
	length = value
	
	value = max(value-headLength,0)
	$CSGCylinder3D.position = -Vector3(0,0,value) * 0.5
	$CSGCylinder3D.height = value
	$CSGCylinder3D2.position = $CSGCylinder3D.position - Vector3(0,0,length) * 0.5
	
	if collision != null:
		collision.position = $CSGCylinder3D.position
		collision.shape.size.z = value
		collision.shape.size.x = baseThickness*1.5
		collision.shape.size.y = baseThickness*1.5
	

func setHeadLength(value : float):
	
	if !isReady:
		await ready
	value = max(0,value)
	$CSGCylinder3D2.height = value
	headLength = value
	
	setLength(length)
