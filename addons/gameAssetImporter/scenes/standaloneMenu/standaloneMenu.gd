extends Control


func _ready():
	#var err = SETTINGS.injectTiming($makeUI,"_ready")
	$makeUI.previewWorld.get_node("Camera3D").queue_free()
	
	$makeUI.popup_centered_ratio(1)
