@tool
extends Node

@onready var parent = get_parent()
@onready var imageLoader = $"../imageLoader"
@onready var iso = $"../IsoReader"
@onready var modelFiles : Dictionary [String,Array]
@onready var textureFiles = parent.textureFiles
	

var center = Vector3.ZERO

class Delta:
	var position : Vector3i
	var bits : Vector3i

class SubModel:
	var subModelName: StringName
	var lodDistance: int
	var billboard: int
	var scale: Vector3

	var cmdOffset: int
	var frameOffset: int
	var textureOffset: int
	var clutOffset: int
	var numAnims: int
	var animsOffset: int



#var scaleFactor = 0.00390625
var scaleFactor = 0.001 

class Frame:
	var offset : int
	var verts



func _ready() -> void:

	modelFiles = parent.modelFiles



func loadSharedVRMInISO():
	
	if parent.cachedSharedVrmData == null:
		
		var textureInfo = textureFiles["bigfile/packs/shared.vrm"]
		var textureSize = textureInfo[0]
		var textureOffset = textureInfo[1]
		
		iso.ISOfile.seek((textureOffset * 2048) +  parent.bigfileRootOffset )
		var data = iso.ISOfile.get_buffer(textureSize)
				
		return imageLoader.getVRMdata(data)
		
	else:
		return parent.cachedSharedVrmData

func threadedWait(thread : Thread,modelName : String,specificAnims : Array,resultStorage : Array,textureData):
	var t = Time.get_ticks_msec()
	resultStorage.append(createModel(modelName,textureData,specificAnims))
	print("model load time: ",Time.get_ticks_msec()-t)

func createModelThreaded(modelName : String,specificAnims : Array,resultStorage,texureData = null) -> Thread:
	var t : Thread = Thread.new()
	t.start(threadedWait.bind(t,modelName,specificAnims,resultStorage,texureData))
	return t

func createModel(modelName : String,textureData = null,specifcAnimation := []):
	
	
	
	if textureData == null:
		if iso.ISOfile != null:
			textureData = loadSharedVRMInISO()
		
		elif parent.standaloneBigfile != null:
			var textureInfo = textureFiles["bigfile/packs/shared.vrm"]
			var textureSize = textureInfo[0]
			var textureOffset = textureInfo[1]
			
			parent.standaloneBigfile.seek((textureOffset * 2048))
			var data = parent.standaloneBigfile.get_buffer(textureSize)
			textureData = imageLoader.getVRMdata(data)
			
			var entry = parent.fileNames.find("bigfile/packs/shared.mpk")
			var sharedMpkOffset = parent.entriesOffsets[entry]
			var sharedMpkSize = parent.entriesSizes[entry]
			parent.standaloneBigfile.seek((sharedMpkOffset * 2048))
			data = parent.standaloneBigfile.get_buffer(sharedMpkSize)
			parent.parseMpk(data)
			



	var modelInfo = modelFiles[modelName]
	var modelSize = modelInfo[0]
	var modelOffset = modelInfo[1]
	
	if modelSize == 0:
		return
	
	var data:PackedByteArray = []
	if parent.standaloneBigfile == null:
		data = iso.getDataAtPosition((modelOffset * 2048) + parent.bigfileRootOffset ,modelSize)
	else:
		parent.standaloneBigfile.seek((modelOffset * 2048))
		data = parent.standaloneBigfile.get_buffer(modelSize)
	
	var model =  parseCTR(data,textureData,0,specifcAnimation)
	
	
	#addWheels(model)
	
	#ENTG.saveNodeAsScene(model)
	return model
	


var c = 0


func addWheels(model : Node3D):
	var sprites : Array[Image]= imageLoader.getWheelSprites()
	
	if sprites.is_empty():
		return
	
	var frontLeft  = Vector3(-2.15,0.923,-2.927)*scaleFactor*245
	var frontRight = Vector3(2.165,0.923,-2.927)*scaleFactor*245
	var backRight = Vector3(2.332,0.923,1.594)*scaleFactor*245
	var backLeft = Vector3(-2.15,0.923,1.594)*scaleFactor*245
	
	var wheelParent = Node3D.new()
	wheelParent.name = "wheels"
	wheelParent.script = load("res://addons/ctr/src/wheels.gd")
	var posArr = [frontLeft,frontRight,backRight,backLeft]
	var posArrStr = ["frontLeft","frontRight","backRight","backLeft"]
	
	
	var dict ={
		"S" : 0,
		"SE-pre": 2,
		"SE": 7,
		"SEpost": 9,
		"East" : 16
		
	}
	
	#var mat : ShaderMaterial = load("res://addons/ctr/shaders/8wayBillboard.tres")
	
	var spriteFrame : SpriteFrames = SpriteFrames.new()
	var orig : Array[Image] = []
	
	for i in sprites:
		orig.append(i.duplicate(true))
	
	for idx in sprites.size():
		sprites[idx].flip_x()
	
	
	orig.pop_front()
	
	
	for i in 14:
		sprites.append(orig[14-i])
	
	
	
	for i in sprites.size():
		spriteFrame.add_frame("default",ImageTexture.create_from_image(sprites[i]))
		
	#ResourceSaver.save(spriteFrame,"res://frames.tres")
	#for key in dict:
		#var texture = ImageTexture.create_from_image(sprites[dict[key]])
		#
		#mat.set_shader_parameter(key,texture)
		#mat.set_shader_parameter("pixelSize",0.5)


	#ResourceSaver.save(mat,"res://huh.tres")
	for i in posArr.size():

		var sprite3D = AnimatedSprite3D.new()
		sprite3D.sprite_frames =  spriteFrame
		sprite3D.position = posArr[i]
		sprite3D.name = posArrStr[i]
		sprite3D.pixel_size = scaleFactor * 12
		sprite3D.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		sprite3D.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		wheelParent.add_child(sprite3D)
	
	model.add_child(wheelParent)


