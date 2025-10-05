extends Node


enum secondaryCompressor {
	DJW = 1,
	LZMA = 2,
	FGK = 16,
}

func parse(path : String):
	
	var file : FileAccess = FileAccess.open(path,FileAccess.READ)
	
	var header = file.get_buffer(4)
	var headerIndicator = file.get_8()
	
	
	var hasCustomTable = (headerIndicator & 0x01) != 0
	var hasAppHeader   = (headerIndicator & 0x02) != 0
	var hasComp        = (headerIndicator & 0x04) != 0
	
	if hasComp:
		var secondaryCompressorId = file.get_8()
		pass
 
