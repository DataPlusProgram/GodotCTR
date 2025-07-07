extends Node
class_name steamUtil



static func findSteamDir():
	return optimisitcFind()


static func optimisitcFind():
	var t = "C:/Program Files (x86)/Steam"
	var ret = []
	if doesDirExist(t):
		return parseSteamDir(t)
		
	return []

static func doesFileExist(path : String) -> bool:
	
	return FileAccess.file_exists(path)
	
static func doesDirExist(dirPath):
	return DirAccess.dir_exists_absolute(dirPath)

static func parseSteamDir(path):
	
	var ret = []
	var vdfPath = path + "/config/libraryfolders.vdf"
	if !doesFileExist(vdfPath):
		return ret
		
	var file = FileAccess.open(vdfPath,FileAccess.READ)
	var paths = []
	
	if file != null:
		while !file.eof_reached():
			var line = file.get_line()
			if line.find('"path"') != -1:
				var p = line.replace('"path',"")
				paths.append(clean(p)+ "/steamapps/common/")
				
				
	
	var validPaths = []
	
	for i in paths:
		if ENTG.doesDirExist(i):
			validPaths.append(i)
	
	return validPaths
	
static func clean(string):
	
	var clean = ""
	var valid = " :abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./\\()"
	
	for i in string:
		if valid.find(i) != -1:
			clean += i

	return clean.replace("\\\\","/")
