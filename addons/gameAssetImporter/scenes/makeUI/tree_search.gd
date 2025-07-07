extends LineEdit

var tree : Tree : set = treeSet


func treeSet(newTree : Tree):
	tree = newTree
	visible = true
	


func _on_text_changed(new_text: String) -> void:
	if tree == null:
		return

	var filter = new_text.strip_edges().to_lower()
	var root = tree.get_root()

	if root == null:
		return

	# Apply the filter recursively
	_filter_tree_items(root, filter)

func _filter_tree_items(item: TreeItem, filter: String) -> bool:
	var text = item.get_text(0).to_lower()
	var matches = filter == "" or text.find(filter) != -1
	var has_visible_child = false

	var child = item.get_first_child()
	while child:
		var child_visible = _filter_tree_items(child, filter)
		has_visible_child = has_visible_child or child_visible
		child = child.get_next()

	var visible = matches or has_visible_child
	item.visible = visible
	return visible
