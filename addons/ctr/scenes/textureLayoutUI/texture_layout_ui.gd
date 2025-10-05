extends VBoxContainer

signal valueChangedSignal
signal vrmChagnedSignal
signal paletteChangedSignal

var painterWindow : Window = null

var colors : PackedColorArray : set = setColors
var textureLayout : Dictionary = {} : set = setTextureLayout

var title : String = "" : set = setTitle

func setTextureLayout(tl : Dictionary):
	
	textureLayout = tl
	
	var uvs = tl["uv"]
		
	%uv1x.value = uvs[0].x
	%uv1y.value = uvs[0].y
		
	%uv2x.value = uvs[1].x
	%uv2y.value = uvs[1].y
		
	%uv3x.value = uvs[2].x
	%uv3y.value = uvs[2].y
		
	%uv4x.value = uvs[3].x
	%uv4y.value = uvs[3].y
		
	var pagePos = tl["page"]
	%pagelX.value = pagePos.x
	%pagelY.value = pagePos.y
	
	var palettePos = tl["pallete"]
	%palX.value = palettePos.x
	%palY.value = palettePos.y
	
	var bpp = textureLayout["bpp"]
	var pageCoord : Vector2i = textureLayout["page"]
	var topLeft = textureLayout["tlUV"]
	var dim = textureLayout["dim"]
	
	var xStartPixel = (pageCoord.x * 64) + (topLeft.x/4)#uv 255 is page pixel width which is 128
	
	if bpp == 1:
		xStartPixel = (pageCoord.x * 64) + (topLeft.x)
	
	var yStartPixel = (pageCoord.y * 128) + topLeft.y
	var rect := Rect2i(xStartPixel,yStartPixel,dim.x,dim.y)
	
	tl["rect"] = rect
	
	%vramX.value = rect.position.x
	%vramY.value = rect.position.y
	%vramWidth.value = rect.size.x
	%vramHeight.value = rect.size.y
	
	if bpp == 0:
		%bpp.value = 4
	elif bpp == 1:
		%bpp.value = 8
	else:
		%bpp.value = 16
	
	if textureLayout.has("image"):
		%Texture.texture = ImageTexture.create_from_image(textureLayout["image"])
		%dim.text = "%sx%s" % [textureLayout["image"].get_size().x,textureLayout["image"].get_size().y]
	
	

func _ready():
	%uv1x.value_changed.connect(valueChanged)
	%uv1y.value_changed.connect(valueChanged)
	%uv2x.value_changed.connect(valueChanged)
	%uv2y.value_changed.connect(valueChanged)
	%uv3x.value_changed.connect(valueChanged)
	%uv3y.value_changed.connect(valueChanged)
	%uv4x.value_changed.connect(valueChanged)
	%uv4y.value_changed.connect(valueChanged)
	%pagelX.value_changed.connect(valueChanged)
	%pagelY.value_changed.connect(valueChanged)
	%palX.value_changed.connect(valueChanged)
	%palY.value_changed.connect(valueChanged)
	
	

func valueChanged(value : int):
	emit_signal("valueChangedSignal")


func getBytes() -> PackedByteArray:
	if painterWindow == null:
		return []
	
	var painter = painterWindow.get_child(0)
	return painter.getImageBitmapData()

func setColors(cols : PackedColorArray):
	
	colors = cols
	
	if colors.is_empty():
		%ColorsLabel.visible = false
		%PaletteContainer.visible = false
		%HSeparator3.visible = false
		return
		
	%ColorsLabel.visible = true
	%PaletteContainer.visible = true
	%HSeparator3.visible = true
	
	for i in colors:
		#var colorRect:= ColorRect.new()
		var colorRect:= ColorPickerButton.new()
		colorRect.color_changed.connect(tlPaletteColorChanged)
		colorRect.color = i
		colorRect.custom_minimum_size = Vector2i(32,32)
		%PaletteContainer.add_child(colorRect)

func  getColors() -> PackedColorArray:
	
	var packedColorArray : PackedColorArray = []
	
	for i : ColorPickerButton in %PaletteContainer.get_children():
		packedColorArray.append(i.color)
		
	return packedColorArray
		

func _on_texture_gui_input(event:  InputEvent) -> void:
	
	
	if event is not InputEventMouseButton:
		return
		
	if event.button_mask != MOUSE_BUTTON_LEFT:
		return
		
	
	var vrmPath : String =  %VRMpath.text
	
	
	if %Texture.texture == null:
		return
	var image : Image = %Texture.texture.get_image()
	
	if vrmPath.is_empty():
		EGLO.showMessage(self,"VRM couldn't be found. Unable to edit")
		return
	
	if painterWindow == null:
		painterWindow = load("res://addons/gameAssetImporter/scenes/painter/painterWindow.tscn").instantiate()
		painterWindow.windowCloseSignal.connect(painterWindowClose)
	
	
	
	var painter = painterWindow.get_child(0)
	painter.curMenuDisplay = painter.MENU_DISPLAY.NONE
	painter.setImage(image)
	painter.paletteMode = true
	painter.paletteColors = colors
	
	get_tree().get_root().add_child(painterWindow)
	painterWindow.popup_centered()
	

func painterWindowClose():
	var painter = painterWindow.get_child(0)
	%Texture.texture = painter.getTexture()
	emit_signal("vrmChagnedSignal")
	

func tlPaletteColorChanged(color : Color):
	emit_signal("paletteChangedSignal")

func setTitle(titleStr : String):
	title = titleStr
	
	if title.is_empty():
		%TitleContainer.visible = false
	else:
		%Title.text = titleStr
		%TitleContainer.visible = true
