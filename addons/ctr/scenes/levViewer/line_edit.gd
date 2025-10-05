extends LineEdit


@onready var mapList = %MapList

func _ready() -> void:
	%MapListContainer.visibility_changed.connect(visChange)
	
func _on_text_changed(new_text: String) -> void:
	
	if mapList == null:
		return
	
	for child in mapList.get_children():
		if child is Button:
			# Case-insensitive filtering
			child.visible = new_text == "" or child.text.to_lower().find(new_text.to_lower()) != -1



func visChange() -> void:
	_on_text_changed(text)
