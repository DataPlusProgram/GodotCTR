@tool
extends Node3D

signal gizmoMoved

@export var arrowLength = 1.0 : set = setArrowLength
@export var headThickness : float = 0.148 : set = setHeadThickness
@export var headLength : float = 0.148 : set = setHeadLength
@export var baseThickness : float = 0.06 : set = setBaseThickness
@export var target : Node = null

var isReady = false
var mouseReferencePos : Vector2 = Vector2.ZERO
var initialPos : Vector3
var mode :MODE = MODE.NONE : set = modeChange

enum MODE {
	NONE,
	XAXIS,
	YAXIS,
	ZAXIS
}

func _ready() -> void:
	$X.generateCollisionSimple()
	$Z.generateCollisionSimple()
	$Y.generateCollisionSimple()
	
	isReady = true

func setHeadThickness(thick):
	if !isReady:
		await ready
	headThickness = thick
	$X.headThickness = headThickness
	$Y.headThickness = headThickness
	$Z.headThickness = headThickness
	
	

func setHeadLength(len):
	if !isReady:
		await ready
	headLength = len
	$X.headLength = headLength
	$Y.headLength = headLength
	$Z.headLength = headLength
	

func setBaseThickness(thick):
	if !isReady:
		await ready
	
	$X.baseThickness = thick
	$Y.baseThickness = thick
	$Z.baseThickness = thick

func setArrowLength(len):
	
	if !isReady:
		await ready
	arrowLength = len
	$X.length = len
	$Y.length = len
	$Z.length = len


var drag_plane : Plane
var drag_start_hit : Vector3
var drag_start_pos : Vector3

func modeChange(m):
	mode = m
	mouseReferencePos = get_viewport().get_mouse_position()
	drag_start_pos = global_position

	if mode == MODE.NONE:
		return

	var camera = get_viewport().get_camera_3d()

	# Drag plane faces the camera (screen plane), not aligned with the axis
	var plane_normal = camera.global_transform.basis.z.normalized()
	drag_plane = Plane(plane_normal, global_position)

	var ray_origin = camera.project_ray_origin(mouseReferencePos)
	var ray_dir = camera.project_ray_normal(mouseReferencePos)
	var hit = drag_plane.intersects_ray(ray_origin, ray_dir)

	if hit:
		drag_start_hit = hit

func _input(event: InputEvent) -> void:
	if mode == MODE.NONE:
		return

	if event is InputEventMouseButton and not event.pressed:
		mode = MODE.NONE
		return

	if event is InputEventMouseMotion:
		var camera = get_viewport().get_camera_3d()
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)

		var hit = drag_plane.intersects_ray(ray_origin, ray_dir)
		if not hit:
			return

		var axis = get_axis_vector()
		var delta = hit - drag_start_hit
		var projected = axis * delta.dot(axis)
		
		global_position = drag_start_pos + projected
		emit_signal("gizmoMoved")
		if target != null:
			target.global_position = drag_start_pos + projected
		
		
	
		
func get_axis_vector() -> Vector3:
	match mode:
		MODE.XAXIS: return global_transform.basis.x
		MODE.YAXIS: return global_transform.basis.y
		MODE.ZAXIS: return global_transform.basis.z
		_: return Vector3.ZERO
	
func selectModeFromId(id : String):
		if id == "X":
			mode =  MODE.XAXIS
		
		if id == "Y":
			mode =  MODE.YAXIS
			
		if id == "Z":
			mode =  MODE.ZAXIS
