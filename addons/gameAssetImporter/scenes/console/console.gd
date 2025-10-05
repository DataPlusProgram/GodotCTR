extends Control

var history : Array[String] = []
var historyMaxSize = 3
var historyOffset = 0


func updateBg() -> void:
	if visible:
		$VBoxContainer/ScrollContainer/ColorRect.size.y = max($VBoxContainer/ScrollContainer/ColorRect.size.y,$VBoxContainer/ScrollContainer/MarginContainer.size.y)

func _ready():
	$VBoxContainer/ScrollContainer.draw.connect(updateBg)
	$"%input".gui_input.connect(_on_input_gui_input)
	
	if !InputMap.has_action("showConsole"):
		InputMap.add_action("showConsole")
	
	%input.words = %execute.funcNames


func _on_input_send_pressed():
	
	
	history.append(%input.text)
	
	if history.size() > historyMaxSize:
		history.pop_front()
	
	%logText.text += "[color=yellow]" +%input.text +"[/color]" + "\n"
	
	
	var retText : String = %execute.execute(%input.text)
	
	%input.text = ""
	
	if !retText.is_empty():#will return non empty for errors
		%logText.text += retText + "\n"
	
	await get_tree().physics_frame
	$VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.get_v_scroll_bar().max_value
	get_viewport().gui_release_focus()
	%input.call_deferred("grab_focus")
	%input.call_deferred("grab_click_focus")
	#%input.grab_click_focus()

func _on_input_gui_input(event):
	if !event is InputEventKey:
		return
	
	if event.keycode == KEY_ENTER and !event.echo and event.pressed:
		historyOffset = 0
		
		
		if %input.suggestion_list.visible:
			if %input.suggestion_list.is_anything_selected():
				return
		
		%input.suggestion_list.visible = false
		_on_input_send_pressed()
		
	if Input.is_action_just_pressed("ui_up"):
		if history.is_empty():
			%input.caret_column = %input.text.length()

			return
			
		if historyOffset > historyMaxSize:
			historyOffset = history.size()
		
		%input.text = history[history.size()-1-(historyOffset%history.size())]
		%input.caret_column = %input.text.length()-1
		historyOffset += 1
		
	
	if Input.is_action_just_pressed("ui_down"):
		if history.is_empty():
			return
			
			
		
		%input.text = history[history.size()-1-(historyOffset%history.size())]
		%input.caret_column = %input.text.length()-1

		historyOffset -= 1
		
		if historyOffset < 0:
			historyOffset = 0 
		
	if Input.is_action_just_pressed("ui_cancel"):
		if !%input.has_focus():
			visible = false


func _on_visibility_changed():
	if !%input.is_inside_tree():
		return
	if visible:
		%input.text = ""
		%input.grab_focus()
	
func execute(str: String):
	%execute.execute(str)