func test2(textureLayout,paletteCache):
	

	var pageCoord : Vector2i = textureLayout["page"]
	var topLeft = textureLayout["tlUV"]
	var dim = textureLayout["dim"]
	var xStartPixel = (pageCoord.x * 128) + (topLeft.x/2)#uv 255 is page pixel width which is 128
	var yStartPixel = (pageCoord.y * 256) + topLeft.y
	var palPos = textureLayout["pallete"]
	
	var bpp = textureLayout["bpp"]
	var texture  = []
	texture.resize(dim.x*dim.y*2)
	
	var sourceStartOffset =  ((yStartPixel*2048)+xStartPixel)/2#1 byte per pixel>
	var vram = imageLoader.vram
	
	
	for y in dim.y:
		for x in dim.x:
			var word_index = sourceStartOffset + (y * 1024) + x
			var byte_index = (y * dim.x + x) * 2

			var low = vram[word_index * 2]
			var high = vram[word_index * 2 + 1]

			texture[byte_index] = low
			texture[byte_index + 1] = high

	
	var palStartOffset = palPos.y*2048 + palPos.x*32
	#var paletteBytes = createPalleteFromOffset(palStartOffset)
	var palKey = str(textureLayout["pallete"])+str(textureLayout["page"])
	var palatteColors = paletteCache[palKey]
	
	
	var image = Image.create_empty(dim.x*4,dim.y,false,Image.FORMAT_RGBA8)
	var pixels = []


	for y in dim.y:
		for x in dim.x * 2:  # each byte has 2 pixels
			var byte = texture[(y*dim.x*2)+x]
			image.set_pixel(x*2,y,palatteColors[byte & 0b00001111])
			image.set_pixel((x*2) + 1,y,palatteColors[byte >> 4])
	
	
	return image

func createPalleteFromOffset(palStartOffset):
	var vram = imageLoader.vram
	var paletteBytes = []
	
	for i in 16:
		var low = vram[palStartOffset + i * 2]
		var high = vram[palStartOffset + i * 2 + 1]
		var short = low | (high << 8)
		paletteBytes.append(short)
		
	return paletteBytes



func convert_short_array_to_bytes(short_array: PackedInt32Array) -> PackedByteArray:
	var byte_array = PackedByteArray()
	for value in short_array:
		
		byte_array.append(value & 0xFF)         # Low byte
		byte_array.append((value >> 8) & 0xFF)  # High byte
		
	return byte_array
	
	#var page1 = textureData[0]
	#var page2 = textureData[0]
	#var page1Bytes = page1["imageData"]
	#var page2Bytes = textureData[1]["imageData"]
	#var w = page1["dim"].x
	#var w2 = page2["dim"].x
	#var p1trueW = w*4
	#
	#var h = 256
	#
	#var clut = extract_clut(page2Bytes,w2,clutPos.x,clutPos.y)
	#
	#var ki = imageLoader.getTimPixels(page1Bytes,Vector2(w,h),0,imageLoader.dummyClut)
	#
	#var i =  imageLoader.getBytesAtCoords(vramCoord.x,vramCoord.y,32)
	#var palette = []
	#for pixel in i.size()/2:
		#var low = i[pixel*2]
		#var high = i[(pixel*2)+1]
		#var pixelValue = (high << 8) | low
		#var color = imageLoader.convert_5551_to_rgb(pixelValue)
		#palette.append(color)
	#
	#
	#
	#var dim = getDim(textureLayout["uv"])
	#var poo : PackedByteArray = []
	#for y in 7:
		#poo.append_array(imageLoader.getBytesAtCoords(vramCoord.x,vramCoord.y,16))
	#
	#var finalPoo = []
	#
	#for p in poo:
			#var byte = poo[p]
			#
			#if byte != 0:
				#breakpoint
			#
			#var palette_index1 = byte & 0x0F
			#var palette_index2 = (byte >> 4) & 0x0F
			#finalPoo.append(imageLoader.dummyClut[palette_index1])
			#finalPoo.append(imageLoader.dummyClut[palette_index2])
				#
	#breakpoint

	
	
	breakpoint
