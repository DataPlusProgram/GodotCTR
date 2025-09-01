extends Camera2D

var dragging := false
var drag_start_position := Vector2.ZERO
var camera_start_position := Vector2.ZERO

# Zoom limits
const MIN_ZOOM := 0.2
const MAX_ZOOM := 16.0
const ZOOM_STEP := 0.05



func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				drag_start_position = event.position
				camera_start_position = position
			else:
				dragging = false

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(ZOOM_STEP, event.position)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-ZOOM_STEP, event.position)

	elif event is InputEventMouseMotion and dragging:
		var drag_offset = event.position - drag_start_position
		# Fix: scale drag offset by inverse of zoom for consistent panning
		position = camera_start_position - drag_offset / zoom

func _zoom_camera(delta: float, zoom_center: Vector2):
	var new_zoom = zoom + Vector2.ONE * delta
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)

	# Zoom toward the mouse position
	var mouse_pos = zoom_center
	var world_pos_before = to_global(mouse_pos)
	zoom = new_zoom
	var world_pos_after = to_global(mouse_pos)
	position += world_pos_before - world_pos_after
