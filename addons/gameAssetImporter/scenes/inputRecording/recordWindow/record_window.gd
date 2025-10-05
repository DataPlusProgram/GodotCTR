extends Window


var pCapture = Input.MOUSE_MODE_CAPTURED

func _on_close_requested() -> void:
	visible = false
	pass # Replace with function body.


func _on_visibility_changed() -> void:
	if visible == true:
		pCapture = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	
	if visible == false:
		Input.mouse_mode =pCapture
		


func _on_focus_entered() -> void:
	pCapture = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



func _on_focus_exited() -> void:
	Input.mouse_mode =pCapture
