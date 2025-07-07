extends Node

@export var scripts : Array[Script] = []

@onready var expression : Expression = Expression.new()

var childNodes : Array[Node]= []
var funcNames = []


func _ready():
	
	childNodes.append($nativeFuncs)
	
	for i in scripts:
		var node : Node = Node.new()
		node.set_script(i)
		add_child(node)
		childNodes.append(node)
	
	populateFuncNames()
	
	
func populateFuncNames():
	for node : Node in childNodes:
		var funcEntries = node.get_script().get_script_method_list()
		
		for funcEntry in funcEntries:
			var funcName =  funcEntry["name"].to_lower()
			if !funcNames.has(funcName):
				funcNames.append(funcName)
			
	
	


func registerScript(script):
	for node : Node in childNodes:
		var existingScript = node.get_script()
		if existingScript.resource_path == script:
			return
	
	var node : Node = Node.new()
	node.set_script(load(script))
	add_child(node)
	childNodes.append(node)
	

func execute(text:String) -> String:
	
	if text.is_empty():
		return ""
	
	text = text.to_lower()
	
	if text.split(" ").size() == 2:
		
		var funcName = text.split(" ")[0]
		var args = text.split(" ")[1]
		if args.is_valid_int():
			text = funcName + "(" + args + ")"
		else:
			text = funcName + "(\"" + args + "\")"
	
	elif text[text.length()-1] != ")":#if it doesn't end in a parenthesis we probably forgot to add them
		text += "()"
	
	
	
	for node : Node in childNodes:
		var checkText : String = checkFuncForNode(node,text)
		
		
		if checkText == &"Incorrect parameters for function":
			return "[color=red]"+ checkText +"[/color]"
			
		if checkText != "failed":
			return checkText
		
			
	
	return "[color=red]Command: "+ text +" not found.[/color]"
	


func checkFuncForNode(node : Node,txt) -> String:
	var error = expression.parse(txt)
	
	if error != OK:
		return ""
	
	
	var tst = node.get_script().get_script_method_list()
	var found = false
	
	var sanitName = txt.split("(")[0]
	
	#var sanitName = text.replace("(","").replace(")","")
	
	var targetFuncEntry = null
	
	for funcEntry in tst:
		
		if funcEntry["name"] == sanitName:
			found = true
			targetFuncEntry = funcEntry
			break
	
	if !found:
		return "failed"
	
	if targetFuncEntry["args"] != targetFuncEntry["default_args"]:# if there are some non default args
		if txt.find("(")+1 == txt.find(")"):
			return &"incorrect parameters for function"
		
	
	var expressionReturn = expression.execute([],node)
	
	if expression.has_execute_failed():
		return "failed"
	
	if typeof(expressionReturn) == TYPE_DICTIONARY:
		return expressionReturn["str"]
	elif typeof(expressionReturn) == TYPE_STRING:
		return expressionReturn
		
	return ""
	
