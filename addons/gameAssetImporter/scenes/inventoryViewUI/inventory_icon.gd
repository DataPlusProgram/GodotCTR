extends Control

var lastImage : Image = null


func setItemText(text : String):
	%text.text = text



func setCountText(text : String):
	%count.text = text

func setImage(img : Image):
	
	if lastImage == img:
		return
	
	lastImage = img
	
	if img == null:
		%TextureRect.texture = null
		return
	
	
	
	var texture : ImageTexture = ImageTexture.create_from_image(img)
	%TextureRect.texture = texture
