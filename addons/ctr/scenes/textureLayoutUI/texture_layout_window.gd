extends Window


func _on_close_requested() -> void:
	queue_free()




func getTextureLayoutUI():
	return $TextureLayoutUi

func setTextureLayout(tl):
	$TextureLayoutUi.textureLayout = tl
	