func bytes_to_shorts(byte_array: PackedByteArray) -> PackedInt32Array:
	var short_array: PackedInt32Array = PackedInt32Array()
	var count := byte_array.size() / 2

	for i in count:
		var hi := byte_array[i * 2]
		var lo := byte_array[i * 2 + 1]
		var short := (hi << 8) | lo  # Big-endian (most common for PSX data)
		short_array.append(short)

	return short_array




	
func extract_clut(page_bytes: PackedByteArray, page_width: int, clut_x: int, clut_y: int) -> Array:
	var clut := []
	
	# Each pixel is 2 bytes (16 bits)
	# Calculate the start offset (in bytes) of the CLUT within the page
	var base_offset = (clut_y * page_width + clut_x) * 2
	
	for i in range(16):  # CLUT is 16 pixels wide
		var byte_index = base_offset + i * 2
		var color_val = page_bytes[byte_index] | (page_bytes[byte_index + 1] << 8)
		var color = imageLoader.convert_5551_to_rgb(color_val)
		clut.append(color)
	
	return clut
	
	
	#for i in raw:
		
	
	
	#var dim = getDim(textureLayout["uv"])
		
	#var pixelData :PackedColorArray= imageLoader.getTimPixels(img["imageData"],img["dim"],img["bpp"],img["clut"])

	#var ret = imageLoader.getTimPixels(data,dim,bpp,clutPixels)
	
	#if bpp == 0: w *= 4# 4-bit
	#if bpp == 1: w *= 2# 8-bit
	#if bpp == 2: w *= 1# 8-bit
	
	#var image = Image.create_empty(dim.x,dim.y,false,Image.FORMAT_RGBA8)
	#
	#
	#for x in dim.x:
		#for y in dim.y:
			#image.set_pixel(x,y,ret[(y*dim.x)+x])
	#
	#image.save_png("res://unpossable.png")
	breakpoint


func extractRect(pageData,uv):# -> PackedByteArray:
	var bbp = pageData["bpp"]
	var imageBytes = pageData["imageData"]
	
	
	breakpoint
	
	
	

	#return result
	
func loadModelFromFile(filepath : String):
	var fileData := FileAccess.get_file_as_bytes(filepath)
	
	var path = filepath.get_file()
	
	var model =  parseCTR(fileData)
	return model

