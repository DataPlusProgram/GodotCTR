extends Window

var text : String : set = setString

signal closeWindowSignal



func _on_close_requested() -> void:
	visible = false
	emit_signal("closeWindowSignal",$TextEdit,title)

func setString(str):
	$TextEdit.text = str
