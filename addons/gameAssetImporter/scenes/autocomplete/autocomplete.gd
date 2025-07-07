extends LineEdit

@onready var suggestion_list: ItemList = $ItemList  # Reference the existing ItemList
@onready var parent_control: Control = null  # Get the parent to constrain the box

var words = ["hello", "world", "godot", "script", "example","exe","eat", "autocomplete"]

func _ready():
	suggestion_list.hide()
	if !get_parent() is Window:
		parent_control = get_parent()
	# Connect signals
	suggestion_list.connect("item_activated", _on_item_selected)
	connect("text_changed", _on_text_changed)

func _physics_process(delta: float) -> void:
	if !has_focus():
		if !suggestion_list.has_focus():
			suggestion_list.visible = false

func _gui_input(event):
	if event is InputEventKey:
		if event.pressed:
			if (event.keycode == KEY_UP or event.keycode == KEY_DOWN):
				if suggestion_list.visible:
					if event.keycode == KEY_UP:
						suggestionListItt(-1)
					if event.keycode == KEY_DOWN:
						suggestionListItt(1)
				# Ignore the key event to prevent default behavior
				accept_event()
				
			
			if event.keycode == KEY_ENTER:
				if suggestion_list.visible:
					if suggestion_list.is_anything_selected():
						var idx = suggestion_list.get_selected_items()[0]
						var txt = suggestion_list.get_item_text(idx)
						text = txt
						suggestion_list.visible = false
						caret_column = text.length()
						accept_event()


func suggestionListItt(itt):
	if !suggestion_list.is_anything_selected():
		suggestion_list.select(0)
		return
			
	var curIdx = suggestion_list.get_selected_items()[0]
	
	if itt >= 0:
		curIdx = (curIdx + 1) % suggestion_list.item_count
	else:
		curIdx = (curIdx - 1 + suggestion_list.item_count) % suggestion_list.item_count

	
	suggestion_list.select(curIdx)
# Called when text changes in the LineEdit
func _on_text_changed(new_text: String):
	suggestion_list.clear()

	if new_text.is_empty():
		suggestion_list.hide()
		return

	var suggestions = get_suggestions(new_text)

	if suggestions.size() > 0:
		for suggestion in suggestions:
			suggestion_list.add_item(suggestion)

		var max_height = min(100, 50* suggestions.size())  # Limit height dynamically
		var new_size = Vector2(size.x, max_height)

		var new_position = Vector2(0, -new_size.y)

		suggestion_list.position = new_position
		suggestion_list.size = new_size
		suggestion_list.show()
		suggestion_list.select(0)
	else:
		suggestion_list.hide()

# Handle selection from the list
func _on_item_selected(index: int):
	text = suggestion_list.get_item_text(index)
	suggestion_list.hide()
	caret_column = text.length()  # Move cursor to the end
	grab_focus()  # Ensure the LineEdit remains focused

# Example function to generate autocomplete suggestions
func get_suggestions(input: String) -> Array:
	return words.filter(func(word): return word.begins_with(input.to_lower()))