func parseCTR(d : PackedByteArray,textureData:Array[Dictionary] = [],customStartOffset := 0,specificAnimation := []):
	var data := StreamPeerBuffer.new()
	data.put_data(d)
	data.seek(customStartOffset)
	
	var unk1 = data.get_32()
	var modelName = data.get_partial_data(16)[1].get_string_from_ascii()
	var unk2 = data.get_16()
	var numModels = data.get_16()
	var ptrToModelHeaderMaybe = data.get_32()
	var anims = {}
	var subModelArr : Array[SubModel]
	var colors : PackedColorArray= []
	var root := Node3D.new()
	
	var cachedTextures = {}
	var paletteCache : Dictionary[String,Array] = {}
	
	
	
	#if modelName != "banner":
	#	return
	
	#if model
	
	root.name = modelName
	
	#-----------------

	for i in numModels:
		subModelArr.append(parseSubModel(data))
	
	
	var doesAnimHaveDuplicateFrames = []
	
	
	
	for i : SubModel in subModelArr:
		
		
		#-------cmd
		data.seek(i.cmdOffset+4)
		var nodbodyKnows = data.get_32()
		
		var retD = parseDrawCommands(data)
		
		var vertCount = retD["maxVertexCount"]
		var drawList = retD["drawList"]
		var maxTextureIndex : int =  retD["maxTextureIndex"]
		var maxColorIndex : int =  retD["maxColorIndex"]
		
		#------clut
		data.seek(i.clutOffset+4)
		
		colors.resize(maxColorIndex+1)
		
		for colorIdx in maxColorIndex+1:
			var colByte = data.get_32()
			
			var w = (colByte >> 24) & 0xFF
			var z = (colByte >> 16) & 0xFF
			var y = (colByte >> 8) & 0xFF
			var x = colByte & 0xFF
			
			colors[colorIdx] = Color(x/255.5,y/255.5,z/255.5,1.0)
			
			#colors.append(Color(x/255.5,y/255.5,z/255.5,w/255.5))
		
		#-----------texture
		
		var textureLayouts : Array[Dictionary]= []
		var textureLayoutsByPalette := {}
		
		data.seek(i.textureOffset+4)
		var textureOffsets = []
		textureOffsets.resize(maxTextureIndex)
		textureLayouts.resize(maxTextureIndex)
		
		for t in maxTextureIndex:
			textureOffsets[t] = data.get_u32()
		
		for t in maxTextureIndex:##44 and 45 are eyes
			data.seek(textureOffsets[t]+4)
			textureLayouts[t] = imageLoader.parseTextureLayout(data)
		
		
		
		
		for textureLayout in textureLayouts:
			textureLayout["uv"][3] = textureLayout["uv"][2];
			textureLayout["normUV"] = normalizeUV(textureLayout["uv"])
			
			if !textureLayoutsByPalette.has(textureLayout["pallete"]):
				textureLayoutsByPalette[textureLayout["pallete"]] = []
				
			textureLayoutsByPalette[textureLayout["pallete"]].append(textureLayout)
			
		
		
		
		
		
		
		#----- create palette cache
		if !textureData.is_empty():
			for t in textureLayouts:
				var palKey = str(t["pallete"])+str(t["page"])
				if !paletteCache.has(palKey):
					var palStartOffset = t["pallete"].y*2048 + t["pallete"].x*32
					var paletteBytes = createPalleteFromOffset(palStartOffset)
					var paletteColors = []
					
					for p in paletteBytes:
						paletteColors.append(imageLoader.convert_5551_to_rgb(p))
					
					paletteCache[palKey] = paletteColors
		
		
	
	
		if !textureData.is_empty():
			
			for t in textureLayouts:
				var key = str(t["pallete"]) + str(t["page"]) + str(t["dim"]) + str(t["tlUV"])
				if !cachedTextures.has(key):
					var image = test2(t,paletteCache)
					
					cachedTextures[key] =image
				
				t["image"] = cachedTextures[key] 
				
		
		
			
			
		
		#textureLayouts.sort_custom(func(a, b):return str(a["image"]) < str(b["image"]))
		
		var prev = null
		var co0unt = 0
		
		
		#----------anims
		var animOffsets = []
		
		if i.animsOffset+4 > data.get_size():
			i.numAnims = 0
		data.seek(i.animsOffset+4)
		
		for animIdx in i.numAnims:
			animOffsets.append(data.get_u32())
		
		
		
		for animOffset in animOffsets:
			data.seek(animOffset+4)
			var ret = parseAnim(data,vertCount)
			anims[ret[0]] = [ret[1],ret[2],ret[3],ret[4]]
		
		if animOffsets.size() == 0:
			var tet = i["cmdOffset"]
			var tet2 = data.get_position()
			var ret  = readFrame(vertCount,data,i.frameOffset+4,[],[],[])
			anims[ret[0]] = [ret[1],ret[2],ret[3],false]
		
		
		if anims.size() == 0:
			return
		
		
		
		var isFirstAnim := true
		var allAnimNames = anims.keys()
		
		if specificAnimation.has("idle"):
			anims = eraseAllButTurn10(anims)
		
		for animName in anims.keys():
			
			
			var curAnimInfo = anims[animName]
			var numberOfFramesInAinm = curAnimInfo[2]
			var duplicateFrames = curAnimInfo[3]
			doesAnimHaveDuplicateFrames.append(duplicateFrames)
			var animNode :=  Node3D.new()
			animNode.name = animName
			
			animNode.visible = isFirstAnim
			isFirstAnim = false
			
			
			var finalAnimData = []
			
			
			for fIdx in anims[animName][0].size():
			#for fIdx in 1:
			
				
				var curFrameNumber = fIdx
				var ret = createFrameMesh(drawList,curAnimInfo[0][curFrameNumber],curAnimInfo[1][curFrameNumber],i.scale,colors,textureLayouts,textureData.is_empty())
				var mesh = ret["mesh"]
				var surfaceInfo = ret["surfaceInfo"]
				var meshInstance := MeshInstance3D.new()
				
				
				
				meshInstance.mesh = mesh
				for sIdx in surfaceInfo.size():
					var mat = StandardMaterial3D.new()
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					#  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					var image = surfaceInfo[sIdx]
					#if image != null:
					#image.save_png("res://dbg/"+str(sIdx)+".png")
					
					
					if image != null:
						mat.albedo_texture = ImageTexture.create_from_image(image)
					
					mat.vertex_color_use_as_albedo = true
					#if OS.get_thread_caller_id() =
					parent.mutex.lock()
					mesh.surface_set_material(sIdx,mat)
					parent.mutex.unlock()
					#else:
					#	mesh.call_deferred("surface_set_material", 0, material)
					#
					continue
				
				meshInstance.name = "frame "+str(curFrameNumber)
				meshInstance.mesh = mesh
				
				if anims.size() == 1 and anims.has("idle"):
					meshInstance.name = root.name
					return meshInstance
				
				animNode.add_child(meshInstance)
				if fIdx != 0:
					meshInstance.visible = false
			root.add_child(animNode)
		break
	
	createAnimationPlayer(root,anims.keys(),doesAnimHaveDuplicateFrames)
	
	if root.get_node_or_null("turn"):
		if root.get_node_or_null("turn/frame 10"):
			root.get_node("turn/frame 0").visible = false
			root.get_node("turn/frame 10").visible =true
	
	
	addWheels(root)
	#root.scale = Vector3.ONE * 0.28
	#ENTG.saveNodeAsScene(root,"res://model.tscn")
	return root
	#;breakpoint

		
		
