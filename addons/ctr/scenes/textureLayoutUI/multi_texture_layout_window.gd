extends Window


var tlList : Dictionary[String,Dictionary]  = {} : set =  setTllist



func _on_close_requested() -> void:
	queue_free()



func getTextureLayoutUI():
	return $TextureLayoutUi

func setTllist(dict):
	tlList = dict
	for i in %TLS.get_children():
		i.queue_free()
		
	for i in dict.keys():
		var node= load("res://addons/ctr/scenes/textureLayoutUI/textureLayoutUI.tscn").instantiate()
		node.textureLayout = dict[i]
		node.title = i
		%TLS.add_child(node)
