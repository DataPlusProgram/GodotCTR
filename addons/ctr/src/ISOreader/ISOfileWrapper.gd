extends Node
class_name ISOFileWrapper

var file : FileAccess
var binFile : PackedByteArray
var binMode := false
var curPos = 0

var big_endian = false

func seek(pos : int) -> void: 
	if binMode:
		curPos = pos
		return
	
	file.seek(pos)

func get_buffer(size : int) -> PackedByteArray:
	if binMode:
		var buffer : PackedByteArray = binFile.slice(curPos,curPos+size)
		curPos+=size
		return buffer
	
	return file.get_buffer(size)

func get_8():
	if binMode:
		var ret : int = binFile[curPos]
		curPos += 1
		return
	else:
		return file.get_8()


func get_16() -> int:
	if binMode:
		var b1 = binFile[curPos]
		var b2 = binFile[curPos + 1]
		curPos += 2
		return (b1 << 8) | b2
	else:
		return file.get_16()

func get_32() -> int:
	if binMode:
		var b1 = binFile[curPos]
		var b2 = binFile[curPos + 1]
		var b3 = binFile[curPos + 2]
		var b4 = binFile[curPos + 3]
		curPos += 4
		return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
	else:
		return file.get_32()

func get_position() -> int:
	if binMode:
		return curPos
		
	return file.get_position()