func createAnimationPlayer(rootNode : Node3D,animNames : PackedStringArray,doesAnimHaveDuplicateFrames):
	var animPlayer = AnimationPlayer.new()
	var lib : AnimationLibrary = AnimationLibrary.new()
	var timeUnit = 1/30.0
	
	var curAnimn = 0
	for i in rootNode.get_children():
		if i.name == "idle":
			return
			
		if doesAnimHaveDuplicateFrames[curAnimn]:
			timeUnit = 1/15.0
		else:
			timeUnit = 1/30.0
		var numFrames = i.get_child_count()
		var anim = Animation.new()
		
		var count = 0
		var size = i.get_child_count()
		
		
		anim.length = timeUnit*numFrames
		
		for j in size:
			anim.add_track(Animation.TYPE_VALUE)
			
		for j in i.get_children():
			anim.track_set_path(count,i.name+"/"+j.name+":visible")
			anim.track_set_interpolation_type(count,Animation.INTERPOLATION_NEAREST)
			
			count += 1
		
		for animName in animNames:
			var tid := anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tid,animName+":visible")
			anim.track_insert_key(tid,0,animName == i.name)
		
		
		for frame in numFrames:
			anim.track_insert_key(frame,0,frame == 0)
				#
		for time in numFrames:
			anim.track_insert_key(time,time*timeUnit,true)
			if time != 0:
				anim.track_insert_key(time-1,time*timeUnit,false)


		lib.add_animation(i.name,anim)
		curAnimn+=1

		
	
	animPlayer.add_animation_library("",lib)
	rootNode.add_child(animPlayer)
	
func createFrameMesh(drawList,frameVerts,frameVertOffsets,scale,colors,textureLayouts,skipTextures):
	var ret = getFinalTriVerts(drawList,frameVerts,frameVertOffsets,scale,colors,textureLayouts,skipTextures)
	var triVerts = ret["verts"]
	var vertColors   = ret["colors"]
	var triUVs  = ret["uvs"]
	var triTextures = ret["textures"]

	
	
	var vertColors3 = []
	var triUVs3 = []
	var triTextures3 : Array[Image]= []
	
	var triVerts3 : Array[PackedVector3Array]= []
	
	
	triVerts3.resize(triVerts.size()/3)
	triUVs3.resize(triVerts.size()/3)
	
	for i in triVerts.size()/3:
		triVerts3[i] = ([triVerts[(i*3)] , triVerts[(i*3)+1], triVerts[(i*3)+2]] as PackedVector3Array)
		triUVs3[i] = ([triUVs[(i*3)] , triUVs[(i*3)+1], triUVs[(i*3)+2]])
		vertColors3.append([vertColors[(i*3)] , vertColors[(i*3)+1] , vertColors[(i*3)+2]])
		triTextures3.append(triTextures[i*3])
		
	
	var triangle_count = triTextures3.size()

	var triangles = []
	for i in triangle_count:
		triangles.append({
			"texture": triTextures3[i],
			"verts": triVerts3[i],
			"colors": vertColors3[i],
			"uvs": triUVs3[i]
		})

	triangles.sort_custom(func(a, b): return str(a["texture"]) < str(b["texture"]))

	var numTris : int = triangles.size()
	triTextures = []
	triVerts = []
	vertColors = []
	triUVs = []
	
	var numTriangles : int =  triangles.size()
	
	triTextures.resize(numTriangles)
	triVerts.resize(numTriangles)
	vertColors.resize(numTriangles)
	triUVs.resize(numTriangles)
	
	for triIdx in numTriangles:
		var triangle : Dictionary = triangles[triIdx]
		triTextures[triIdx] =triangle["texture"]
		triVerts[triIdx] =(triangle["verts"])
		vertColors[triIdx] = (triangle["colors"])
		triUVs[triIdx] = (triangle["uvs"])
	
	
	
	var totalMesh := ArrayMesh.new()
	
	
	var arrays = []
	var surfaceInfo = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = [] as PackedVector3Array
	arrays[Mesh.ARRAY_COLOR] = [] as PackedColorArray
	arrays[Mesh.ARRAY_TEX_UV] = [] as PackedVector2Array
	#here
	var prevTexture = null
	var first = true
	
	var triVerts3size = triVerts3.size()
	for v in triVerts3.size():
		
		var currentTexture = triTextures[v]
		
		if triTextures[v] != prevTexture and arrays[Mesh.ARRAY_VERTEX].size() > 0  and !first:
			totalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			surfaceInfo.append(prevTexture)
			prevTexture = triTextures[v]
			arrays[Mesh.ARRAY_VERTEX] = [] as PackedVector3Array
			arrays[Mesh.ARRAY_COLOR] = [] as PackedColorArray
			arrays[Mesh.ARRAY_TEX_UV] = [] as PackedVector2Array
		
		first = false
		prevTexture = currentTexture
		
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][2])
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][1])
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][0])
		
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][2])
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][1])
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][0])
		
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][2])
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][1])
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][0])
		
	if arrays.size() != 0:
		totalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		surfaceInfo.append(prevTexture)
	

		
	
	return {"mesh":totalMesh,"surfaceInfo":surfaceInfo,"triVerts":triVerts3}



