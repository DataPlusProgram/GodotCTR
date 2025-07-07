extends VBoxContainer


func _on_visibility_changed() -> void:
	var data : Dictionary = SETTINGS.getTimeData(get_tree())
	var procData = processData(data)
	setTreeData(procData)
	pass # Replace with function body.

func saveDataToFile():
	var data : Dictionary = SETTINGS.getTimeData(get_tree())
	dataToFile(data)
	

func processData(data : Dictionary):
	
	var dir = {}
	
	for key in data.keys():
		
		var entry = data[key]
		
		if typeof(entry) != TYPE_ARRAY:
			continue
		
		var time = entry[0]
		var path = entry[1]
		
		
		var subDir = doesHavePath(dir,path)
		#if !dir.has(path):
		#	dir[path] = {}
		
		subDir[key] = [time]
		
		
		
	return dir
	

func doesHavePath(dict,path : String):
	var dirDict = dict
	#for i in dirDict.keys():
	#	breakpoint
		
	var dirSplits = path.split("/", false)
	
	if dirSplits.is_empty():
		return dirDict
	
	for subDir in dirSplits:
		
		if subDir.is_empty():
			breakpoint
		
		if !dirDict.has(subDir):
			
			dirDict[subDir] = {}
			dirDict = dirDict[subDir]
			
		else:
			dirDict = dirDict[subDir]
	
	
	return dirDict
	


func setTreeData(data):
	var tree : Tree = $timingsTree
	var root : TreeItem= tree.create_item()
	
	tree.set_hide_root(true)
	tree.create_item(root)
	
	root.create_child()
	
	recursive(root,data,0)
	#for i in data.keys():
	#	var item : TreeItem = root.create_child()
	#	item.set_text(0,i)
		
		
		
	
	
func recursive(root,data,timeSum):
	
	var rootTime = 0
	
	for key in data.keys():
		var item : TreeItem = root.create_child()
		item.set_text(0,key)
		
		var entry = data[key]
		
		if typeof(entry) == TYPE_DICTIONARY:
			timeSum += recursive(item,entry,timeSum)
		else:
			if key.find(":"):
				key = key.split(":")[1]
			item.set_text(0,key)
			item.set_text(1,str(entry[0]))
			timeSum += entry[0]
			
			
		#item.set_text(1,str(timeSum))
		
	#root.set_text(1,str(timeSum))
	return timeSum
		
	
		
	


func _on_timings_debug_window_close_requested() -> void:
	get_parent().visible = false
	pass # Replace with function body.

func dataToFile(data):
	
	var file : FileAccess = null
	var timeStamp := Time.get_datetime_string_from_system()
	
	
	if !FileAccess.file_exists("user://performanceTmings.csv"):
		file = FileAccess.open("user://performanceTmings.csv",FileAccess.WRITE)
	else:
		file = FileAccess.open("user://performanceTmings.csv",FileAccess.READ_WRITE)
	
	
	if file == null:
		print("performance file open fail:",FileAccess.get_open_error())
		return
	
	file.seek_end()
	
	
	
	for key in data.keys():
		
		
		
		if key.find(":") == -1:
			continue
	
		var id = key
		var stateInfo = key.split(":")[0]
		var nameStar = key.split(":")[1]
		var entry = data[key]
		var time = entry[0]
		var path = entry[1]
		
		#id = id.replace(",","-")
		
		var out = [timeStamp,str(OS.get_unique_id().hash()),stateInfo.replace(",","-"),path,nameStar,str(time)]
		
		
		var lineOut = ""#OS.get_unique_id() + stateInfo.replace(",","-") + "," + path + "," + nameStar + "," + str(time)
		
		for i in out:
			lineOut += i + ","
		
		lineOut = lineOut.trim_suffix(",")
		file.store_line(lineOut)
		
	


func _on_tree_exiting() -> void:
	saveDataToFile()
	
