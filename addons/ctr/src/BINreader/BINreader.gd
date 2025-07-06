extends Node


var a = "res://CTR - Crash Team Racing (USA).bin"

var sectorDataArray : PackedByteArray = []
var sectorInfoArray : PackedByteArray = []
var sectorPostArray : PackedByteArray = []
var sectorSubheaderArray : PackedByteArray = []

class FileEntry:
	var offset : int
	var size : int
	
#func _ready() -> void:
	#getBinData("a")
	#breakpoint


class PathTableEntry:
	var nameStr: StringName
	var offset: int
	var parent_index: int


func getBinData(path:StringName):
	var file : FileAccess = FileAccess.open(path,FileAccess.READ)
	
	var error := file.get_error()
	
	if error !=0:
		breakpoint
	readAllSectors(file,sectorDataArray,sectorInfoArray,sectorPostArray, sectorSubheaderArray )
	
	

func initialize(path : StringName):
	var file : FileAccess = FileAccess.open(a,FileAccess.READ)
	#var sectors : Array[PackedByteArray] = []
	
	var allData : PackedByteArray = []
	var sectorHeaderData = []
	var orderedData : Dictionary[int,PackedByteArray]= {}
	
	var outFile : FileAccess = FileAccess.open("res://test.iso",FileAccess.WRITE)
	
	var err = FileAccess.get_open_error()
	
	if err != 0:
		breakpoint
	
	var count = 0
	
	var sectorArray : PackedByteArray = []
	var prevLba = 0
	var a= Time.get_ticks_msec()
	while !file.eof_reached():
		var ret = readSector(file)
		
		if ret.is_empty():
			continue
		
		var lba = ret[0]
		#if lba != prevLba:
		#	print(lba)
		
		prevLba = lba
		
		sectorArray.append_array(ret[1])
		continue
		if !orderedData.has(lba):#we just keep the original lba
			orderedData[lba] = ret[1]
		
		
			
		count +=1
	
	print("A Time:",Time.get_ticks_msec()-a)
	file.seek(0)
	
	
	a= Time.get_ticks_msec()
	
	
	
	var sectorDataArray : PackedByteArray = []
	var sectorInfoArray : PackedByteArray = []
	var sectorPostArray : PackedByteArray = []
	var sectorSubheaderArray : PackedByteArray = []
	
	var sectorDataArray2 : PackedByteArray = []
	var sectorInfoArray2 : PackedByteArray = []
	var sectorPostArray2 : PackedByteArray = []
	var sectorSubheaderArray2 : PackedByteArray = []
	
	
	#var data2 = StreamPeerBuffer.new()
	#data2.put_data(file.get_buffer(file.get_length()))
	#data2.seek(0)
	
	#readAllSectors(file,sectorDataArray,sectorInfoArray,sectorPostArray, sectorSubheaderArray )
	#var allBytes := file.get_buffer(file.get_length())
	#var total_sectors := allBytes.size() / 2352
	#var mid_sector := int(total_sectors / 2)
	#var mid_offset := mid_sector * 2352
