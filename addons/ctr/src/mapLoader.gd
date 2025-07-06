@tool
extends Node

@onready var parent := get_parent()
@onready var imageLoader := $"../imageLoader"
@onready var modelLoader: = $"../modelLoader"
@onready var iso : ISO  = $"../IsoReader"

@onready var modelFiles : Dictionary [String,Array] = parent.modelFiles
@onready var levelFiles : Dictionary [String,Array] = parent.levelFiles

var debug = true

var mapScaleFactor = 0.012
#var mapScaleFactor = (1.0 / (1 << 12))
#@onready var mapScaleFactor = (1.0 / (1 << 12))0.000244140625
#@onready var mapScaleFactor = (1.0 / (1 << 8))  0.00390625

var textureCache = {}
var paletteCache = {}

enum QuadFlags {
	None = 0,
	Invisible = 1 << 0,
	MoonGravity = 1 << 1,
	Reflection = 1 << 2,
	Kickers = 1 << 3,
	OutOfBounds = 1 << 4,
	NeverUsed = 1 << 5,
	TriggerScript = 1 << 6,
	Reverb = 1 << 7,
	KickersToo = 1 << 8,
	MaskGrab = 1 << 9,
	TempleDoor = 1 << 10,
	Unknown = 1 << 11,
	Ground = 1 << 12,
	Wall = 1 << 13,
	NoCollision = 1 << 14,
	InvisibleTriggers = 1 << 15,
	All = -1
}

enum RotateFlipType {
	None = 0,
	Rotate90 = 1,
	Rotate180 = 2,
	Rotate270 = 3,
	FlipRotate270 = 4,
	FlipRotate180 = 5,
	FlipRotate90 = 6,
	Flip = 7,
	NoMatch = -1
}

enum FaceMode {
	DrawBoth = 0,
	DrawLeft = 1,
	DrawRight = 2,
	DrawNone = 3
}

func createMap(mapName : String):
	var rootOffset = parent.bigfileRootOffset
	var mapInfo = levelFiles[mapName]
	var mapSize = mapInfo[0]
	var mapOffset = mapInfo[1]
	
	var vrmPath = mapName.substr(0,mapName.rfind("/")) + "/data.vrm"
	var textureData = []
	
	var textureFiles = parent.textureFiles
	
	if parent.textureFiles.has(vrmPath):
		var textureInfo =  parent.textureFiles[vrmPath]
		var textureSize = textureInfo[0]
		var textureOffset = textureInfo[1]
		iso.ISOfile.seek((textureOffset * 2048) +rootOffset )
		var data := iso.ISOfile.get_buffer(textureSize)
		
		imageLoader.parseVRM2(data)
		textureData = imageLoader.getVRMdata(data)
	else:
		print_debug("path not found for map vrm")
	
	
	iso.ISOfile.seek((mapOffset * 2048) + rootOffset )
	var data := iso.ISOfile.get_buffer(mapSize)
	var map =  parseMap(data,textureData)
	
	if debug:
		map.set_meta("offsetInIso",(mapOffset * 2048) + rootOffset)
		map.set_meta("mapSizeInBytes",mapSize)
	
	return map
	

func getIconsFromMap(mapName : String):
	var rootOffset = parent.bigfileRootOffset
	var mapInfo = levelFiles[mapName]
	var mapSize = mapInfo[0]
	var mapOffset = mapInfo[1]
	
	
	var vrmPath = mapName.substr(0,mapName.rfind("/")) + "/data.vrm"
	
	if parent.textureFiles.has(vrmPath):
		var textureInfo =  parent.textureFiles[vrmPath]
		var textureSize = textureInfo[0]
		var textureOffset = textureInfo[1]
		iso.ISOfile.seek((textureOffset * 2048) +rootOffset )
		var data := iso.ISOfile.get_buffer(textureSize)
		imageLoader.parseVRM2(data)
	
	iso.ISOfile.seek((mapOffset * 2048) + rootOffset )
	var d:= iso.ISOfile.get_buffer(mapSize)	
	var data := StreamPeerBuffer.new()
	data.put_data(d)
	data.seek(64)
	
	var iconsOffset = data.get_u32()
	data.seek(iconsOffset+4)
	
	var icons = createIcons(data)
	
	var paletteCache = {}
	
	var ret : Dictionary[String,Image] = {}
	
	for i in icons:
		#if i == "proto8":
		ret[i] = imageLoader.textureLayoutToImage(icons[i],paletteCache)
		
		#image.save_png("res://dbg/%s.png" % [i])
	
	return ret
	

