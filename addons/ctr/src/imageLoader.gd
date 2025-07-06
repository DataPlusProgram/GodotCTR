@tool
extends Node

@onready var parent = get_parent()
@onready var entriesOffsets = parent.entriesOffsets
@onready var entriesSizes = parent.entriesSizes
@onready var textureFiles = parent.textureFiles
@onready var iso : ISO = parent.iso
@onready var vram : PackedByteArray
@onready var textureLayoutsDict = parent.textureLayoutsDict
#func createVRM(file: FileAccess,index : int):


var dummyClut := [
	Color(1.0, 0.0, 0.0, 0.0),      # red
	Color(0, 1, 0),      # green
	Color(0, 0, 1),      # blue
	Color(1, 1, 0),      # yellow
	Color(1, 0, 1),      # magenta
	Color(0, 1, 1),      # cyan
	Color(1, 0.5, 0),    # orange
	Color(0.5, 0.25, 0), # brown
	Color(0.5, 0.5, 0.5),# gray
	Color(1, 1, 1),      # white
	Color(0.25, 0.25, 0.25), # dark gray
	Color(0.75, 0.75, 0.75), # light gray
	Color(0.5, 0, 0.5),  # purple
	Color(0, 0.5, 0.5),  # teal
	Color(0.5, 0.5, 0),  # olive
	Color(0, 0, 0)       # black
]



func _ready() -> void:
	vram.resize(1024*512*2)#each pixel is 2 bytes
	print("vram size:",vram.size())#the vram dim will commonly be refered to as 1024x512 but that is at 2 bytes per pixel, 2048x512 is more true to the byte array format


func blankVram():
	vram.fill(0)

func getBytesAtCoords(x,y,numBytes):
	var index = (y*1024)+x
	return vram.slice(index,index+numBytes)
	
	

func createVRM(textureName : String):
	
	
	var rootOffset = parent.bigfileRootOffset
	
	var textureInfo = textureFiles[textureName]
	var textureSize = textureInfo[0]
	var textureOffset = textureInfo[1]
	
	iso.ISOfile.seek((textureOffset * 2048) + rootOffset )
	
	
	var t = Time.get_ticks_msec()
	
	var data = iso.ISOfile.get_buffer(textureSize)
	var img = parseVRM2(data)
	
	#img.save_png("res://test.png")
	#print(Time.get_ticks_msec() - t)
	return  img


func getVRMdata(data : PackedByteArray) -> Array[Dictionary]:
	
	var rootOffset = parent.bigfileRootOffset
	
	
	
	var data2 = StreamPeerBuffer.new()
	
	data2.put_data(data)
	data2.seek(0)
	
	var magic = data2.get_32()
	var timData : Array[Dictionary]= []
	
	if magic == 0x20:
		for i in range(2):
			
			var size := data2.get_32()
			var tim_data = data2.get_data(size)[1]
			
			timData.append( getTimData(tim_data))
	else:
		data2.seek(0)
		timData.append(getTimData(data))
		
	return timData

func parseVRM2(d: PackedByteArray):
	var data = StreamPeerBuffer.new()
	
	data.put_data(d)
	data.seek(0)
	
	var magic = data.get_32()
	var timData : Array= []
	
	if magic == 0x20:
		for i in range(2):
			
			var size := data.get_32()
			var tim_data = data.get_data(size)[1]
			
			timData.append( getTimData(tim_data))
	else:
		data.seek(0)
		timData.append(getTimData(d))
	
	var pixelData : Array[PackedColorArray]
	
	for i in timData:
		pixelData.append(getTimPixels(i["imageData"],i["dim"],i["bpp"],i["clut"]))
		
		
	var totalImage := Image.create_empty(1024, 512, false, Image.FORMAT_RGBA8)
	
	for i in timData.size():
		var tim = timData[i]
		var vramPos : Vector2i = tim["vramPos"]
		var colorData = pixelData[i]
		
		var w = tim["dim"].x
		var h = tim["dim"].y
		
		for y in h:
			for x in w:
				totalImage.set_pixel(x+vramPos.x, y+vramPos.y, colorData[(y*w)+x])
		
		
		
	return totalImage