func createMesh(triVerts,vertColors,triUVs,triTextures):
	var totalMesh := ArrayMesh.new()
	
	
	var arrays = []
	var surfaceInfo = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = [] as PackedVector3Array
	arrays[Mesh.ARRAY_COLOR] = [] as PackedColorArray
	arrays[Mesh.ARRAY_TEX_UV] = [] as PackedVector2Array
	#here
	var prevTexture = null
	var first = true
	
	for v in triVerts.size():
		
		var currentTexture = triTextures[v]
		
		if triTextures[v] != prevTexture and arrays[Mesh.ARRAY_VERTEX].size() > 0  and !first:
			totalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			surfaceInfo.append(prevTexture)
			prevTexture = triTextures[v]
			arrays[Mesh.ARRAY_VERTEX] = [] as PackedVector3Array
			arrays[Mesh.ARRAY_COLOR] = [] as PackedColorArray
			arrays[Mesh.ARRAY_TEX_UV] = [] as PackedVector2Array
		
		first = false
		prevTexture = currentTexture
		
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][0])
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][1])
		arrays[Mesh.ARRAY_VERTEX].append(triVerts[v][2])
		
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][0])
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][1])
		arrays[Mesh.ARRAY_COLOR].append(vertColors[v][2])
		
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][0])
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][1])
		arrays[Mesh.ARRAY_TEX_UV].append(triUVs[v][2])
		
	if arrays.size() != 0:
		totalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		surfaceInfo.append(prevTexture)
		
	return [totalMesh,surfaceInfo]

func getFinalTriVerts(drawList,verts,offset,scale,colors,textureLayouts,skipTextures = false):
	
	var temp : PackedVector3Array = []
	var tempUV : PackedVector3Array =[]
	var tempTex : Array[Image] =[]
	var tempColor : PackedColorArray = []
	var stack : PackedVector3Array = []
	var triVerts : PackedVector3Array = []
	var triColors : PackedColorArray = []
	var triTextures : Array[Image] = []
	var triUVs : PackedVector2Array = []
	var vfixed : PackedVector3Array
	
	vfixed.resize(verts.size())
	stack.resize(256)
	temp.resize(4)
	#triTextures.resize(4)
	tempUV.resize(4)
	tempColor.resize(4)
	tempTex.resize(4)
	
	
	
	for i in verts.size():
		var srcVert = verts[i]
		vfixed[i] = Vector3.ZERO
		vfixed[i].x = ((srcVert.x / 255.0) + offset.x)*scale.x
		vfixed[i].y = ((srcVert.z / 255.0) + offset.y)*scale.y
		vfixed[i].z = ((srcVert.y / 255.0) + offset.z)*scale.z
		
	var vertexIndex = 0;
	var stripLength = 0;
	
	var count = 0
	
	

	
	for cmd in drawList:
		if !cmd["stack_vertex"]:
			stack[cmd["stack_index"]] = vfixed[vertexIndex]
			vertexIndex += 1

		var textureIndex = cmd["tex_index"]
		
		temp[0] = temp[1];
		temp[1] = temp[2];
		temp[2] = temp[3];
		temp[3] = stack[cmd["stack_index"]];
		
		tempColor[0] = tempColor[1];
		tempColor[1] = tempColor[2];
		tempColor[2] = tempColor[3];
		tempColor[3] = colors[cmd["color_index"]];
		
		tempUV[0] = tempUV[1];
		tempUV[1] = tempUV[2];
		tempUV[2] = tempUV[3];

		
		tempTex[0] = tempTex[1];
		tempTex[1] = tempTex[2];
		tempTex[2] = tempTex[3];
		
		if !skipTextures:
			if textureIndex == 0:
				tempTex[3] = null
			else:
				tempTex[3] = textureLayouts[textureIndex- 1]["image"];


		if cmd["swap_vertex"]:
			temp[1] = temp[0];
			tempColor[1] = tempColor[0]
			tempTex[1] = tempTex[0]
			
			
		if cmd["new_tri_strip"]:
			stripLength = 0
		
		if stripLength >= 2:
			for z in range(2, -1, -1):
				
				
				
				triVerts.append(temp[z+1]*Vector3(-1,1,-1))
				triColors.append(tempColor[z+1]*2.0)
				
				if textureIndex != 0:
					var textureLayout = textureLayouts[textureIndex-1]
					textureLayout["normUV"] = normalizeUV(textureLayout["uv"])
	
					if !skipTextures:
						triTextures.append(textureLayout["image"])
					else:
						triTextures.append(null)
					#print(count,":",textureLayout["normUV"][z])
					var x = textureLayout["normUV"][z]
					textureLayout["normUV"][z]
					triUVs.append(textureLayout["normUV"][z]/255.0)


					count += 1
					
				else:

					triUVs.append(Vector2.ZERO)
					triTextures.append(null)
					count += 1
				
				

			
			if cmd["flip_normal"]:
				var last_index = triVerts.size() - 1
				var temp2 = triVerts[last_index]
				
				triVerts[last_index] = triVerts[last_index - 1]
				triVerts[last_index - 1] = temp2
				
				temp2 = triColors[last_index]
				triColors[last_index] = triColors[last_index - 1]
				triColors[last_index - 1] = temp2
				
				temp2 = triUVs[last_index]
				triUVs[last_index] = triUVs[last_index - 1]
				triUVs[last_index - 1] = temp2
				
				
				
			
			
		stripLength += 1
	

	return {"verts":triVerts,"colors":triColors,"uvs":triUVs,"textures":triTextures}


