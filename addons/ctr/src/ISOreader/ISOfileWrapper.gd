extends Node
class_name ISOFileWrapper

var file : FileAccess
var binByteArray : PackedByteArray
#var binFile : FileAccess
var binMode : BIN_MODE= BIN_MODE.NONE
var curPos = 0

var big_endian = false
var binFilePath = ""

const SECTOR_SIZE = 2352
const USER_DATA_OFFSET = 24  # 12(sync) + 4(header) + 8(subheader)
const USER_DATA_SIZE = 2048

enum BIN_MODE{
	NONE,
	BUFFER,
	DISK
}

func seek(pos : int) -> void: 
	if binMode == BIN_MODE.BUFFER:
		curPos = pos
		return
	
	if binMode == BIN_MODE.DISK:
		# pos is logical user-data position
		curPos = pos
		return
	
	file.seek(pos)



func get_buffer(size : int) -> PackedByteArray:
	if binMode == BIN_MODE.BUFFER:
		var buffer : PackedByteArray = binByteArray.slice(curPos,curPos+size)
		curPos+=size
		return buffer
	
	if binMode == BIN_MODE.DISK:
		var result = PackedByteArray()
		var remaining = size
		
		var sector = curPos / USER_DATA_SIZE
		var offset_in_sector = curPos % USER_DATA_SIZE
		var file_offset = sector * SECTOR_SIZE + USER_DATA_OFFSET + offset_in_sector
		
		
		while remaining > 0:
			sector = curPos / USER_DATA_SIZE
			offset_in_sector = curPos % USER_DATA_SIZE
			file_offset = sector * SECTOR_SIZE + USER_DATA_OFFSET + offset_in_sector
			
			# Figure out how many bytes we can read from this sector
			var chunk_size = min(USER_DATA_SIZE - offset_in_sector, remaining)

			# Safety check
			if file_offset + chunk_size > file.get_length():
				break  # EOF
			
			file.seek(file_offset)
			var chunk = file.get_buffer(chunk_size)
			result.append_array(chunk)
			
			curPos += chunk_size
			remaining -= chunk_size
			
			if chunk.size() < chunk_size:
				break  # EOF or incomplete read
		
		return result
	
	return file.get_buffer(size)

func get_path():
	if binMode == BIN_MODE.BUFFER:
		return binFilePath
	
	if binMode == BIN_MODE.DISK:
		return file.get_path()
	
	return file.get_path()
	

func get_8() -> int:
	if binMode == BIN_MODE.BUFFER:
		var ret : int = binByteArray[curPos]
		curPos += 1
		return ret
	
	if binMode == BIN_MODE.DISK:
		var bytes = get_buffer(1)
		if bytes.size() < 1:
			push_error("End of file reached while reading get_8")
			return 0
		return bytes[0]
	
	return file.get_8()


func get_16() -> int:
	if binMode == BIN_MODE.BUFFER:
		var b1 = binByteArray[curPos]
		var b2 = binByteArray[curPos + 1]
		curPos += 2
		return b1 | (b2 << 8)

	if binMode == BIN_MODE.DISK:
		var bytes = get_buffer(2)
		if bytes.size() < 2:
			push_error("Not enough data to read 16-bit int")
			return 0
		return bytes[0] | (bytes[1] << 8)

	return file.get_16()

func get_32() -> int:
	if binMode == BIN_MODE.BUFFER:
		var b1 = binByteArray[curPos]
		var b2 = binByteArray[curPos + 1]
		var b3 = binByteArray[curPos + 2]
		var b4 = binByteArray[curPos + 3]
		curPos += 4
		return b1 | (b2 << 8) | (b3 << 16) | (b4 << 24)
	
	if binMode == BIN_MODE.DISK:
		var bytes = get_buffer(4)
		if bytes.size() < 4:
			push_error("Not enough data to read 32-bit int")
			return 0
		return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24)
	
	return file.get_32()

func get_position() -> int:
	if binMode == BIN_MODE.BUFFER:
		return curPos
	
	if binMode == BIN_MODE.DISK:
		return curPos
	
	return file.get_position()

func store_buffer(data: PackedByteArray) -> void:
	if binMode == BIN_MODE.BUFFER:
		for i in data.size():
			binByteArray[curPos + i] = data[i]
		curPos += data.size()
		return
	
	if binMode == BIN_MODE.DISK:
		var size = data.size()
		var written = 0
		
		while written < size:
			var sector = curPos / USER_DATA_SIZE
			var offset_in_sector = curPos % USER_DATA_SIZE
			var file_offset = sector * SECTOR_SIZE + USER_DATA_OFFSET + offset_in_sector
			
			var writable = min(USER_DATA_SIZE - offset_in_sector, size - written)
			var chunk = data.slice(written, written + writable)
			
			file.seek(file_offset)
			file.store_buffer(chunk)
			
			written += writable
			curPos += writable
		return
	
	file.store_buffer(data)
	