func getTimPixels(tim : PackedByteArray,dim : Vector2i,bpp : int,clut : PackedColorArray = []) -> PackedColorArray:
	
	var pixelIndex:= 0
	var pixelData : PackedColorArray = []
	
	var data = StreamPeerBuffer.new()
	data.put_data(tim)
	data.seek(0)
	
	var timeSize = tim.size()
	

	if bpp == 0: dim.x *= 4# 4-bit
	if bpp == 1: dim.x *= 2# 8-bit
	if bpp == 2: dim.x *= 1# 16-bit

	if bpp == 0: pixelData.resize(dim.x*dim.y)
	if bpp == 1: pixelData.resize(dim.x*dim.y)
	if bpp == 2: pixelData.resize(dim.x*dim.y)
	
	
	var w := dim.x
	var h := dim.y
	
	var temp_colors
	
	for y in h:
		for x in w:
			var color : Color
			
			if bpp == 0:
				if x % 2 == 0:
					var byte = data.get_8()
					var palette_index1 = byte & 0x0F
					var palette_index2 = (byte >> 4) & 0x0F
					temp_colors = [clut[palette_index1], clut[palette_index2]]

				color = temp_colors[x % 2]
				pixelData[(y * w) + x] = color


			if bpp == 1:  # 8-bit (2 pixels per u16)
				color = clut[data.get_u8()]
				pixelData[(y*w)+x] = color
				
			if bpp == 2:  # 16-bit direct color
				var val = data.get_16()
				color = convert_5551_to_rgb(val)
		
				pixelData[(y*w)+x] = (color)

	var t = pixelData[0]
	return pixelData


func getTimData(dat : PackedByteArray,loadIntoVRAM : bool= false) -> Dictionary:
	var data = StreamPeerBuffer.new()
	data.put_data(dat)
	data.seek(0)
	
	var magic = data.get_32()
	var flags = data.get_32()
	var bpp = flags & 0b11
	var hasCLUT = (flags >> 3) & 1
	
	var clut : PackedColorArray = []
	
	if hasCLUT:
		var clut_len = data.get_u32()
		var clut_x = data.get_u16()
		var clut_y = data.get_u16()
		var clut_width = data.get_u16()
		var clut_height = data.get_u16()
		
		
		clut.resize(clut_width * clut_height)
		
		for i in clut_width * clut_height:
			var color = data.get_u16()#glut always 2 byte
			clut[i] = convert_5551_to_rgb(color)
		
	
	var image_len = data.get_u32()
	var vramX = data.get_u16()
	var vramY = data.get_u16()
	var w = data.get_u16()
	var h = data.get_u16()
	
	
	var t = timByteCountFromW(w,bpp)*h
	var image_data : PackedByteArray= []
	image_data.resize(t)
	
	for i in image_data.size():
		image_data[i] = data.get_8() 
		
	
	copyImageToVram16(image_data,Vector2i(vramX,vramY),Vector2i(w,h))
	#for y in h:
	#	for x in w:
	#		var byte = dat[(y*w)+x]
	#		vram[((1024*y) + vramY) + vramX+x] = dat[(y*w)+x]
	
	return {"clut":clut,"imageData":image_data,"dim":Vector2i(w,h),"bpp":bpp,"vramPos":Vector2i(vramX,vramY)}

func copyImageToVram16(dat: PackedByteArray,vramPos : Vector2, dim : Vector2):
	var vramWidth = 1024
	var imgWidth = int(dim.x)
	var imgHeight = int(dim.y)
	var offsetX = int(vramPos.x)
	var offsetY = int(vramPos.y)

	for y in range(imgHeight):
		for x in range(imgWidth):
			var srcIndex = ((y * imgWidth) + x) * 2
			var dstX = offsetX + x
			var dstY = offsetY + y

			# Bounds check to prevent overflow
			if dstX >= vramWidth or dstY >= 512:
				continue

			var dstIndex = ((dstY * vramWidth) + dstX) * 2
			vram[dstIndex] = dat[srcIndex]
			vram[dstIndex + 1] = dat[srcIndex + 1]

func timDataToImage( timData : Dictionary , externalClut : PackedColorArray = []):
	var data  : PackedByteArray= timData["imageData"]
	var bpp : int = timData["bpp"]
	var dim = timData["dim"]
	var clut : PackedColorArray = timData["clut"]
	
	if clut.is_empty() and !externalClut.is_empty():
		clut = externalClut
	
	
	var pixels : PackedColorArray = getTimPixels(data,timData["dim"],bpp,clut)
	
	var image = Image.create_empty(dim.x,dim.y,false,Image.FORMAT_RGBA8)
	
	for y in dim.y:
			for x in dim.x:
				image.set_pixel(x,y,pixels[(y*dim.x)+x])
			
	

	return image
	breakpoint