func parseMap(d,textureData):
	
	var data := StreamPeerBuffer.new()
	data.put_data(d)
	data.seek(0)
	
	var patchTable : PackedInt32Array = []
	var size = data.get_u32()
	data.seek(4)
	
	var hasTable = (size >> 31) == 0
	size &= ~(1 << 31)
	
	if hasTable:
	
		var contentData = data.get_partial_data(size)[1]
		var numEntries = data.get_u32()/4
		patchTable.resize(numEntries)
		
		for i in numEntries:
			patchTable[i] = data.get_u32()
	
	
	data.seek(0)
	
	
	
	return readScene(data,patchTable,textureData)



func readScene(data : StreamPeerBuffer,patchTable : PackedInt32Array,textureData):
	var header =getHeader(data)
	
	
	data.seek(header["meshOffset"])
	var rootNode = readMeshInfo(data)
	
	
	rootNode.set_meta("startPos",header["startingLinePositions"])
	rootNode.set_meta("startRot", header["startingLineRotations"])
	
	if debug:
		rootNode.set_meta("header",header)
	
	data.seek(header["iconsOffset"]+4)
	var iconTextureLayouts = createIcons(data)
	
	#data.seek(header["modelsOffset"])
	#createMapSubModels(data,header["numModels"],textureData)
	return rootNode
	


func createIcons(data : StreamPeerBuffer):
	var numTextures : int = data.get_32()
	var textureOffset : int = data.get_32()
	var numGroups : int = data.get_32()
	var pointerGroups : int = data.get_32()
	
	var textureLayouts = {}
	
	for i in numTextures:
		var ret = parent.parseIcon(data)
		textureLayouts[ret[0]] = ret[1]
	
	return textureLayouts
	
func readMeshInfo(data : StreamPeerBuffer):
	
	var unk = data.get_u32()
	var numQuadBlocks = data.get_u32()
	var numVerts = data.get_u32()
	var numUnk = data.get_u32()
	
	var quadBlocksOffset2 = data.get_u32()
	var vertsOffset2 = data.get_u32()
	
	var unkOffset = data.get_u32()
	var pos = data.get_position()
	var visDataOffset = data.get_u32()
	
	
	var numVisData = data.get_u32()
	var quadBlocksOffset = data.get_u32()
	var vertsOffset = data.get_u32()
	
	var verts = []
	var colors = []
	var morphColors = []


	
	
	data.seek(vertsOffset2+4)
	var ret = getVerts(data,numVerts)
	verts = ret[0]
	colors = ret[1]
	
	var dimRet := getMapDim(verts)
	var minDim := dimRet[0]
	var maxDim := dimRet[1]
	
	data.seek(quadBlocksOffset2+4)
	
	
	
	var r =  getQuadBlocks(data,numQuadBlocks,verts,colors)
	var blocks = r[0]
	var blocksColors = r[1]
	var blockTextures = r[2]
	var blockInfo = r[3]
	

	var root = Node3D.new()
	root.name="testMap"

	if debug:
		root.set_meta("blocksInfo",blockInfo)
		root.set_meta("quadBlocksOffset",quadBlocksOffset2+4)
	

	var matCache = {}
	
	for i in blocks.size():
		
		
		var center = getBlockCenter(blocks[i])
		
		var info = blockInfo[i]
		
		var meshInstance : MeshInstance3D = renderBlock(blocks[i],blocksColors[i],blockTextures[i],info,center)
		
		if debug:
			meshInstance.set_meta("blockIdx",i)
		
		var cols = []
		if (info["quadFlags"] & QuadFlags.NoCollision) == 0:
			cols = funcCreateBlockCollision(blocks[i],center)
			
		
		
		var body = StaticBody3D.new()
		
		
		for surfIdx in 4:
			var image = blockTextures[i][surfIdx]["image"]
			
			if !matCache.has(image):
				var m = StandardMaterial3D.new()
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.vertex_color_use_as_albedo = true
				m.albedo_texture = ImageTexture.create_from_image(image)
				matCache[image] = m
			
			meshInstance.mesh.surface_set_material(surfIdx,matCache[image])

		for c in cols:
			body.add_child(c)
		meshInstance.add_child(body)
		root.add_child(meshInstance)
	
	#mapDict["BB"] = mapDict["maxDim"] - mapDict["minDim"]
	#mapDict["center"]  = mapDict["minDim"] + (mapDict["BB"]*0.5)

	root.set_meta("boundingBox",maxDim-minDim)
	root.set_meta("center",minDim+(maxDim-minDim)*0.5)
	return root
	
