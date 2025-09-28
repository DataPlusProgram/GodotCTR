extends Node

@onready var http_request = $HTTPRequest

func _ready():
	
	var url = "https://api.github.com/users/DataPlusProgram/repos"
	var err = $HTTPRequest.request(url)
	if err != OK:
		print("Request failed with error: ", err)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var repos : PackedStringArray = []
	var apiLimit = false
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Array:
			for repo in json:
				repos.append(repo["name"])  # Print each repo's name
		else:
			print("Unexpected response format.")
	else:
		if response_code == 403:
			$VBoxContainer/Msg.text = "Api limit reached"
			apiLimit = true
		else:
			print("Failed with HTTP code: ", response_code)
		
	
	
	if !repos.is_empty():
		logRepoList(repos)
	
	
	
	
	if repos.is_empty():
		if FileAccess.file_exists("user://repoLog.txt"):
			var file = FileAccess.open("user://repoLog.txt",FileAccess.READ)
			
			if file == null:
				print_debug("Could not open repo log")
				return
			
			while !file.eof_reached():
				var line = file.get_line()
				if !line.is_empty():
					repos.append(line)
				
			
	
		else:
			print_debug("No repo log exists")
			return
	
	populateList(repos)
	
	
	
	var allBranches = []
	for repoIdx in repos.size():
		
		if apiLimit : break
		
		var repoName =repos[repoIdx]
		var request = "https://api.github.com/repos/DataPlusProgram/%s/branches" % repoName
		$BranchRequest.request(request)
		await $BranchRequest.request_completed
		var branches = latestBranch
		
		if latestBranch.is_empty():
			break
		
		
		
			
		var localBranches = []
		var ob : OptionButton = %projectList.get_node(repoName)
		
		for branch in branches:
			ob.add_item(branch["name"])
			localBranches.append(branch["name"])
			
		allBranches.append(localBranches)
		latestBranch = []
		
		
			
	%projectList.columns = 4
	for i in %projectList.get_children():
		i.visible = true
		
	
				
	if allBranches.size() == repos.size():
		logBranchList(allBranches)
		return
		
	if apiLimit:
		allBranches = []
		if FileAccess.file_exists("user://branchLog.txt"):
			var file = FileAccess.open("user://branchLog.txt",FileAccess.READ)
						
			if file == null:
				print_debug("Could not open branch log")
				return
						
			while !file.eof_reached():
				var line = file.get_line()
						
				if !line.is_empty():
					allBranches.append(str_to_var(line))
				
			for i in repos:
				var ob : OptionButton = %projectList.get_node(i)
				ob.add_item(i)
			
			%projectList.columns = 4
			for i in %projectList.get_children():
				i.visible = true
				
	
		
	


	
func populateList(repos : PackedStringArray):
	for repoName in repos:
		var button = Button.new()
		button.text = repoName
		
		var branchChoiced = OptionButton.new()
		branchChoiced.name = repoName
		branchChoiced.visible = false
		
		var button2 = Button.new()
		button2.text = "Open Github"
		button2.pressed.connect(OS.shell_open.bind("https://github.com/DataPlusProgram/"+repoName))
		
		var request = "https://github.com/DataPlusProgram/%s/archive/refs/heads/main.zip" % [repoName]
		
		var button3 = Button.new()
		button3.pressed.connect($DownloadRequest.request.bind(request))
		button3.text = "Download"
		
		%projectList.add_child(button)
		%projectList.add_child(branchChoiced)
		%projectList.add_child(button2)
		%projectList.add_child(button3)
		#%projectList.add_child(button3.duplicate())
		

var latestBranch = []

func _on_download_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		EGLO.showMessage(self,"Error: " + str(response_code))
		return
		
	var zipBytes : PackedByteArray = body
	var zip := ZIPReader.new()
	var desktop  = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	var file = FileAccess.open(desktop+"/repo.zip", FileAccess.WRITE)
	if !file:
		return
	
	file.store_buffer(body)
	file.close()
	
	var reader = ZIPReader.new()
	var err = reader.open(desktop+"/repo.zip")
	extract_all_from_zip(reader,desktop + "/git")
	
	if %Inject.button_pressed:
		var template = FileAccess.open("res://addons/gameAssetImporter/scenes/copyTool/scenes/godot4projectTemplate.txt",FileAccess.READ).get_as_text()
		var output = template % ["project"]
		var f = reader.get_files()
		var projectFile := FileAccess.open(desktop + "/git/" +f[0]+"project.godot",FileAccess.WRITE)
		if projectFile == null:
			return
		projectFile.store_string(output)
		projectFile.close()
	
	if %OpenOnDownload.button_pressed:
		var f = reader.get_files()
		var dest = desktop + "/git/" +f[0]+"project.godot"
		OS.shell_open(dest)
		
		
	
	
func extract_all_from_zip(reader,destDir):
	
	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	if !DirAccess.dir_exists_absolute(destDir):
		DirAccess.make_dir_recursive_absolute(destDir)
	var root_dir : DirAccess = DirAccess.open(destDir)
	
	
	
	if root_dir == null:
		EGLO.showMessage(self,"Could not open directory:"+destDir)
		return
	
	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)


func _on_branch_request_request_completed(result:  int, response_code:  int, headers:  PackedStringArray, body:  PackedByteArray) -> void:
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Array:
			for branch in json:
				latestBranch.append(branch)
		else:
			latestBranch = []
			print("Unexpected response format.")
	else:
		if response_code == 403:
			$VBoxContainer/Msg.text = "Api limit reached"
		print("Failed with HTTP code: ", response_code)
		
	
	latestBranch.reverse()
	

func logRepoList(repos):
	var file = FileAccess.open("user://repoLog.txt",FileAccess.WRITE)
	for i in repos:
		file.store_line(i)
	
	file.close()
	 
	
	
func logBranchList(branches):
	var file = FileAccess.open("user://branchLog.txt",FileAccess.WRITE)
	for i in branches:
		file.store_line(str(i))
	
	file.close()
	