func geVRamImage() -> Image:
	var width = 1024
	var height = 512
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var i = 0
	for y in height:
		for x in width:
			if i + 1 >= vram.size():
				break
			var low = vram[i]
			var high = vram[i + 1]
			var pixelValue = (high << 8) | low
			var color = convert_5551_to_rgb(pixelValue)
			#if pixelValue != 0:
			#	breakpoint
			image.set_pixel(x, y, color)
			i += 2
	
	
	drawPageGridOnImage(image)
	image.save_png("res://vram.png")
	return image
	
	
func drawPageGridOnImage(image: Image) -> void:
	var width = image.get_width()
	var height = image.get_height()
	var lineColor = Color(1, 0, 0, 1) # Red lines

	# Draw vertical lines every 64 pixels
	for x in range(0, width, 64):
		for y in range(height):
			image.set_pixel(x, y, lineColor)

	# Draw horizontal lines every 256 pixels
	for y in range(0, height, 256):
		for x in range(width):
			image.set_pixel(x, y, lineColor)

	


func timByteCountFromW(w : int,bpp):
	match bpp:
		0:  # 4-bit
			return  w
		1:  # 8-bit
			return  w * 4
		2:  # 16-bit
			return  w  * 8# each framebuffer pixel is one pixel here

	return w

func parseTimAndCreateImage(dat : PackedByteArray) -> Array:
	
	var data = StreamPeerBuffer.new()
	data.put_data(dat)
	data.seek(0)
	
	var magic = data.get_32()
	var flags = data.get_32()
	var bpp = flags & 0b11
	var hasCLUT = (flags >> 3) & 1
	
	var clut = []
	
	if hasCLUT:
		var clut_len = data.get_u32()
		var clut_x = data.get_u16()
		var clut_y = data.get_u16()
		var clut_width = data.get_u16()
		var clut_height = data.get_u16()
		
		
		clut.resize(clut_width * clut_height)
		
		for i in clut_width * clut_height:
			var color = data.get_u16()#glut always 2 byte
			clut[i] = convert_5551_to_rgb(color)
		
	
	var image_len = data.get_u32()
	var img_x = data.get_u16()
	var img_y = data.get_u16()
	var w = data.get_u16()
	var h = data.get_u16()
	
	var real_width = w
	match bpp:
		0:  # 4-bit
			real_width = w * 4
		1:  # 8-bit
			real_width = w * 2
		2:  # 16-bit
			real_width = w  # each framebuffer pixel is one pixel here
		_:
			real_width = w  # fallback

	w = real_width
	
	var image_data : PackedInt32Array= []
	var pixelDataCount  = 0
	
	if bpp == 0: pixelDataCount = (w * h) / 4
	if bpp == 1: pixelDataCount = (w * h) / 2
	if bpp == 2: pixelDataCount = (w * h)
	
	image_data.resize(pixelDataCount)
	
	for i in pixelDataCount:
		image_data[i] = data.get_u16()  # Format depends on BPP
	
	#might need to split function here for threading
	var image = Image.create_empty(w,h,false,Image.FORMAT_RGBA8)
	
	var pixel_index = 0
	var color : Color
	
	for y in h:
		for x in w:
			
			match bpp:
				0:  # 4-bit (4 pixels per u16)
					var word_index = pixel_index / 4
					var shift = (pixel_index % 4) * 4
					var word = image_data[word_index]
					var palette_index = (word >> shift) & 0xF
					color = clut[palette_index]

				1:  # 8-bit (2 pixels per u16)
					var word_index = pixel_index / 2
					var shift = (pixel_index % 2) * 8
					var word = image_data[word_index]
					var palette_index = (word >> shift) & 0xFF
					color = clut[palette_index]

				2:  # 16-bit direct color
					var val = image_data[pixel_index]
					color = convert_5551_to_rgb(val)
					

				_:  # Unsupported (24-bit or other)
					color = Color(1, 0, 1)  # Magenta error

			image.set_pixel(x, y, color)
			pixel_index += 1 
	
	return [image,Vector2(img_x,img_y)]




func pixelColorsToImage(pixelColors : PackedColorArray,bpp):
	pass

func combineTims(tims : Array):
	var alphaColor = Color.BLACK
	var totalImage := Image.create_empty(1024, 512, false, Image.FORMAT_RGBA8)
	
	for tim in tims:
		var image : Image = tim[0]
		var pos : Vector2 = tim[1] 
		#'pos.x -= 512
		
		for x in image.get_width():
			for y in image.get_height():
				var color = image.get_pixel(x, y)
				if color != alphaColor:
					totalImage.set_pixelv(pos + Vector2(x, y), color)
				
	
	
	return totalImage
	