func getMapDim(verts) -> Array[Vector3]:
	var minDim := Vector3.INF
	var maxDim := -Vector3.INF
	for vert : Vector3 in verts:
		if vert.x < minDim.x: minDim.x = vert.x
		if vert.y < minDim.y: minDim.y = vert.y
		if vert.z < minDim.z: minDim.z = vert.z
		if vert.x > maxDim.x: maxDim.x = vert.x
		if vert.y > maxDim.y: maxDim.y = vert.y
		if vert.z > maxDim.z: maxDim.z = vert.z
	
	
	return [minDim,maxDim]
		
	
func order_points_ccw(points: PackedVector3Array) -> PackedVector3Array:
	assert(points.size() == 4)

	# Step 1: Calculate the polygon normal
	var normal = (points[1] - points[0]).cross(points[2] - points[0]).normalized()

	# Step 2: Compute the centroid of the points
	var centroid = Vector3()
	for p in points:
		centroid += p
	centroid /= points.size()

	# Step 3: Define local coordinate axes on the plane
	var axis_x = (points[0] - centroid).normalized()
	var axis_y = normal.cross(axis_x)

	# Step 4: Calculate angle for each point relative to centroid on plane
	var points_with_angle = []
	for p in points:
		var vec = p - centroid
		var x = vec.dot(axis_x)
		var y = vec.dot(axis_y)
		var angle = atan2(y, x)
		points_with_angle.append({"point": p, "angle": angle})

	# Step 5: Sort points by angle (CCW)
	points_with_angle.sort_custom(
		func(a, b):
			if a["angle"] < b["angle"]:
				return -1
			else:
				return 1
)

	# Step 6: Return sorted points as PackedVector3Array
	var sorted_points = PackedVector3Array()
	for item in points_with_angle:
		sorted_points.append(item["point"])

	return sorted_points
func is_quad_convex(p: PackedVector3Array) -> bool:
	if p.size() != 4:
		return false

	# Step 1: Get normal of plane (assumes p[0], p[1], p[2] define the plane)
	var normal = (p[1] - p[0]).cross(p[2] - p[0]).normalized()

	# Step 2: Project points to the plane's 2D basis (e.g. to X/Y-like space)
	var x_axis = (p[1] - p[0]).normalized()
	var y_axis = normal.cross(x_axis)

	var projected := []
	for point in p:
		var vec = point - p[0]
		projected.append(Vector2(vec.dot(x_axis), vec.dot(y_axis)))

	# Step 3: Check convexity in 2D using cross product signs
	var is_positive = null
	for i in range(4):
		var a = projected[i]
		var b = projected[(i + 1) % 4]
		var c = projected[(i + 2) % 4]

		var ab = b - a
		var bc = c - b
		var cross = ab.cross(bc)

		if is_positive == null:
			is_positive = cross > 0
		elif (cross > 0) != is_positive:
			return false  # found a turn in the other direction → concave

	return true

func is_polygon_ccw(points: PackedVector3Array) -> bool:
	# Assuming points size is 4
	assert(points.size() == 4)

	var normal = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var sum = 0.0

	for i in range(points.size()):
		var current = points[i]
		var next = points[(i + 1) % points.size()]
		var edge = next - current
		sum += normal.dot(current.cross(next))

	# If sum is positive, polygon is CCW relative to normal
	return sum > 0

func are_points_coplanar(a: Vector3, b: Vector3, c: Vector3, d: Vector3, epsilon := 0.0001) -> bool:
	var normal = (b - a).cross(c - a).normalized()
	var dist = abs((d - a).dot(normal))
	return dist < epsilon

