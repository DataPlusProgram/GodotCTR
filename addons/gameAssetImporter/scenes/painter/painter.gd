extends SubViewportContainer

@onready var camera := %Camera2D
@onready var texture_rect = %TextureRect  # Adjust this if needed
@onready var texture : Texture2D = texture_rect.texture
@onready var viewport : SubViewport = %SubViewport

@export var curColor = Color.BLACK : set = curColorSet
@export var initialSize = Vector2i(640,640)

var lastDrawPos : Vector2 =  Vector2.INF

enum TOOL_MODE {
	NONE,
	PEN,
	FILL
}

var curTool : TOOL_MODE = TOOL_MODE.NONE

func _ready() -> void:
	
	if  %TextureRect.texture == null:
		var image = Image.create_empty(initialSize.x,initialSize.y,false,Image.FORMAT_RGBAF)
		image.fill(Color.WHITE)
		setImage(image)
	
	setBrushPixel()
	
	%PenButton.button_pressed = true
	%SubViewportContainer.curTool = TOOL_MODE.PEN


func setBrushPixel(color: Color = Color.BLACK,size : Vector2i = Vector2i(1,1)):
	var brushImage = Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBAF)
	brushImage.fill(color)
	%BrushTexture.texture = ImageTexture.create_from_image(brushImage)
	

func _input(event):
	return




func curColorSet(color : Color):
	curColor = color
	%PaletteButton.color = color
	%ColorPickerButton.color = color
	setBrushPixel(color)
	

func setImage(image : Image):
	%TextureRect.texture = ImageTexture.create_from_image(image)
	texture = %TextureRect.texture
	%ImageDim.text = "%s x %s" % [image.get_size().x,image.get_size().y]
	centerCamera()
	

func _on_texture_rect_gui_input(event:  InputEvent) -> void:
	#if event is InputEventMouseButton:
	#	print(event)
	
	var mousePressed = false
	var mouseJustPressed = false
	
	if event is InputEventMouseButton:
		mousePressed = InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		mouseJustPressed = mousePressed
	
	if event is InputEventMouseMotion:
		mousePressed = event.button_mask == MOUSE_BUTTON_LEFT

	
	var mousePos := Vector2(event.position.x,event.position.y)
	var mousePosi := Vector2i(event.position.x,event.position.y)
	
	%BrushTexture.position = mousePosi
	
	if !mousePressed:
		lastDrawPos = Vector2.INF
		return
	
	var points : Array[Vector2i] = [Vector2i(event.position.x,event.position.y)]
	
	
	
	if (lastDrawPos  !=  event.position):
		if lastDrawPos != Vector2.INF:
			points = getInterpolatedMousePositions(Vector2(lastDrawPos.x,lastDrawPos.y) ,mousePos)
		
	
	lastDrawPos = Vector2(event.position.x,event.position.y)
	
	if points.size() == 0:
		breakpoint
	
	var image : Image = texture.get_image()
	
	if curTool == TOOL_MODE.PEN:
		penDraw(image,points)
	
	elif curTool == TOOL_MODE.FILL:
		fillImage(image,points[0],curColor)
	else:
		return
	
	texture.image = image



func getInterpolatedMousePositions(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []

	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y

	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	
	var sx = 1
	if x0 >= x1:
		sx = -1

	var sy = 1
	if y0 >= y1:
		sy = -1
	
	var err = dx + dy  # error value

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return points


func centerCamera():
	if texture.get_image() == null:
		return
	
	var imageSize = Vector2(texture.get_image().get_size())
	var maxDim = max(imageSize.x,imageSize.y)*2.0
	
	%Camera2D.zoom = Vector2(640.0/maxDim,640.0/maxDim)
	
	%Camera2D.position = imageSize/2.0
	

func penDraw(image: Image,points : Array[Vector2i]):
	
	var imageSize : Vector2i = image.get_size()
	for pos in points:
		if pos.x < 0 or pos.y < 0:
			continue
			
		if pos.x >= imageSize.x:
			continue
			
		if pos.y >= imageSize.y:
			continue
			
		image.set_pixel(pos.x,pos.y,curColor)
	texture.image = image
	



func fillImage(image: Image, start_pos: Vector2i, fill_color: Color) -> void:

	var width = image.get_width()
	var height = image.get_height()

	var target_color = image.get_pixelv(start_pos)
	if target_color == fill_color:
		return  # Nothing to fill

	var stack: Array[Vector2i] = [start_pos]

	while stack.size() > 0:
		var pos = stack.pop_back()

		# Bounds check
		if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height:
			continue

		# Check if pixel matches target color
		if image.get_pixelv(pos) != target_color:
			continue

		# Set new color
		image.set_pixelv(pos, fill_color)

		# Add neighboring pixels
		stack.append(Vector2i(pos.x + 1, pos.y))
		stack.append(Vector2i(pos.x - 1, pos.y))
		stack.append(Vector2i(pos.x, pos.y + 1))
		stack.append(Vector2i(pos.x, pos.y - 1))


func _on_color_picker_button_color_changed(color:  Color) -> void:
	curColor = color


func turnOffAllToolButtons(exception : Node):
	for i : Node in %Tools.get_children():
		
		if i == exception:
			continue
		
		if i is not Button:
			continue
			
		i.button_pressed = false
	
func _on_pen_button_toggled(toggled_on:  bool) -> void:
	
	if toggled_on == true:
		curTool = TOOL_MODE.PEN
	
	turnOffAllToolButtons(%PenButton)
	

	

func _on_fill_button_toggled(toggled_on:  bool) -> void:
	
	if toggled_on == true:
		curTool = TOOL_MODE.FILL
	
	turnOffAllToolButtons(%FillButton)
	

	
