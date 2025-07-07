extends PopupMenu


func _on_focus_exited() -> void:
	visible = false#if this is remove the pop won't show up again for some reason