func reverse(verts,idx):
	var a = verts[idx]
	var b = verts[idx+1]
	var c = verts[idx+2]
	
	verts[idx] = c
	verts[idx+2] = a
	 
	#verts[idx] = Vector3.ZERO
	
	return verts
		
	
func createMeshFromVertices(vertices: PackedVector3Array) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	return mesh

func parseAnim(data: StreamPeerBuffer,numVerts : int):
	var animName = data.get_partial_data(16)[1].get_string_from_ascii()
	var numFrames : int = data.get_16()
	
	var duplicateFrames = false
	
	if ((numFrames & 0x8000) > 0):
		duplicateFrames = true;
	
	numFrames &= 0x7fff
	
	if duplicateFrames:
		numFrames /= 2;
		numFrames+=1
	
	var frames : Array[PackedVector3Array]= []
	var framePosOffsets : PackedVector3Array = []
	var isCompressed : bool = true
	
	var frameSize : int = data.get_16()
	var deltaOffset = data.get_32()
	
	if deltaOffset == 0:
		isCompressed = false
	
	var frameOffset = data.get_position()
	
	var deltas : Array[Delta]= []
	
	if isCompressed:
		deltas.resize(numVerts)
		data.seek(deltaOffset+4)
		
		for i in numVerts:
			deltas[i] = getDelta(data.get_u32())

	
	var t0 = Time.get_ticks_msec()
	
	for i in numFrames:
		readFrame(numVerts,data,(frameOffset) + (i*frameSize),frames,framePosOffsets,deltas)

	
	return [animName,frames,framePosOffsets,numFrames,duplicateFrames]


func readFrame(numVerts,data : StreamPeerBuffer,ptrFrame,frames : Array[PackedVector3Array],framePosOffsets : PackedVector3Array,deltas: Array[Delta]):
	
	
	var pos = data.get_position()
	if ptrFrame > data.get_size():
		print_debug("frame pointer out of range")
		#return null
	else:
		data.seek(ptrFrame)
	var isCompressed = true
	framePosOffsets.append(readVector(data,0.00390625))
		
	data.get_partial_data(16) 
		
	var bonk = data.get_u32()
	var vertsOffset = bonk - 0x1C
		
	
	data.seek(data.get_position()+vertsOffset)
	
	if deltas.is_empty():
		var frame : PackedVector3Array= []
		var t = data.get_position()
		for i in numVerts:
			frame.append(Vector3(data.get_u8(),data.get_u8(),data.get_u8()))
			
		
		frames.append(frame)
		
		
	else:
		var vertBytesCompressed := StreamPeerBuffer.new()
		var ba = BitStreamReader.new()
		ba.init( data.get_partial_data(4000)[1])# todo: don't use hardcoded size
		var t = vertBytesCompressed.get_32()
		
		
		if !deltas.is_empty():
			frames.append(decompressVerts(ba,deltas))
			

	return ["idle",frames,framePosOffsets,1]

func getDelta(value : int) -> Delta:
	var delta := Delta.new()
	
	delta.bits.x = int((value >> (3 * 2)) & 7)
	delta.bits.y = int((value >> (3 * 1)) & 7)
	delta.bits.z = int((value >> (3 * 0)) & 7)

	delta.position.x = int((value >> (9 + 8 * 2)) & 0xFF)
	delta.position.y = int((value >> (9 + 8 * 1)) & 0xFF)
	delta.position.z = int((value >> (9 + 8 * 0)) & 0xFF)
	
	return delta
	
	

