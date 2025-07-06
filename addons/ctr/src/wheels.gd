@tool
extends Node3D

var par = null

@onready var fronWheels = [$"frontLeft",$frontRight]
@onready var backWheels = [$"backLeft",$backRight]

var steerAngle = 0
func _ready():
	par = $"../../"
	

func _physics_process(delta: float) -> void:

	
	if get_viewport().get_camera_3d() == null:
		return
	
	var diff = get_viewport().get_camera_3d().global_position - global_position

	diff = diff.normalized()
	var angle = rad_to_deg(atan2(diff.x,diff.z)) - rad_to_deg(180)

	var horizontalDistance = sqrt(diff.x * diff.x + diff.z * diff.z)
	var verticalAngle = rad_to_deg(atan2(diff.y, horizontalDistance))
	
	
	#print(verticalAngle)
	
	if "rotation" in par:
		if par is Node3D:
			angle -=  rad_to_deg(par.rotation.y)
			angle = fmod(angle,360)

	
	var index = 0
	
	for i : AnimatedSprite3D in fronWheels:
		
	
		if verticalAngle > 50  or verticalAngle < -44:
			i.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			i.frame = 0
			continue
		
		i.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var unit = int((angle+steerAngle) / 5.625)
		index = unit % 32
		i.frame = index
		
	for i in backWheels:
		
		if verticalAngle > 50 or verticalAngle < -44:
			i.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			i.frame = 0
			continue
		
		i.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var unit = int(angle / 5.625)
		index = unit % 32
		i.frame = index
