extends Control

@onready var itemContainer = %ItemContainer
var par = null
@export var showZero : bool = false
@export var showNaN : bool = false
@export var fixedSize : int = -1
@export var iconSize = Vector2i(64,64)
@export var compactMode = false : set = compactModeSet

var prevMouseCapture = null
var iconUIPool : Array = []

var itemScene = load("res://addons/gameAssetImporter/scenes/inventoryViewUI/inventoryIcon.tscn").instantiate()
var flag = true

func _physics_process(delta: float) -> void:
	
	if visible == false:
		return
	
	if par == null:
		par = get_node_or_null("../")
	
	if par == null:
		return
	
	
	
	if not "inventory" in par:
		return
	
	var inventory : Dictionary = par.inventory
	updateInventory(inventory)
	

func updateInventory(inventory : Dictionary):
	
	if flag == false:
		return
	
	itemContainer = $ColorRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemContainer
	if itemContainer == null:
		return
	
	clear()
	
	for item in inventory:
		addItem(item,inventory[item])
	
	if fixedSize == -1:
		return
	
	
	var diff = fixedSize - itemContainer.get_child_count()
	
	for i in diff:
		addItem("empty",{})
	
	#flag = false

func clear():

	for i in itemContainer.get_children():
		itemContainer.remove_child(i)
		iconUIPool.push_back(i)


func addItem(str : String,entry : Dictionary):
	
	var item
	
	if iconUIPool.size() > 0:
		item = iconUIPool.pop_front()
	else:
		item = itemScene.duplicate()
		item.custom_minimum_size = iconSize
	
	if str == "empty":
		item.setItemText("")
		item.setCountText("")
		itemContainer.add_child(item)
		return
	
	if entry.has("count"):
		var count = entry["count"]
	

		if count > 0:
			item.setCountText(str(count))
		elif  showZero:
			item.setCountText(str(count))
		else:
			return
		
	elif showNaN:
		item.setCountText("NaN")
	else:
		return
		
	item.setItemText(str)
	
	
	itemContainer.add_child(item)
	


func _on_visibility_changed() -> void:
	prevMouseCapture = Input.mouse_mode
	
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif prevMouseCapture != null:
		Input.mouse_mode = prevMouseCapture
	
func compactModeSet(value):
	compactMode = value
	%InventoryTitle.visible = value
	%HSeparator.visible = value