var cachedColorInt : int = -1
var cachedColor : Color = Color.REBECCA_PURPLE

func parseTextureLayout(data: StreamPeerBuffer):
	var uv : PackedVector2Array = []
	uv.append(Vector2(data.get_u8(),data.get_u8()))
	
	var buf = data.get_u16()
	var pallete = Vector2i(buf & 0x3F, buf >> 6)
	uv.append(Vector2i(data.get_u8(),data.get_u8()))
	
	buf = data.get_u16()
	var page = Vector2i(buf & 0xF, (buf >> 4) & 1)
	var blendingMode = ((buf >> 5) & 3)
	var bpp = ((buf >> 7) & 3)
	var rest = ((buf >> 9) & 0x7F) % 255
	uv.append(Vector2i(data.get_u8(),data.get_u8()))
	uv.append(Vector2i(data.get_u8(),data.get_u8()))
	
	var uvMin = Vector2.INF
	var uvMax = -Vector2.INF
	
	for vee in uv:
		if vee.x < uvMin.x : uvMin.x = vee.x
		if vee.y < uvMin.y : uvMin.y = vee.y
		
		if vee.x > uvMax.x : uvMax.x = vee.x
		if vee.y > uvMax.y : uvMax.y = vee.y
	

	
	var width =  ((uvMax.x - uvMin.x) / 1 + 1)
	
	if bpp == 0: width = int((uvMax.x - uvMin.x) / 4 + 1)
	if bpp == 1: width = int((uvMax.x - uvMin.x) / 2 + 1)
	
	var height = int((uvMax -uvMin).y) + 1
	
	
	var dict =  {"offset":data.get_position(),"uv":uv,"pallete":pallete,"page":page,"blendingMode":blendingMode,"bpp":bpp,"rest":rest,"dim":Vector2i(width,height),"tlUV" :uvMin}
	
	dict["normUV"] = normalizeUV(uv)
	
	return dict

func createPalleteFromOffset(palStartOffset,bpp = 0):
	var paletteBytes = []
	
	if bpp == 0:
		paletteBytes.resize(16)
		for i in 16:
			var low = vram[palStartOffset + i * 2]
			var high = vram[palStartOffset + i * 2 + 1]
			var short = low | (high << 8)
			paletteBytes[i] = short 
	
	elif bpp == 1:
		paletteBytes.resize(256)
		for i in 256:
			var low = vram[palStartOffset + i * 2]
			var high = vram[palStartOffset + i * 2 + 1]
			var short = low | (high << 8)
			paletteBytes[i] = short 
		
	return paletteBytes
	
	
func readPalleteFromTextureLayout(textureLayout:Dictionary):
	var palStartOffset = textureLayout["pallete"].y*2048 + textureLayout["pallete"].x*32
	var paletteBytes = createPalleteFromOffset(palStartOffset,textureLayout["bpp"])
	var paletteColors = []
	paletteColors.resize(paletteBytes.size())
	
	for p in paletteBytes.size():
		paletteColors[p] = convert_5551_to_rgb(paletteBytes[p])
		
	return paletteColors
	
func textureLayoutToImage(textureLayout : Dictionary,paletteCache := {},textureCache := {}):

	var palKey := str(textureLayout["pallete"])+str(textureLayout["page"])
	if !paletteCache.has(palKey):
		var paletteColors = readPalleteFromTextureLayout(textureLayout)
		paletteCache[palKey] = paletteColors
				
		
	var key = str(textureLayout["pallete"]) + str(textureLayout["page"]) + str(textureLayout["dim"]) + str(textureLayout["tlUV"])
	if !textureCache.has(key):
		var image = textureLayoutToImageInner(textureLayout,paletteCache)
		
		textureCache[key]  =image
				
	textureLayout["image"] = textureCache[key]
		
	return textureCache[key]