func get_quad_corners(quad: Array, center: Vector3) -> PackedVector3Array:
	# quad is an Array of two triangles: each triangle is Array of 3 Vector3
	var unique_points = []
	
	for triangle in quad:
		for point in triangle:
			var pt = point - center
			var exists = false
			for up in unique_points:
				if up.is_equal_approx(pt):
					exists = true
					break
			if not exists:
				unique_points.append(pt)
	
	# Make sure there are 4 unique points
	assert(unique_points.size() == 4)

	# Now order these points CCW (assuming planar quad)
	var ordered_points = order_points_ccw(PackedVector3Array(unique_points))
	return ordered_points


func remove_duplicate_vectors(points: Array) -> Array:
	var unique = []
	for p in points:
		var exists = false
		for u in unique:
			if p.is_equal_approx(u):
				exists = true
				break
		if not exists:
			unique.append(p)
	return unique

func funcCreateBlockCollision(block : Array,center):
	var cols : Array[CollisionShape3D]
	for quad in block:
		
		var quadMin = Vector3.INF
		var quadMax = -Vector3.INF


		var colShape = CollisionShape3D.new()
		var polyShape = ConvexPolygonShape3D.new()
		var shapeVerts : PackedVector3Array =  [quad[1][2]-center, quad[0][2]-center,quad[0][1]-center, quad[0][0]-center ]
		shapeVerts = remove_duplicate_vectors(shapeVerts)
		
		if shapeVerts.size() < 3:
			continue
		
		polyShape.points = shapeVerts
		colShape.shape = polyShape
				
		cols.append(colShape)
	
	return cols

func getBlockCenter(block:Array):
	var center = Vector3.ZERO
	var vertCount = 0
	for quad in block:
		for tri in quad:
			for vert in tri:
				center += vert
				vertCount += 1
	
	center /= vertCount
	return center

func renderBlock(block : Array,colors: Array,texInfo : Array,info : Dictionary,center = Vector3.ZERO):

	var totalMesh = ArrayMesh.new()
	var surfaceInfo = []

	for quadIdx in block.size():
		var arrays := []
		var rotationByte = info["faceRotations"]
		var modeByte = info["faceModes"]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = [] as PackedVector3Array
		arrays[Mesh.ARRAY_COLOR] = [] as PackedColorArray
		arrays[Mesh.ARRAY_TEX_UV] = [] as PackedVector2Array
		
		var quadUV = texInfo[quadIdx]["normUV"]
		var rot = rotationByte[quadIdx]
		
		if rot == RotateFlipType.Rotate90 : 
			rotateUV(quadUV,1)
			
		elif rot == RotateFlipType.Rotate180: 
			rotateUV(quadUV,2)
		
		elif rot == RotateFlipType.Rotate270 :
			rotateUV(quadUV,3)
		
		elif rot == RotateFlipType.Flip : 
			flipUV(quadUV)
		
		elif rot == RotateFlipType.FlipRotate90 : 
			flipUV(quadUV)
			rotateUV(quadUV,1)
		
		
		elif rot == RotateFlipType.FlipRotate180: 
			flipUV(quadUV)
			rotateUV(quadUV,2)
		
		
		elif rotationByte[quadIdx] == RotateFlipType.FlipRotate270 : 
			flipUV(quadUV)
			rotateUV(quadUV,3)
		
		
		
		if modeByte[quadIdx] == FaceMode.DrawLeft:
			rotateTri(quadUV,2)
		
		elif modeByte[quadIdx] == FaceMode.DrawRight :
			rotateTri(quadUV,1)
			
		
		for triIdx in block[quadIdx].size():
			for vertIdx in block[quadIdx][triIdx].size():
				
				arrays[Mesh.ARRAY_VERTEX].append(block[quadIdx][triIdx][vertIdx] - center)
				arrays[Mesh.ARRAY_COLOR].append(colors[quadIdx][triIdx][vertIdx] )
				
			if triIdx == 0:
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[0]/255.0)
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[1]/255.0)
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[3]/255.0)
				
			else:
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[0]/255.0)
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[3]/255.0)
				arrays[Mesh.ARRAY_TEX_UV].append(quadUV[2]/255.0)

		
		totalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	
	
	
	var meshInstance = MeshInstance3D.new()
	meshInstance.position = center
	meshInstance.mesh = totalMesh
	return meshInstance

