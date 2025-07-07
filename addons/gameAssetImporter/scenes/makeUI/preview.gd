@tool
extends Control




var handleInputPar = false
@onready var subViewport = get_node_or_null("%SubViewport")


func _input(event):
	
	 
	if subViewport != null:
		for i in subViewport.get_children():
			i.set_process_input(false)
	
	
	if !("position" in event):
		return
	
	if !("global_position" in event):
		return
	
	var mPos = event.position
	mPos = event.global_position
	var pos = get_global_rect().position
	var dim = get_rect().size
	
	if Engine.is_editor_hint():
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return

	if !Engine.is_editor_hint():
		mPos = event.position
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return
		
	
	if subViewport == null:
		return
	
	if subViewport.get_node("CameraTopDown").visible:
		subViewport.get_node("CameraTopDown")._input(event)
	
	
	if subViewport.get_node("Camera3D").visible:
		subViewport.get_node("Camera3D")._input(event)


func _on_menu_button_open_pressed() -> void:
	$"../../FileDialog".popup()
	pass # Replace with function body.


func _on_sub_viewport_container_mouse_entered() -> void:
	%SubViewport.process_mode =Node.PROCESS_MODE_INHERIT


func _on_sub_viewport_container_mouse_exited() -> void:
	%SubViewport.process_mode =Node.PROCESS_MODE_DISABLED
