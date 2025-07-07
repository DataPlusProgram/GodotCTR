@tool
extends Window


@export var dict : Dictionary = {} : set = dictSet

func _process(delta: float) -> void:
	pass



func addItem(text1,text2):
	
	
	var itemList  = %ItemList
	
	
	
	var label := Label.new()
	var value := Label.new()
	var delete := Button.new()
	
	delete.pressed.connect(eraseKey.bind(dict,text1))
	
	label.text = text1
	delete.text = "Delete"
	value.text = str(text2)
	
	itemList.add_child(label)
	itemList.add_child(value)
	itemList.add_child(delete)
	


func _on_close_requested() -> void:
	visible = false


func dictSet(dict1):
	dict = dict1
	var itemList  = %ItemList
	
	for node in itemList.get_children():
		node.queue_free()
	
	for i in dict1:
		addItem(i,dict1[i])
	
	
	
func eraseKey(dict,key):
	dict.erase(key)
	dictSet(dict)
	breakpoint


func _on_add_key_button_pressed() -> void:
	
	var key =  $MarginContainer/VBoxContainer/HBoxContainer/TextEdit.text
	var value = $MarginContainer/VBoxContainer/HBoxContainer/TextEdit2.text
	
	if key.is_empty():
		return
	
	if value.is_empty():
		return
	
	dict[key] = value
	dictSet(dict)
	$MarginContainer/VBoxContainer/HBoxContainer/TextEdit.text = ""
	$MarginContainer/VBoxContainer/HBoxContainer/TextEdit2.text = ""