#
	#var first_half := allBytes.slice(0, mid_offset)
	#var second_half := allBytes.slice(mid_offset, allBytes.size())
	#
	#var t1 = Thread.new()
	#var t2 = Thread.new()
	#
	#t1.start(readAllSectorsFromBytes.bind(first_half,sectorDataArray,sectorInfoArray,sectorPostArray,sectorSubheaderArray),Thread.PRIORITY_HIGH)
	#t2.start(readAllSectorsFromBytes.bind(second_half,sectorDataArray2,sectorInfoArray2,sectorPostArray2,sectorSubheaderArray2),Thread.PRIORITY_HIGH)
	#
	#t1.wait_to_finish()
	#t2.wait_to_finish()
	#readAllSectorsFromBytes(first_half,sectorDataArray,sectorInfoArray,sectorPostArray,sectorSubheaderArray)
	#readAllSectorsFromBytes(second_half,sectorDataArray2,sectorInfoArray2,sectorPostArray2,sectorSubheaderArray2)
	#
	#sectorDataArray.append_array(sectorDataArray2)
	#sectorInfoArray.append_array(sectorInfoArray2)
	#sectorPostArray.append_array(sectorPostArray2)
	#sectorSubheaderArray.append_array(sectorSubheaderArray2)
	
	readAllSectors(file,sectorDataArray,sectorInfoArray,sectorPostArray, sectorSubheaderArray )
	
	print("B Time:",Time.get_ticks_msec()-a)
	
	var binBytes := reconstructBin(sectorDataArray,sectorInfoArray,sectorPostArray,sectorSubheaderArray )
	var t = binBytes.size()
	var binFile = FileAccess.open("res://testBin.bin",FileAccess.WRITE)
	var binOpenErr = FileAccess.get_open_error()
	var binErr = binFile.store_buffer(binBytes)
	binFile.close()
	#outFile.store_buffer(sectorArray)
	#outFile.close()
	return
	#var info = parseVolumeDescriptor(sectorArray[16])
	
	#file.seek(info["pathTableOffset"]+16)
	
	#var pteArr := parsePathTable(file,info["pathTableSize"],info["blockSize"])
	#var dirToEntry : Dictionary[String,PathTableEntry] = createDirDict(file,pteArr)
	#for idx in orderedData.keys():
	
		#var data := orderedData[idx]
		#outFile.store_buffer(data)
	
	
	
	outFile.close()
	breakpoint

func reconstructBin(sectorDataArray: PackedByteArray ,sectorInfoArray: PackedByteArray ,sectorPostArray: PackedByteArray ,sectorSubheaderArray: PackedByteArray ) -> PackedByteArray:
	var numSectors = sectorDataArray.size() / 2048#form 2 would make this incorrect
	var bytes : PackedByteArray = []
	var curSector := 0
	
	for i in numSectors:
		var nextSector = curSector+1
		bytes.append_array(sectorInfoArray.slice(curSector*16,nextSector*16))
		bytes.append_array(sectorSubheaderArray.slice(curSector*8,nextSector*8))#not present if mode 1 
		bytes.append_array(sectorDataArray.slice(curSector*2048,nextSector*2048))
		bytes.append_array(sectorPostArray.slice(curSector*280,nextSector*280))
		
		curSector += 1
	
	return bytes

func readAllSectors(file : FileAccess,sectorDataArray : PackedByteArray,sectorInfoArray: PackedByteArray,sectorPostArray: PackedByteArray,sectorSubHeaderAray : PackedByteArray):
	
	var numSectors = file.get_length()/2352.0

	var curSecor = 0

	
	for i in numSectors:
		sectorInfoArray.append_array(file.get_buffer(16))
		
		if file.eof_reached():
			return
		
		
		var mode = sectorInfoArray[(curSecor*16)+15]
		
		curSecor += 1
		if mode == 2:
			
			var subheader = file.get_buffer(8)
			sectorSubHeaderAray.append_array(subheader)
			var t = file.eof_reached()
		
			var isForm2 : bool = ( subheader[3] & 0x20) != 0
			
			
			
			if !isForm2:
				sectorDataArray.append_array(file.get_buffer(2048)) # sector data
				sectorPostArray.append_array(file.get_buffer(280))
				continue
				
			else:
				sectorDataArray.append_array(file.get_buffer(2324)) 
				sectorPostArray.append_array(file.get_buffer(4))
				continue
			
		
		sectorSubHeaderAray.append_array([-1,-1,-1,-1,-1,-1,-1,-1])
		sectorDataArray.append_array(file.get_buffer(2048))
		sectorPostArray.append_array(file.get_buffer(288))




