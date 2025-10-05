@tool
class_name ISO
extends Node


var ISOfile : ISOFileWrapper = ISOFileWrapper.new()
var files : Dictionary[String,Array] = {}
var directory : Dictionary = {}
var fileEntries = {}
var binMode = false
var mutex : Mutex = Mutex.new()
var volumeIdOffset := -1
@onready var binLoader = $BinReader
@onready var binData :PackedByteArray = binLoader.sectorDataArray



enum FileFlags{
	HIDDEN = 1 << 0,
	DIR = 1 << 1,
	FILE = 1 << 2,
	FILEX = 1 << 3,
	GOUP_PERMISSION = 1 << 4,
	RESERVED1 = 1 << 5,
	RESERVED2 = 1 << 6,
	NOT_FINAL_DIR = 1 << 7
}

class PathTableEntry:
	var nameStr: StringName
	var offset: int
	var parent_index: int


class FileEntry:
	var offset : int
	var size : int


func initialize(path : StringName):
	
	
	
	print("opening bin:",path)
	
	
	if path.get_extension() == "bin":
		#ISOfile.binMode = ISOfile.BIN_MODE.BUFFER
		#ISOfile.binFilePath = path
		#$"BinReader".getBinData(path)
		#SOfile.binByteArray = binLoader.sectorDataArray
		
		
		ISOfile.binMode = ISOfile.BIN_MODE.DISK
		ISOfile.file = FileAccess.open(path,FileAccess.READ_WRITE)
		
	else:
		ISOfile.BIN_MODE.NONE

		ISOfile.file =  FileAccess.open(path,FileAccess.READ_WRITE)
		
		
	var err = FileAccess.get_open_error()
	
	if err != 0:
		print_debug("Couldn't open iso file error:",err)
		EGLO.showMessage(get_tree().get_root(),"Could not open file. Another program may be using it.")
		return []
	
	ISOfile.seek(0x8000)
	
	var info = parsePrimaryVolumeDescriptor(ISOfile)
	
	
	ISOfile.seek(info["pathTableOffset"])
	

	var pteArr := parsePathTable(ISOfile,info["pathTableSize"],info["blockSize"])
	var dirToEntry : Dictionary[String,PathTableEntry] = createDirDict(ISOfile,pteArr)
	
	
	dirToEntry["/"] = pteArr[0]
	
	var isoDirectoryStucture = {}
	var fileList : Dictionary[String,Array]= {}
	
	addFilesToDir(ISOfile,isoDirectoryStucture,"/",dirToEntry,fileList)
	
	for dir in dirToEntry:
		var curDir = isoDirectoryStucture
		var runningStr : String = ""
		

		for subDir in dir.split("/",false):
			
			runningStr += "/" + subDir
			
			if !curDir.has(subDir):
				curDir[subDir] = {}
				addFilesToDir(ISOfile,curDir[subDir],runningStr,dirToEntry,fileList)
			
			
			curDir = curDir[subDir]
	
	
	
	files = fileList
	directory = isoDirectoryStucture
	#ISOfile.file = file
	fileEntries = fileList
	return [fileList,isoDirectoryStucture]

func close():
	if ISOfile.file != null:
		ISOfile.file.close()
	files  = {}
	directory = {}
	fileEntries = {}
	binMode = false


func getDataAtPosition(pos : int,numBytes : int) -> PackedByteArray:
	mutex.lock()
	ISOfile.seek(pos)
	var data : PackedByteArray = ISOfile.get_buffer(numBytes)
	mutex.unlock()
	return data

func getFileData(path : String) -> PackedByteArray:
	var entry := files[path]
	ISOfile.seek(entry[1])
	var data := ISOfile.get_buffer(entry[0])
	return data

func seekToFileAndReturnSize(path:String) -> int:
	
	if !files.has(path):
		print_debug("file not found in iso: %s"%[path])
		return -1
	
	var entry := files[path]
	ISOfile.seek(entry[1])
	return entry[0]
	

