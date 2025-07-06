extends CharacterBody3D


func _physics_process(delta):
	velocity = -Vector3(transform.basis.z)
	move_and_slide()