func readAllSectorsFromBytes(
	all_bytes: PackedByteArray,
	sectorDataArray: PackedByteArray,
	sectorInfoArray: PackedByteArray,
	sectorPostArray: PackedByteArray,
	sectorSubHeaderArray: PackedByteArray
):
	var sector_size := 2352
	var total_sectors := all_bytes.size() / sector_size

	for i in range(total_sectors):
		var offset := i * sector_size
		var sector := all_bytes.slice(offset, offset + sector_size)

		# First 16 bytes = sync (12) + header (4)
		var header := sector.slice(0, 16)
		sectorInfoArray.append_array(header)
		var mode := header[15]

		if mode == 2:
			# Next 8 bytes = subheader
			var subheader := sector.slice(16, 24)
			sectorSubHeaderArray.append_array(subheader)

			var isForm2 := (subheader[3] & 0x20) != 0

			if isForm2:
				var data := sector.slice(24, 24 + 2324)
				var post := sector.slice(2348, 2352)
				sectorDataArray.append_array(data)
				sectorPostArray.append_array(post)
			else:
				var data := sector.slice(24, 24 + 2048)
				var post := sector.slice(24 + 2048, 2352)
				sectorDataArray.append_array(data)
				sectorPostArray.append_array(post)

			
		else:
			# Mode 1 or unknown — no subheader
			sectorSubHeaderArray.append_array([ -1, -1, -1, -1, -1, -1, -1, -1 ])
			var data := sector.slice(16, 16 + 2048)
			var post := sector.slice(16 + 2048, 2352)

			sectorDataArray.append_array(data)
			sectorPostArray.append_array(post)
			
			
			
var sectorIdx =0
func readSector(file : FileAccess):
	#12 bytes of sync
	var syncStart = file.get_8()
	var syncBytes = file.get_buffer(10)
	var syncEnd = file.get_8()
	#4 bytes of mm:ss + frame + mode
	var mm = file.get_8()
	var ss = file.get_8()
	var frame = file.get_8()
	var mode = file.get_8()
	var lba = ((mm * 60) + ss) * 75 + frame - 150# lba is its index 
	
	
	
	
	if mode == 2:
		
		var subheader = file.get_buffer(8)
		var isForm2 : bool = ( subheader[3] & 0x20) != 0
		
		
		
		if !isForm2:
			var data = file.get_buffer(2048) # sector data
			file.get_buffer(280) # ecc
			return [lba,data]
			
		else:
			var data = file.get_buffer(2324)
			file.get_buffer(4)
			
			return [lba,data]
		
	
	var data = file.get_buffer(2048) # sector data
	file.get_buffer(288) # ecc
	#file.get_buffer(280) # ecc

	
	return [lba,data]
	
func parseVolumeDescriptor(d : PackedByteArray):#sector 16
	
	var data := StreamPeerBuffer.new()
	data.put_data(d)
	data.seek(0)
	
	#var magic = data.get_partial_data(6)[1].get_string_from_ascii()
	
	#if magic != "CD001":
	#	breakpoint
	var retDict : Dictionary[StringName,Variant]
	var decriptorType = data.get_8()
	var standard = data.get_partial_data(5)[1].get_string_from_ascii()
	var descriptorVersion = data.get_8()
	data.get_8()#unused
	var systemName = data.get_partial_data(32)[1].get_string_from_ascii()
	var volumeId = data.get_partial_data(32)[1].get_string_from_ascii()
	data.get_partial_data(8)
	
	var volumeSpaceSizeLSB = data.get_32()
	var volumeSpaceSizeMSB = data.get_32()
	data.get_partial_data(32)
	var volumeSetSizeLSB = data.get_16()
	var volumeSetSizeMSB = data.get_16()
	
	var volumeSequenceNumberLSB = data.get_16()
	var volumeSequenceNumberMSB = data.get_16()
	var logicalBlockSizeLSB = data.get_16()
	var logicalBlockSizeMSB = data.get_16()
	var pathTableSizeLSB = data.get_32()
	var pathTableSizeMSB = data.get_32()
	var locationOfPathTable = data.get_32()#little endian (pc)
	var locationOfOptionalPathTable = data.get_32()
	
	data.big_endian = true
	var locationOfPathTableM_LSB = data.get_32()#big endian (psx)
	var locationOfOptionalPathTableM = data.get_32()
	data.big_endian = false
	
	var ret = parseDirectory2(data,34)
	
	retDict["pathTableOffset"] = locationOfPathTable * 2352
	retDict["pathTableSize"] = pathTableSizeLSB
	retDict["blockSize"] = logicalBlockSizeLSB
	return retDict
	
	