func parsePrimaryVolumeDescriptor(file : ISOFileWrapper):
	
	var retDict : Dictionary[StringName,Variant]
	
	var decriptorType = file.get_8()
	var standard = file.get_buffer(5).get_string_from_ascii()
	var descriptorVersion = file.get_8()
	file.get_8()#unused
	var systemName = file.get_buffer(32).get_string_from_ascii()
	volumeIdOffset = file.get_position()
	var volumeId = file.get_buffer(32).get_string_from_ascii()
	file.get_buffer(8)
	var volumeSpaceSizeLSB = file.get_32()
	var volumeSpaceSizeMSB = file.get_32()
	file.get_buffer(32)
	var volumeSetSizeLSB = file.get_16()
	var volumeSetSizeMSB = file.get_16()
	
	var volumeSequenceNumberLSB = file.get_16()
	var volumeSequenceNumberMSB = file.get_16()
	var logicalBlockSizeLSB = file.get_16()
	var logicalBlockSizeMSB = file.get_16()
	var pathTableSizeLSB = file.get_32()
	var pathTableSizeMSB = file.get_32()
	var locationOfPathTable = file.get_32()#little endian (pc)
	var locationOfOptionalPathTable = file.get_32()
	
	#file.big_endian = true
	#var locationOfPathTableM_LSB = file.get_32()#big endian (psx)
	#var locationOfOptionalPathTableM = file.get_32()
	#file.big_endian = false
	
	
	var ret = parseDirectory2(file,34)
	
	
	retDict["pathTableOffset"] = locationOfPathTable * logicalBlockSizeLSB
	retDict["pathTableSize"] = pathTableSizeLSB
	retDict["blockSize"] = logicalBlockSizeLSB
	return retDict
	
	

#func parseDirectory(file : FileAccess):
	#
	#
	##var t = file.get_position()
	#var initialPos = file.get_position()
	#var length = file.get_8()
	#var extendedAtributeRecordLength = file.get_8()
	#var locationOfExtentLSB = file.get_32()
	#var locationOfExtentMSB = file.get_32()
	#var dataLengthLSB = file.get_32()
	#var dataLengthMSB = file.get_32()
	#
	#var year = file.get_8()
	#var month = file.get_8()
	#var day = file.get_8()
	#var hour = file.get_8()
	#var minute = file.get_8()
	#var second = file.get_8()
	#var timeZone = file.get_8()
	#
	#var fileFlags = file.get_8()
	#var fileUnitSize = file.get_8()
	#var interleaveGapSize = file.get_8()
	#var volumeSequenceNumber = file.get_32()
	#var lengthOfFilename = file.get_8()
	#
	##var b = file.get_8()
	#
	#var fileName = file.get_buffer(lengthOfFilename).get_string_from_ascii()
	#
	#
	#if lengthOfFilename % 2 != 0:
		#file.get_8()
	#
	#var t = file.get_position() - initialPos
	#return {"lba":locationOfExtentLSB*2048,"size":dataLengthLSB}
	
	

func parsePathTable(file : ISOFileWrapper,pathTableSize,blockSize : int) -> Array[PathTableEntry]:
	
	var arr : Array[PathTableEntry]= []
	var startPos = file.get_position()
	
	while file.get_position() - startPos < pathTableSize:
		var nameLength = file.get_8()
		var extendedAtributeLength = file.get_8()
		var LBA = file.get_32() * blockSize
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

func createDirDict(file : ISOFileWrapper,arr : Array[PathTableEntry]):
	
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
	

func getDirectorySize(file: ISOFileWrapper, offset: int) -> int:
	var initalPos = file.get_position()
	
	file.seek(offset)
	var length = file.get_8()
	if length == 0:
		file.seek(initalPos)
		return 0  # invalid

	file.get_8() # extended attribute length
	var extent_LBA = file.get_32()
	file.get_32() # MSB version of LBA
	var data_length = file.get_32()
	
	file.seek(initalPos)
	return data_length

func parseDirectory2(file : ISOFileWrapper,size : int):
	
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
		

		var fileName = file.get_buffer(lengthOfFilename).get_string_from_ascii()
		
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

	#return {"lba":locationOfExtentLSB*2048,"size":dataLengthLSB}
	
func addFilesToDir(file : ISOFileWrapper, dir : Dictionary,path : String,pathTableEntries : Dictionary[String,PathTableEntry],fileList):
	var tableEntry := pathTableEntries[path]
	
	
	var size = getDirectorySize(file,tableEntry.offset)
	file.seek(tableEntry.offset)
	
	var files = parseDirectory2(file,size)
	
	for f in files:
		dir[f] = files[f]
		
		if path != "/":
			fileList[(path + "/" + f).lstrip("/")] = [files[f].size,files[f].offset]
		else:
			fileList[(path + "/" + f).lstrip("/")] = [files[f].size,files[f].offset]
			
	return
