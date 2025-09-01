extends Window

signal windowCloseSignal

func _on_close_requested() -> void:
	visible = false
	emit_signal("windowCloseSignal")