func parseDirectory2(file : StreamPeerBuffer,size : int):
	
	var iniitalPos = file.get_position()
	var retDict : Dictionary[String,FileEntry]= {}
	while true:
		var initialPos = file.get_position()
		var length = file.get_8()
		
		if length == 0:
			return retDict
		
		var extendedAtributeRecordLength = file.get_8()
		var locationOfExtentLSB = file.get_32() * 2048
		var locationOfExtentMSB = file.get_32()
		var dataLengthLSB = file.get_32()
		var dataLengthMSB = file.get_32()
		
		var year = file.get_8()
		var month = file.get_8()
		var day = file.get_8()
		var hour = file.get_8()
		var minute = file.get_8()
		var second = file.get_8()
		var timeZone = file.get_8()
		
		var fileFlags = file.get_8()
		var fileUnitSize = file.get_8()
		var interleaveGapSize = file.get_8()
		var volumeSequenceNumberLSB = file.get_16()
		var volumeSequenceNumberMSB = file.get_16()
		var lengthOfFilename = file.get_8()
		
		#var b = file.get_8()
		
		
		
		
		var fileName = file.get_partial_data(lengthOfFilename)[1].get_string_from_ascii()
		
		if lengthOfFilename % 2 != 0:
			file.get_8()
		
		
		
		if (fileFlags & 0x02) == 0:
			var fe = FileEntry.new()
			fe.offset = locationOfExtentLSB
			fe.size = dataLengthLSB
			retDict[fileName.split(";")[0]] = fe
		
		file.seek(initialPos + length)
		var t = file.get_position() - initialPos
		if t == size:
			return retDict


func parsePathTable(file : FileAccess,pathTableSize,blockSize : int) -> Array[PathTableEntry]:
	
	var arr : Array[PathTableEntry]= []
	var startPos = file.get_position()
	
	while file.get_position() - startPos < pathTableSize:
		var nameLength = file.get_8()
		var extendedAtributeLength = file.get_8()
		var LBA = file.get_32() 
		var parDirNumber = file.get_16()
		var fName = file.get_buffer(nameLength).get_string_from_ascii()
		
		
		if nameLength % 2 != 0:
			file.get_8()
		
		
		var pte := PathTableEntry.new()
		
		pte.nameStr = fName
		pte.offset = LBA
		pte.parent_index = parDirNumber
		
		arr.append(pte)

	return arr


func createDirDict(file : FileAccess,arr : Array[PathTableEntry]):
	
	var dict :  Dictionary[String,PathTableEntry]= {}
	var allPaths : PackedStringArray = []
	var allPTE : Array[PathTableEntry] = []
	
	for i : PathTableEntry in arr:
		if i.nameStr.is_empty():
			continue
		
		var pathStr = i.nameStr
		var nextItt : PathTableEntry = i
		

		
		while(true):
			var parentIdx := nextItt.parent_index-1
			
			
			if !allPaths.has(pathStr):
				allPTE.append(nextItt)
				
			nextItt = arr[parentIdx]
			pathStr = nextItt.nameStr + "/" + pathStr
			
			if parentIdx == 0:
				break
			
		
		if !allPaths.has(pathStr):
			allPaths.append(pathStr)
			allPTE.append(i)
			dict[pathStr] = i
	
	return dict
	print("%x" % allPTE[0].offset)