func rotateUV(uvs, rotations = 1):
	for i in range(rotations % 4):
		var temp = uvs[0]
		uvs[0] = uvs[1]
		uvs[1] = temp

		temp = uvs[0]
		uvs[0] = uvs[2]
		uvs[2] = temp

		temp = uvs[2]
		uvs[2] = uvs[3]
		uvs[3] = temp
		
	

func rotateTri(uvs, rotations = 1):
	for i in range(rotations % 3):
		var temp = uvs[0]
		uvs[0] = uvs[1]
		uvs[1] = uvs[2]
		uvs[2] = temp
	return uvs

func flipUV(uvs):
	var oldUV0 = uvs[0]
	uvs[0] = uvs[1]
	uvs[1] = oldUV0
	
	var oldUV2 = uvs[2]
	uvs[2] = uvs[3]
	uvs[3] = oldUV2
	
	

func getQuadBlocks(data : StreamPeerBuffer,numQuadBlocks : int,verts : Array,c):
	var blocks = []
	var blocksInfo = []
	var blockTextures = []
	var blocksColors = []
	
	for q in numQuadBlocks:
		var t = data.get_position()
		var indices = []
		var colors = []
		
		for i in 9:
			var index = data.get_u16()
			
			indices.append(verts[index])
			colors.append(c[index])
		
		var tlQuad = [[indices[0],indices[4],indices[6]],[indices[0],indices[6],indices[5]]]
		var trQuad = [[indices[4],indices[1],indices[7]],[indices[4],indices[7],indices[6]]]
		var blQaud = [[indices[5],indices[6],indices[8]],[indices[5],indices[8],indices[2]]]
		var brQuad = [[indices[6],indices[7],indices[3]],[indices[6],indices[3],indices[8]]]
		
		var tlQuadColor = [[colors[0],colors[4],colors[6]],[colors[0],colors[6],colors[5]]]
		var trQuadColor = [[colors[4],colors[1],colors[7]],[colors[4],colors[7],colors[6]]]
		var blQaudColor = [[colors[5],colors[6],colors[8]],[colors[5],colors[8],colors[2]]]
		var brQuadColor = [[colors[6],colors[7],colors[3]],[colors[6],colors[3],colors[8]]]
		
		
		blocks.append([tlQuad,trQuad,blQaud,brQuad])
		blocksColors.append([tlQuadColor,trQuadColor,blQaudColor,brQuadColor])
		
		
		var quadFlags = data.get_16()
		print(data.get_position()-t)
		var buffer =data.get_u32()
		var drawOrderHigh = data.get_partial_data(4)[1]
		var textureOffsets = []
		
		
		var drawOrderLow = buffer & 0xFF
		
		var faceRotations = []
		var faceModes = []
		
		for i in 4:
			var val = ((buffer >> 8 + 5 * i) & 0x1F)
			faceRotations.append(val & 7)
			faceModes.append((val >> 3) & 3)
			
		for i in 4:
			textureOffsets.append(data.get_32())
			

		var bbMin = readVector(data,mapScaleFactor)
		var bbMax = readVector(data,mapScaleFactor)
		
		var pos = data.get_position()
		
		var terrainFlag = data.get_8()
		var weatherItensity = data.get_8()
		var weatherType = data.get_8()
		var unkTerrainFlag = data.get_8()
		
		var id = data.get_16()
		var trackPost = data.get_8()
		var midUnk = data.get_8()
		
		var lowTextureOffset = data.get_u32()
		
		var pvsOffset = data.get_u32()
		var p = data.get_position()
		for i in 5:
			var faceNoramlX = data.get_16()#todo add scale
			var faceNormalY = data.get_16()
		
		
		
		var texturePos = data.get_position()
		
	
		
		blocksInfo.append({"quadFlags":quadFlags,"drawOrderHigh":drawOrderHigh,"faceRotations":faceRotations,"faceModes":faceModes})
		blockTextures.append(parseTextureLayouts(data,lowTextureOffset,textureOffsets))
		
		data.seek(texturePos)
		
		
	return [blocks,blocksColors,blockTextures,blocksInfo]
	


