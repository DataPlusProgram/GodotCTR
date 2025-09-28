extends Node


var isRecording : bool = true
var mouseRecord = []
var outDir = "user://replaysOut/"
func _process(delta: float) -> void:
	if isRecording:
		recordMouse()

func recordMouse():
	
	if !isRecording:
		return
	
	var curPos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().size
	
	var isInside = Rect2(Vector2.ZERO, viewport_size).has_point(curPos)
	
	if !isInside:
		return
	
	if mouseRecord.is_empty():
		mouseRecord.append([Time.get_ticks_msec(),curPos,Input.get_mouse_button_mask()])
		return
	
	var baseTime = mouseRecord[0][0]
	var lastPos = mouseRecord.back()[1]
	var lastInput = mouseRecord.back()[2]
	
	var curInput = Input.get_mouse_button_mask()
	
	if lastPos != curPos or lastInput != curInput:
		mouseRecord.append([Time.get_ticks_msec()-baseTime,curPos,curInput])
		

func replayMouse():
	
	isRecording = false
	
	var baseTime =  mouseRecord[0][0]
	mouseRecord.pop_front()
	var pInputMask = 0
	for i in mouseRecord:
		doRecord(i,pInputMask)
		pInputMask = i[2]
		

func doRecord(record,pIputMask):
	var timeDiff = record[0]
	var pos = record[1]
	var inputMask = record[2]
	
	await get_tree().create_timer(timeDiff/1000.0).timeout
	
	Input.warp_mouse(pos)
	
	#if inputMask != 0 and pIputMask !=0:
	print(record)
	applyMouseMask(inputMask,pIputMask,pos)
	
	
func applyMouseMask(mask: int, pInputMask: int, pos: Vector2):
	_check_button(MOUSE_BUTTON_LEFT,   MOUSE_BUTTON_MASK_LEFT, mask, pInputMask, pos)
	_check_button(MOUSE_BUTTON_RIGHT,  MOUSE_BUTTON_MASK_RIGHT, mask, pInputMask, pos)
	_check_button(MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_MASK_MIDDLE, mask, pInputMask, pos)

func _check_button(button: int, bit: int, new_mask: int, old_mask: int, pos: Vector2):
	var was_pressed = (old_mask & bit) != 0
	var is_pressed  = (new_mask & bit) != 0
	
	if was_pressed != is_pressed:
		
		var ev = InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = is_pressed
		ev.position = pos
		
		Input.parse_input_event(ev)


func _on_button_pressed() -> void:
	var saveStr : String = JSON.stringify(mouseRecord)

	DirAccess.make_dir_absolute(outDir)
	var file = FileAccess.open(outDir+"replay1.txt",FileAccess.WRITE)
	file.store_string(saveStr)
	file.close()
	


func _on_load_pressed() -> void:
	var itemList : ItemList = %ItemList
	var selected = itemList.get_selected_items()[0]
	var replayFileName = itemList.get_item_text(selected)
	
	var target = outDir+replayFileName
	
	if get_parent() is Window:
		get_parent().visible = false
	
	loadReplayFromFile(target)
	
	


func loadReplayFromFile(filePath):
	var file := FileAccess.open(filePath,FileAccess.READ)
	var json = JSON.new()
	var text = file.get_as_text()
	json.parse(text)
	var buffer = json.get_data()
	
	for i in buffer:
		var strVector : String = i[1]
		var split = strVector.remove_chars("()").split_floats(",")
		
		i[1] = Vector2i(split[0],split[1])#vector is read as string so convert it back
	
	mouseRecord = buffer

	
	replayMouse()
	

func _on_control_visibility_changed() -> void:
	if $Control.visible == false:
		return
	
	if !DirAccess.dir_exists_absolute(outDir):
		return
	
	populateFileUI()
	

func populateFileUI():
	var files = DirAccess.get_files_at(outDir)
	populateList(files)
	

func populateList(files):
	
	var itemList : ItemList = %ItemList
	
	for i in files:
		itemList.add_item(i)
	
	itemList.select(0)
	
	
	