func parseDrawCommands(data: StreamPeerBuffer):
	var drawList : Array[Dictionary]= []
	var maxVertexCount := 0
	var maxColorIndex := 0
	var maxTextureIndex := 0
	while true:
		var raw := data.get_u32()
		
		if raw == 0xFFFFFFFF:
			break
	
		var flags = (raw >> 24) & 0xFF
		var stackIndex = (raw >> 16) & 0xFF
		var colorIndex = (raw >> 9) & 0x7F
		var texIndex = raw & 0x1FF
		
		
		
		var useStackVertex = (flags & 0x04) != 0

		
		if  !useStackVertex:
			maxVertexCount += 1

		if colorIndex > maxColorIndex:
			maxColorIndex = colorIndex
		
		if texIndex > maxTextureIndex:
			maxTextureIndex = texIndex

		var drawCommand = {
			"raw": raw,
			"flags": flags,
			"stack_index": stackIndex,
			"color_index": colorIndex,
			"tex_index": texIndex,
			"new_tri_strip": (flags & 0x80) != 0,
			"swap_vertex":   (flags & 0x40) != 0,
			"flip_normal":   (flags & 0x20) != 0,
			"culled_face":   (flags & 0x10) != 0,
			"stack_color":   (flags & 0x08) != 0,
			"stack_vertex":  useStackVertex,
			"unused_1":      (flags & 0x02) != 0,
			"unused_2":      (flags & 0x01) != 0
		}

		drawList.append(drawCommand)

	return {"drawList": drawList,"maxVertexCount": maxVertexCount,"maxColorIndex":maxColorIndex,"maxTextureIndex":maxTextureIndex}


func decompressVerts(bs : BitStreamReader, deltas : Array[Delta]) -> PackedVector3Array:
	var result : PackedVector3Array = []
	var X : int = 0
	var Y  : int= 0
	var Z : int= 0

	result.resize(deltas.size())
	
	for idx in deltas.size():
		var ret = deltaToVertex(X, Y, Z, bs, deltas[idx])

		X = ret[1]
		Y = ret[2]
		Z = ret[3]
		
		result[idx] =  ret[0]
		

	return result


func deltaToVertex(X : int, Y : int, Z : int, bs : Node, delta : Delta) -> Array:

	if delta.bits.x == 7: X = 0
	if delta.bits.y == 7: Y = 0
	if delta.bits.z == 7: Z = 0

	var tX = getTemporalValue(bs, delta.bits.x)
	var tY = getTemporalValue(bs, delta.bits.y)
	var tZ = getTemporalValue(bs, delta.bits.z)

	X = (X + (delta.position.x << 1) + tX) % 256
	Y = (Y + delta.position.y + tY) % 256
	Z = (Z + delta.position.z + tZ) % 256

	var vertex = Vector3(X & 0xFF, Z & 0xFF, Y & 0xFF)

	return [vertex, X , Y , Z]

var cache = {}

func getTemporalValue(bs : BitStreamReader,deltaBits : int) -> int:
	
	var result := 0
	
	if bs.take_bit() == 1:
		result = -(1 << deltaBits)
		 

	for i in range(deltaBits):
		result |= bs.take_bit() << (deltaBits - 1 - i)

	return result


func parseSubModel(data: StreamPeerBuffer) -> SubModel:
	var model := SubModel.new()

	model.subModelName = data.get_partial_data(16)[1].get_string_from_ascii()
	

	var unk5 := data.get_32()
	model.lodDistance = data.get_16()
	model.billboard = data.get_16()
	model.scale = readVector(data, scaleFactor)
	model.cmdOffset = data.get_32()
	model.frameOffset = data.get_32()
	model.textureOffset = data.get_32()
	model.clutOffset = data.get_32()

	var unk6 := data.get_32()
	model.numAnims = data.get_32()
	model.animsOffset = data.get_32()
	var unk7 := data.get_32()

	return model



func readVector(buffer: StreamPeerBuffer, scale: float = 1.0) -> Vector3:
	var x = buffer.get_16() * scale
	var y = buffer.get_16() * scale
	var z = buffer.get_16() * scale
	buffer.get_16()
	return Vector3(x, y, z)

func  getDim(arr)-> Vector2:
	var uvMin = Vector2.INF
	var uvMax = -Vector2.INF
	
	for uv in arr:
		if uv.x < uvMin.x : uvMin.x = uv.x
		if uv.y < uvMin.y : uvMin.y = uv.y
		
		if uv.x > uvMax.x : uvMax.x = uv.x
		if uv.y > uvMax.y : uvMax.y = uv.y
		
	return uvMax-uvMin


	


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
	
	
func animToImage(triVerts):
	
	var width = triVerts.size() * 3  # 3 pixels per triangle
	var height = 1
	var image = Image.create_empty(width, height, false, Image.FORMAT_RGBF)  # Use RGB float for precision

	var pixel_index = 0
	for tri in triVerts:
		for vert in tri:
			image.set_pixel(pixel_index, 0, Color(vert.x, vert.y, vert.z))
			pixel_index += 1

	image.save_png("res://var.png")
	return image



func eraseAllButTurn10(anims : Dictionary):
	
	
	if !anims.has("turn"):
		return anims
	
	var retAnimns : Dictionary = {}
	
	retAnimns["turn"] = anims["turn"]
	
	var a  : PackedVector3Array = retAnimns["turn"][0][10]
	var b  = retAnimns["turn"][1][10]
	
	retAnimns["turn"][0].resize(1)
	retAnimns["turn"][1].resize(1)
	
	retAnimns["turn"][0] = [a]
	retAnimns["turn"][1] = [b] as PackedVector3Array
	retAnimns["turn"][2] = 1
	
	return retAnimns