func textureLayoutToImageInner(textureLayout,paletteCache = {}):
	
	var bpp = textureLayout["bpp"]
	var pageCoord : Vector2i = textureLayout["page"]
	var topLeft = textureLayout["tlUV"]
	var dim = textureLayout["dim"]
	var xStartPixel = (pageCoord.x * 128) + (topLeft.x/2)#uv 255 is page pixel width which is 128
	
	if bpp == 1:
		xStartPixel = (pageCoord.x * 128) + (topLeft.x)
	
	var yStartPixel = (pageCoord.y * 256) + topLeft.y
	var palPos = textureLayout["pallete"]
	
	
	var texture  = []
	texture.resize(dim.x*dim.y*2)
	
	var sourceStartOffset =  ((yStartPixel*2048)+xStartPixel)/2#1 byte per pixel>
	var vram = vram
	
	if bpp == 1:
		sourceStartOffset += 0
	#2048x512 
	for y in dim.y:
		for x in dim.x:
			var word_index = sourceStartOffset + (y * 1024) + x#this is offset in vram of texture
			var byte_index = (y * dim.x + x) * 2

			var low = vram[word_index * 2]#its twice of what it is since we're in bytes
			var high = vram[word_index * 2 + 1]

			texture[byte_index] = low
			texture[byte_index + 1] = high

	
	var palStartOffset = palPos.y*2048 + palPos.x*32
	var palKey = str(textureLayout["pallete"])+str(textureLayout["page"])
	
	if !paletteCache.has(palKey):
		if bpp != 2:
			paletteCache[palKey] = readPalleteFromTextureLayout(textureLayout)
		
	var palatteColors = paletteCache[palKey]
	
	
	var image : Image
	
	if bpp == 0:
		image = Image.create_empty(dim.x*4,dim.y,false,Image.FORMAT_RGBA8)
	elif bpp == 1:
		image = Image.create_empty(dim.x*2,dim.y,false,Image.FORMAT_RGBA8)
	else:
		image = Image.create_empty(dim.x,dim.y,false,Image.FORMAT_RGBA8)
	
	var pixels = []

	if bpp != 2:
		for y in dim.y:
			for x in dim.x * 2:  # each byte has 2 pixels
				if bpp == 0:
					var byte = texture[(y*dim.x*2)+x]
					image.set_pixel(x*2,y,palatteColors[byte & 0b00001111])
					image.set_pixel((x*2) + 1,y,palatteColors[byte >> 4])
				
				if bpp == 1:
					var index = (y * dim.x * 2) + x
					var byte = texture[index]
					image.set_pixel(x, y, palatteColors[byte])
			
	else:
		for y in dim.y:
			for x in dim.x:
					var index = (y * dim.x + x) * 2
					var low = texture[index]
					var high = texture[index + 1]
					var word = low | (high << 8)
					var color = convert_5551_to_rgb(word)
					image.set_pixel(x, y, color)
				
		
	
	return image


func convert_4bpp_pixels(input_array):
	var pixels = []
	for value in input_array:
		var byte1 = (value >> 8) & 0xFF
		var byte2 = value & 0xFF

		
		pixels.append(byte2 & 0xF)
		pixels.append((byte2 >> 4))
		
		pixels.append(byte1 & 0xF)
		pixels.append((byte1 >> 4))
		
	
	return pixels

func convert_5551_to_rgb(val: int) -> Color:
	
	var r = float((val >> 0) & 0x1F) / 31.0
	var g = float((val >> 5) & 0x1F) / 31.0
	var b = float((val >> 10) & 0x1F) / 31.0
	var a = float((val >> 15) & 0x01)


	if r == 0 and g == 0 and b == 0 and a == 0:
		return Color.TRANSPARENT
	
	
	#cachedColor = Color(r,g,b,1)

	return Color(r,g,b,1)

func fetchTexture( textureName : String):
	
	if !textureLayoutsDict.has(textureName):
		return null
	
	return textureLayoutToImageInner(textureLayoutsDict[textureName])
	

var wheelsCached = []

func getWheelSprites() -> Array[Image]:
	var ret : Array[Image]
	
	
	if !parent.textureLayoutsDict.has(("tire" + str(0)).pad_zeros(2)):
		return []
	
	for i in 17:
		var str = ("tire" + str(i)).pad_zeros(2)
		ret.append(textureLayoutToImageInner(parent.textureLayoutsDict[str]))

	
	return ret
		

func normalizeUV(uvs):
	var normuv : PackedVector2Array = []
	
	var uvMin = Vector2.INF
	var uvMax = -Vector2.INF
	
	for uv in uvs:
		if uv.x < uvMin.x : uvMin.x = uv.x
		if uv.y < uvMin.y : uvMin.y = uv.y
		
		if uv.x > uvMax.x : uvMax.x = uv.x
		if uv.y > uvMax.y : uvMax.y = uv.y
	
	for i in 4:
		
		var x = ((uvs[i].x - uvMin.x) / (uvMax.x - uvMin.x))  * 255
		var y = ((uvs[i].y - uvMin.y) / (uvMax.y - uvMin.y))  * 255
		
		x = clamp(int(x), 0, 255)
		y = clamp(int(y),0,255)
		
		normuv.append(Vector2(x,y))
	
		
		
	return normuv
	
