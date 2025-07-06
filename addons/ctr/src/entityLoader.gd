@tool
extends Node

@onready var imageLoader = $"../imageLoader"
@onready var modelLoader = $"../modelLoader"
@onready var mapLoader = $"../mapLoader"
@onready var entityCreator = $"../entityLoader"

func createRacer(entityInfo,params):
	var baseScene: Node = load("res://addons/ctr/scenes/racer/racer_template.tscn").instantiate()
	var modelPath = entityInfo["param1"]
	
	var model = modelLoader.createModel(modelPath)
	var test = baseScene.get_node("visual")
	baseScene.get_node("visual").add_child(model)
	
	
	var image : Image = imageLoader.fetchTexture(entityInfo["name"])

	return baseScene
	