func parseTextureLayouts(data : StreamPeerBuffer,textureLowOffset,mainTextureOffsets):
	data.seek(textureLowOffset+4)
	var textureLayouts = []
	var lowTextureInfo = imageLoader.parseTextureLayout(data)
	
	
	
	for offset in mainTextureOffsets:
		
		#f offset != 0:
		#	breakpoint
		
		data.seek(offset+4)
		var textureInfo = imageLoader.parseTextureLayout(data)
		imageLoader.textureLayoutToImage(textureInfo,paletteCache,textureCache)
		#textureInfo["image"].save_png("res://dbg/danger%s.png" %[offset])
		textureLayouts.append(textureInfo)
		
		
	
	
	return textureLayouts

func getVerts(data : StreamPeerBuffer,numVerts : int):
	var verts = []
	var colors = []
	
	for i in numVerts:
		verts.append(readVector(data,mapScaleFactor))
		var pad = data.get_u16()#used in pre-release
		colors.append(getColor(data.get_u32()))
		var morphColor = data.get_u32()
	
	
	return [verts,colors]
	
func getColor(val):
	var W = (val >> 24) & 0xFF
	var Z = (val >> 16) & 0xFF
	var Y = (val >> 8) & 0xFF
	var X = val & 0xFF
	
	var r = float(X) / 255.0
	var g = float(Y) / 255.0
	var b = float(Z) / 255.0
	var a = float(W) / 255.0
	
	if r == 0 and g == 0 and b == 0:
		return Color.TRANSPARENT
	
	return Color(r, g, b, 1)

func getHeader(data : StreamPeerBuffer):
	var unk = data.get_32()
	
	var meshInfoOffset = data.get_u32()
	var skyboxOffset = data.get_u32()
	var animTextureOffset = data.get_u32()
	
	var nunInstances = data.get_u32()
	var instancesOffset = data.get_u32()
	
	var numModels = data.get_u32()
	var modelsOffset = data.get_u32()
	
	var unkPtr1 = data.get_u32()
	var unkPtr2 = data.get_u32()
	var instancesPointerPointer = data.get_u32()
	var unkPtr3 = data.get_u32()
	
	data.get_u32()
	data.get_u32()
	
	var numWater = data.get_u32()
	var waterOffset = data.get_u32()
	
	
	var iconsOffset = data.get_u32()
	var iconsArrayOffset = data.get_u32()
	
	var environmentMapOffset = data.get_u32()
	
	
	var gradients = []
	
	for i in 3:
	
		var gradientFrom = data.get_16()
		var gradientTo = data.get_16()
		var gradientFromColor = data.get_partial_data(4)
		var gradientToColor = data.get_partial_data(4)
		
		gradients.append([gradientFrom,gradientTo,gradientFromColor,gradientToColor])
	
	var startingLinePositions : PackedVector3Array = []
	var startingLineRotations  : PackedVector3Array = []
	
	for i in 8:
		startingLinePositions.append(readVector(data,mapScaleFactor))
		startingLineRotations.append(readVector(data,0.000244140625))
	
	
	
	var unkPtr4 = data.get_u32()
	var unkPtr5 = data.get_u32()

	var lLowTexArrayOffset = data.get_u32()
	
	for i in 4:#backColor
		data.get_8()
	
	var sceneFags = data.get_u32()
	var builtStartOffset = data.get_u32()
	var buildEndOffset = data.get_u32()
	var bulidTypeOffset  =data.get_u32()
	
	return {"meshOffset":meshInfoOffset,"modelsOffset":modelsOffset,"numModels":numModels,"startingLinePositions":startingLinePositions,"startingLineRotations":startingLineRotations,"iconsOffset":iconsOffset}
	
	

func readVector(buffer: StreamPeerBuffer,scale : float) -> Vector3:
	var x = buffer.get_16() * scale
	var y = buffer.get_16() * scale
	var z = buffer.get_16() * scale
	return Vector3(x,y,z)


func createMapSubModels(buffer: StreamPeerBuffer,numModels : int,textureData) :
	var modelOffsets = []
	
	for i in numModels:
		modelOffsets.append(buffer.get_u32())
	
	for i in modelOffsets.size():
		var offset = modelOffsets[i]
		var size = 0
		
		if i != modelOffsets.size() -1:
			size =  modelOffsets[i+1] - offset
		
		else:
			size = 15000
		
		
		buffer.seek(0)
		var ctrData = buffer.get_partial_data(buffer.get_size())[1]
		var model = modelLoader.parseCTR(ctrData,textureData,offset)
		#if model != null:
		#	ENTG.saveNodeAsScene(model)
		
		
