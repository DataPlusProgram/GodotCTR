extends Node

var allRecord
var outDir = "user://replaysOut/"
var player : Node = null : set = playerSet
var playerBuffer : Array=  [] 
var playing = false
@onready var mouseRecorder = %mouseRecorder

func _on_control_visibility_changed() -> void:
	if $Control.visible == false:
		return
	
	if !DirAccess.dir_exists_absolute(outDir):
		return
	
	populateFileUI()

func _ready() -> void:
	mouseRecorder.mouseBufferEmptySgnal.connect(mouseFinished)
	_on_record_toggled(%Record.button_pressed)

func _on_save_pressed() -> void:
	var totalInput = [mouseRecorder.mouseRecord]
	
	if player != null:
		totalInput.append(player.inputDictBuffer)
	
	var saveStr : String = JSON.stringify(totalInput)
	
	var nextNum = getHighestReplayNumber(outDir)+1
	
	DirAccess.make_dir_absolute(outDir)
	var file = FileAccess.open(outDir+"replay%s.txt"%[nextNum],FileAccess.WRITE)
	file.store_string(saveStr)
	file.close()
	populateFileUI()


func _on_load_pressed() -> void:
	var itemList : ItemList = %ItemList
	var selected = itemList.get_selected_items()[0]
	var replayFileName = itemList.get_item_text(selected)
	
	var target = outDir+replayFileName
	
	if get_parent() is Window:
		get_parent().visible = false
	
	loadReplayFromFile(target)
	var playing = false
	

func registerPlayer(targetPlayer :Node):
	#mouseRecorder._process(0)
	player = targetPlayer
	
	mouseRecorder.isRecording = false
	player.recordInput = true
	
	
func loadReplayFromFile(filePath):
	var file := FileAccess.open(filePath,FileAccess.READ)
	var json = JSON.new()
	var text = file.get_as_text()
	json.parse(text)
	var buffer = json.get_data()
	var mouseBuffer = buffer[0]
	
	for i in mouseBuffer:
		var strVector : String = i[1]
		var split = strVector.remove_chars("()").split_floats(",")
		
		i[1] = Vector2i(split[0],split[1])#vector is read as string so convert it back
	
	
	
	playerBuffer = buffer[1] as Array
	
	for i in playerBuffer:
		for key in i:
			if i[key] is String:
				if i[key][0] == "(":
					var valueStr = i[key]
					var split = valueStr.remove_chars("()").split_floats(",")
					if split.size() == 2:
						i[key]= Vector2(split[0],split[1])
					if split.size() == 3:
						i[key]= Vector3(split[0],split[1],split[2])
				
		
	
	mouseRecorder.mouseRecord = mouseBuffer
	mouseRecorder.replayMouse()

func populateFileUI():
	var files = DirAccess.get_files_at(outDir)
	populateList(files)
	
func _physics_process(delta: float) -> void:
	if player == null:
		return
		
	if playerBuffer.is_empty():
		return
		
	player.tick(delta,playerBuffer.pop_front())

func populateList(files):
	
	var itemList : ItemList = %ItemList
	itemList.clear()
	for i in files:
		itemList.add_item(i)
	
	itemList.select(0)



func startMouseRecording():
	mouseRecorder.isRecording = true
	

func _on_record_toggled(toggled_on: bool) -> void:
	mouseRecorder.isRecording = toggled_on
	%Save.disabled = !toggled_on
	

func playerSet(node : Node):
	player = node
	

func mouseFinished():
	pass

func getHighestReplayNumber(path: String) -> int:
	var dir = DirAccess.open(path)
	if dir == null:
		return 0
	
	var max_num := 0
	for file_name in dir.get_files():
		if file_name.begins_with("replay"):
			var number_str := file_name.substr(6).split(".")[0]
			if number_str.is_valid_int():
				var num := int(number_str)
				if num > max_num:
					max_num = num
	return max_num


func _on_delete_pressed() -> void:
	var itemList : ItemList = %ItemList
	var selected = itemList.get_selected_items()[0]
	var replayFileName =  itemList.get_item_text(selected)
	DirAccess.open(outDir).remove(replayFileName)
	populateFileUI()
	
