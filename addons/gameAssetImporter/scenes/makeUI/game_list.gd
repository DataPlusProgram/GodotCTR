extends ItemList
signal  configSelected

func _on_gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
		
	var idx = get_item_at_position(event.position, true)
	
	if idx == -1:
		return
	
	emit_signal("configSelected",get_item_text(idx))
	
