extends HBoxContainer

func _draw():
	print($v1.size.x )
	
	$v1.size.x = min($v1.size.x,500)
