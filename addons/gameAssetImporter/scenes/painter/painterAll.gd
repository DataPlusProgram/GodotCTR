@tool
extends Control

@onready var isEditor = Engine.is_editor_hint()


@export_category("Configuration")
@export var paletteMode = false : set = setPaletteMode
@export var paletteColors : PackedColorArray = [] : set = setPaletteColors

@export_category("Style")

@export var bgColor = Color.BLUE : set = setBgColor
@export var imageBgColor = Color.GRAY
@export var viewportSideMargin = 40 : set = setViewportSideMargin
@export var viewportVerticalMargin = 10

enum MENU_DISPLAY {
	ALL,
	NONE,
}

var curMenuDisplay : MENU_DISPLAY = MENU_DISPLAY.NONE : set = menuDisplaySet

func _ready() -> void:
	
	
	if isEditor:
		return
		
	
	%MenuButtonFile.get_popup().id_pressed.connect(menuButtonFilePressed)
		
	setBgColor(bgColor)
	setViewportSideMargin(viewportSideMargin)
	var huh = %bg
	RenderingServer.set_default_clear_color(imageBgColor)
	
	
	

func _physics_process(delta: float) -> void:
	
	if isEditor:
		return
	
	%ZoomLabel.text = str(snapped(%Camera2D.zoom.x,0.01)) + "%"

func setBgColor(color):
	bgColor = color
	if get_node_or_null("%bg") == null:
		await ready
	
	var bgBox : StyleBoxFlat = %bg.get("theme_override_styles/panel")
	bgBox.bg_color = color
	

func setImage(image : Image):
	%SubViewportContainer.setImage(image)
	

func setViewportSideMargin(value):
	
	viewportSideMargin = value
	
	if get_node_or_null("%ViewportMargin") == null:
		await ready
	
	
	print("set viewport side margin ",viewportSideMargin)
	%ViewportMargin.set("theme_override_constants/margin_left",viewportSideMargin)
	%ViewportMargin.set("theme_override_constants/margin_right",viewportSideMargin)
	
func menuButtonFilePressed(idx):
	
	if idx == 0:
		%FileDialogOpen.popup_centered()
		
	if idx == 2:
		breakpoint
	



func _on_file_dialog_open_file_selected(path:  String) -> void:
	if path.get_extension() ==  "png":
		setImage(Image.load_from_file(path))
	
	if path.get_extension() ==  "svg":
		setImage(Image.load_from_file(path))
		
	pass # Replace with function body.

func setPaletteMode(value):
	paletteMode = value
	
	if get_node_or_null("%bg") == null:
		await ready
		
	
	%PaletteButtonContainer.visible = value
	%ColorPickerButton.visible = !value
		

func setPaletteColors(colors : PackedColorArray):
	paletteColors = colors
	
	if get_node_or_null("%bg") == null:
		return
	
	for child : Node in %PaletteColorContainer.get_children():
		child.queue_free()
	
	

		
	
	for i : int in colors.size():
		var color = colors[i]
		var colorRect:= ColorRect.new()
		colorRect.color = color
		colorRect.custom_minimum_size = Vector2i(32,32)
		colorRect.set_meta("index",i)
		colorRect.gui_input.connect(paletteColorInput.bind(colorRect))
		%PaletteColorContainer.add_child(colorRect)
	
	if colors.size() > 0:
		%SubViewportContainer.curColor = colors[0]
	

func getImageBitmapData() -> PackedByteArray:
	var image : Image = %SubViewportContainer.texture.get_image()
	var bitmap : PackedByteArray = []
	var imageW = image.get_size().x
	var imageH = image.get_size().y
	bitmap.resize(imageW*imageH)
	
	var count = 0
	
	for y in imageH:
		for x in imageW:
			var pixelColor : Color = image.get_pixel(x,y)
			
			var bitmapIndex = paletteColors.find(pixelColor)
			
			var smallestDiff = INF
			var smallestDiffIndex = 0
			
			for idx : int in paletteColors.size():
				
				var i = paletteColors[idx]
				var diff = i - pixelColor
				var diffAmt = Vector4(diff.r,diff.g,diff.b,diff.a).length()
				
				if diffAmt < smallestDiff:
					smallestDiff = diffAmt
					smallestDiffIndex = idx
					
			
			bitmap[count] = smallestDiffIndex
			count += 1

	return bitmap

func getTexture() -> Texture2D:
	return %TextureRect.texture

func _on_palette_button_pressed() -> void:
	pass # Replace with function body.

func paletteColorInput(event : InputEvent,colorNode : ColorRect):
	if event is not InputEventMouseButton:
		return
		
	
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
		
	%SubViewportContainer.curColor = colorNode.color
	$Window.visible = false


func _on_palette_button_gui_input(event:  InputEvent) -> void:
	
	if event is not InputEventMouseButton:
		return
		
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	$Window.popup_centered()


func _on_window_close_requested() -> void:
	$Window.visible = false


func menuDisplaySet(value : MENU_DISPLAY):
	curMenuDisplay = value
	
	if curMenuDisplay == MENU_DISPLAY.NONE:
		%MenuContainer.visible = false
	
	if curMenuDisplay == MENU_DISPLAY.ALL:
		%MenuContainer.visible = false
