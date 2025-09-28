@tool
class_name EGLO
extends Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

static var curPoint : ColorRect = null

static func drawPoint2D(tree : SceneTree,position : Vector2):
	var point = ColorRect.new()
	point.size = Vector2(2,2)
	point.position = position - point.size*0.5
	point.color = Color.RED
	point.z_index = 3
	
	if is_instance_valid(curPoint):
		curPoint.queue_free()
	
	curPoint = point
	
	tree.get_root().add_child(point)

static func bindConsole(tree):
	
	if Engine.is_editor_hint():
		return
	
	if tree.has_meta("bindedConsole"):
		return tree.get_meta("bindedConsole")
	
	var node = Node.new()
	node.set_script(load("res://addons/gameAssetImporter/scenes/console/consoleActivateBind.gd"))
	addChildNowOrDeferred(tree.get_root(),node)

	return node
	

static func saveVertArrAsScene(arr,sceneName = "poly",path = "res://dbg/"):
	var poly =  Polygon2D.new()
	poly.name = sceneName
	poly.polygon = arr.duplicate(true)
	ENTG.saveNodeAsScene(poly,path)

static func getCollisionShapeHeight(node : Node) -> float:
	
	if node == null:
		return 0 
	
	var shape = node.shape
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		return shape.extents.y * 2.0
	
	
	elif shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		return shape.height
		
	return 0.0

static func drawVertsAsSpheres(tree,arr):
	var root = Node3D.new()
	var material:=StandardMaterial3D.new()
	material.albedo_color = randomColor()
	
	if typeof(arr[0]) == TYPE_PACKED_VECTOR3_ARRAY:
		for i in arr:
			for j in i:
				var sphere = CSGSphere3D.new()
				sphere.material = material
				sphere.radius = 0.1
				sphere.position = j
				root.add_child(sphere)
	else:
		for i in arr:
			var sphere = CSGSphere3D.new()
			sphere.material = material
			sphere.radius = 0.1
			sphere.position = i
			root.add_child(sphere)
	
	tree.get_root().add_child(root)
	return root

static func funcDrawCustomAABB(par,node):
	var aabb = node.custom_aabb
	var mesh := CSGBox3D.new()
	mesh.size = aabb.size
	mesh.global_basis = par.global_basis
	#mesh.position += aabb.position
	
	par.add_child(mesh)
	

static func createAABBcollisionShape(mesh_instance: MeshInstance3D) -> CollisionShape3D:
	var mesh = mesh_instance.mesh
	if not mesh:
		return

	var aabb = mesh.get_aabb()
	var box_shape = BoxShape3D.new()
	box_shape.size = aabb.size

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = box_shape

	var local_center = aabb.position + (aabb.size * 0.5)
	collision_shape.transform.origin = local_center

	return collision_shape

static func givePlayerWeapons(playerNode : Node,allWeapons,gameName = ""):
	
	#var allWeapons = ["shotgun","super shotgun","chaingun","plasma gun","rocket launcher","chainsaw","BFG"]
	

		
	for weaponStr in allWeapons:
		var node = ENTG.fetchEntity(weaponStr,{},playerNode.get_tree(),gameName,false)
			
		if node == null:
			return null
			
		node.visible = true
		playerNode.weaponManager.pickup(node,true,true)
		

static func createMesh(faces) -> ArrayMesh:
	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		if face.size() == 4:  # If the face has 4 vertices (a quadrilateral)
			# Split the quadrilateral into two triangles
			surf.add_vertex(face[0])
			surf.add_vertex(face[1])
			surf.add_vertex(face[3])

			surf.add_vertex(face[1])
			surf.add_vertex(face[2])
			surf.add_vertex(face[3])
		else:
			# If it's a triangle, add it as is
			for i in range(3):
				surf.add_vertex(face[i])

	var mesh = surf.commit()
	return mesh

static func getShapeHeight(node):
	
	var shape = node.shape
	
	if shape == null:
		return
		
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		return shape.extents.y * 2.0

	
	
	if  shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		return shape.height


static func setShapeThickness(node : Node,radius : float) -> void:
	
	if node == null:
		return
	
	if node.shape == null:
		return 
		
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape3D":
		shape.extents.z = radius
		shape.extents.x = radius
		
	if shapeClass == "CylinderShape3D":
		shape.radius = radius


static func bytes_to_unsigned_shorts(byte_array: PackedByteArray) -> PackedInt32Array:
	var short_array := PackedInt32Array()
	var size := byte_array.size()

	if size % 2 != 0:
		push_warning("Byte array length is not even. Last byte will be ignored.")
		size -= 1

	for i in range(0, size, 2):
		var low := byte_array[i]
		var high := byte_array[i + 1]
		var ushort := (high << 8) | low  # Little-endian order
		short_array.append(ushort)

	return short_array

static var materialCache : Dictionary[Color,StandardMaterial3D] = {}
static var sphereMeshCache : Dictionary[float,SphereMesh]
static func drawSphere(node : Node,pos : Vector3,color = Color.WHITE,radius = 0.1):
	
	
	var shape : SphereMesh = null
	
	if !sphereMeshCache.has(radius):
		shape = SphereMesh.new()
		shape.radius = radius/2.0
		shape.height = radius
		sphereMeshCache[radius] = shape
	
	shape = sphereMeshCache[radius]
	
	var meshInstance = MeshInstance3D.new()
	meshInstance.mesh = shape
	if color != Color.WHITE:
		if !materialCache.has(color):
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			materialCache[color] = mat
			
		shape.material = materialCache[color]

		
	
	meshInstance.position = pos
	meshInstance.name = "deubgSphere"
	node.call_deferred("add_child",meshInstance)
	return meshInstance

static func getShapeThickness(node: Node) -> float:
	
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape3D":
		return shape.extents.z
		
		
	if shapeClass == "CylinderShape3D":
		return shape.radius
	
	return 0

static func setCollisionShapeHeight(node,height):
	
	var shape = node.shape
	
	if shape == null:
		return
		
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		
		if shape.extents.y !=  height/2.0:
			shape.extents.y = height/2.0
		return
	
	
	elif shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		shape.height = height
		return


static func saveVertTwoArrAsSpheres(arr1,arr2,sceneName = "quad",path = "res://dbg/"):
	
	var material:=StandardMaterial3D.new()
	material.albedo_color = Color.RED
	var m1 = saveVertArrAsSpheres(arr1,sceneName+"1",path,material,false)
	
	
	material = material.duplicate()
	material.albedo_color = Color.BLUE
	var m2 = saveVertArrAsSpheres(arr2,sceneName+"2",path,material,false)
	
	var root = Node3D.new()
	root.add_child(m1)
	root.add_child(m2)
	
	root.name = sceneName + "3"
	ENTG.saveNodeAsScene(root)

static func convertFanToTriangles(fanVertices: PackedVector3Array, fanUvs: PackedVector2Array) -> Array:
	var triangles: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	
	if fanVertices.size() < 3:
		return [triangles, uvs]  # Return empty arrays if insufficient vertices
	
	var center = fanVertices[0]
	var centerUv = fanUvs[0]

	for i in range(1, fanVertices.size() - 1):
		triangles.append(center)
		triangles.append(fanVertices[i])
		triangles.append(fanVertices[i + 1])
		
		uvs.append(centerUv)
		uvs.append(fanUvs[i])
		uvs.append(fanUvs[i + 1])
	
	return [triangles, uvs]  # Return both vertex and UV arrays


static func saveVertArrAsSpheres(arr,sceneName = "quad",path = "res://dbg/",mat : StandardMaterial3D = null,save = true):
	var root = Node3D.new()
	var itt = 0
	for i in arr:
		var sphere = CSGSphere3D.new()
		sphere.name = str(itt)
		sphere.material = mat
		sphere.radius = 0.1
		sphere.position = i
		root.add_child(sphere)
		itt += 1
	
	root.name = sceneName
	
	if save:
		ENTG.saveNodeAsScene(root,path)
	return root

static func addChildNowOrDeferred(parent,child):
	var numChild = parent.get_child_count()
	parent.add_child(child)
	var postNumChild = parent.get_child_count()
	
	if numChild != postNumChild:
		return
		
	parent.add_child.call_deferred(child)
	
static func rawRaycast(world : World3D,start : Vector3,end : Vector3,exclude : Array= []):
	var spaceState = world.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = exclude
	return spaceState.intersect_ray(query)  # Returns a dictionary with collision info or empty if no hit


static func getChildOfClass(node,type):
	for c in node.get_children():
		if c.get_class() == type:
			return c
			
	return null

static func randomColor() -> Color:
	return Color(randf(), randf(), randf(), 1.0) 

static func getTreeStructure(node: Node, depth: int = 0, is_last: bool = true) -> String:
	var output := ""
	var indent := ""

	# Manually build the indentation string
	for i in range(depth - 1):
		indent += "┃  "
	if depth > 0:
		indent += "┖╴" if is_last else "┠╴"

	output += indent + node.name + "\n"

	var child_count := node.get_child_count()
	for i in range(child_count):
		var child := node.get_child(i)
		output += getTreeStructure(child, depth + 1, i == child_count - 1)

	return output


static func fetchConsole(tree : SceneTree) -> Node:
	if tree.has_meta("consoleNode"):
		return tree.get_meta("consoleNode")
		
	var consoleNode : Node = load("res://addons/gameAssetImporter/scenes/console/consoleWindow.tscn").instantiate()
	consoleNode.visible = false
	
	tree.get_root().call_deferred("add_child",consoleNode)
	tree.set_meta("consoleNode",consoleNode)
	#consoleNode.popup_centered_ratio()
	
	return consoleNode

static func fetchTimingsDebug(tree : SceneTree) -> Node:
	if tree.has_meta("timingsDebug"):
		return tree.get_meta("timingsDebug")
		
	var timingsNode : Node = load("res://addons/gameAssetImporter/scenes/timingsDebug/timingsDebugWindow.tscn").instantiate()
	timingsNode.visible = false
	
	tree.get_root().call_deferred("add_child",timingsNode)
	tree.set_meta("timingsDebug",timingsNode)
	return timingsNode

		

static func registerConsoleCommands(tree:SceneTree,script):
	fetchConsole(tree).registerScript(script)

static func rgbToHSV(r: float, g: float, b: float) -> Array:
	r /= 255.0
	g /= 255.0
	b /= 255.0

	var max_val = max(r, g, b)
	var min_val = min(r, g, b)
	var h = 0.0
	var s = 0.0
	var v = max_val

	var d = max_val - min_val
	s = 0 if max_val == 0 else d / max_val

	if max_val == min_val:
		h = 0.0 # achromatic
	else:
		match max_val:
			r:
				h = (g - b) / d + (6 if g < b else 0)
			g:
				h = (b - r) / d + 2
			b:
				h = (r - g) / d + 4
		h /= 6.0

	return [h, s, v]

static func intToHex(x : int):
	return "0x%x" % x

static func printFileAsHex(filePath : StringName):
		var data = FileAccess.get_file_as_bytes(filePath)
	
		var file
		
		var hex = ""
		
		for i in data:
			hex += "%0x," % i
		
		print(hex)
		

static func getChildrenRecursive(node : Node) -> Array[Node]:
	var ret : Array[Node] = []
	
	for child : Node in node.get_children():
		ret.append(child)
		ret += getChildrenRecursive(child)
	
	return ret
		

static func playGrowAnimForNode(node,endScale,time = 0.2):
	var tween : Tween = node.create_tween()
	tween.tween_property(node, "scale", endScale,time/2.0)

static func playShrinkAnimForNode(node,endScale,time = 0.2):
	var tween : Tween = node.create_tween()
	tween.tween_property(node, "scale", endScale,time/2.0)
	
	

static func playGrowMaskAnimForNode(node : Control,endScale,time = 0.2):
	var fakeMask = node.duplicate()
	fakeMask.position = node.global_position
	#fakeMask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.get_tree().get_root().add_child(fakeMask)
	
	if node.has_meta("animating") and node.get_meta("animating"):
		return
	
	node.set_meta("animating", true)  # Mark animation as active

	var tweenPos: Tween = node.create_tween()
	var tweenScale: Tween = node.create_tween()
	var startPos = node.global_position

	# Calculate offset to keep GUI centered
	var size = node.get_rect().size
	var scaleDiff = endScale - Vector2.ONE # for now we will just assume unit transform
	var offset = (scaleDiff * size) / 2.0

	var endPos = startPos - offset  # Adjusted position to maintain centering
	
	# Animate to the enlarged position and scale
	tweenPos.tween_property(fakeMask, "position", endPos, time / 2.0)
	tweenScale.tween_property(fakeMask, "scale", endScale, time / 2.0)

	await node.get_tree().create_timer(time / 2.0).timeout
#
	#Create new tweens to return to the original state
	tweenPos = node.create_tween()
	tweenScale = node.create_tween()

	tweenPos.tween_property(fakeMask, "position", startPos, time / 2.0)
	tweenScale.tween_property(fakeMask, "scale", Vector3.ONE, time / 2.0)#assume indentiy trasformm

	await node.get_tree().create_timer(time / 2.0).timeout

	node.set_meta("animating", false)  # Mark animation as finished
	

static func playGrowAndShrinkAnimForNode(node,startScale,endScale,time = 0.2):
	var tween : Tween = node.create_tween()
	tween.tween_property(node, "scale", endScale,time/2.0)
	await node.get_tree().create_timer(0.2).timeout
	
	tween = node.create_tween()
	tween.tween_property(node, "scale", startScale,time/2.0)


static func playCenteredGrowAnimForNode(node, startScale, endScale, time = 0.2):
	# Prevent running if there's an active tween
	if node.has_meta("animating") and node.get_meta("animating"):
		return
	
	node.set_meta("animating", true)  # Mark animation as active

	var tweenPos: Tween = node.create_tween()
	var tweenScale: Tween = node.create_tween()
	var startPos = node.position

	# Calculate offset to keep GUI centered
	var size = node.get_rect().size
	var scaleDiff = endScale - startScale
	var offset = (scaleDiff * size) / 2.0

	var endPos = startPos - offset  # Adjusted position to maintain centering

	# Animate to the enlarged position and scale
	tweenPos.tween_property(node, "position", endPos, time / 2.0)
	tweenScale.tween_property(node, "scale", endScale, time / 2.0)

	await node.get_tree().create_timer(time / 2.0).timeout

	# Create new tweens to return to the original state
	tweenPos = node.create_tween()
	tweenScale = node.create_tween()

	tweenPos.tween_property(node, "position", startPos, time / 2.0)
	tweenScale.tween_property(node, "scale", startScale, time / 2.0)

	await node.get_tree().create_timer(time / 2.0).timeout

	node.set_meta("animating", false)  # Mark animation as finished


static func removeUnessecaryLines(verts:PackedVector3Array):
	#EGLO.saveVertArrAsSpheres(verts,"a1")
	var ret : PackedVector3Array = []
		
	for i in verts.size():
		var pIdx = i-1
		
		if pIdx == -1: 
			pIdx = verts.size()-1

		var prevVert = verts[pIdx]
		var curVert = verts[i]
		var nextVert = verts[(i+1)%verts.size()]
		
		var diff1 = (prevVert - curVert).normalized()
		var diff2 = (curVert-nextVert).normalized()
		
		#print("verts %s,%s,%s : %s %s"%[pIdx,i,(i+1)%verts.size(),diff1,diff2])
		
		if (diff1) != (diff2):
			ret.append(curVert)
		
	
	#EGLO.saveVertArrAsSpheres(ret,"b1")
	return ret
	

static func simplify_polyline(verts: PackedVector3Array) -> PackedVector3Array:
	if verts.size() < 3:
		return verts  # Not enough vertices to simplify

	var result = PackedVector3Array()
	result.append(verts[0])  # Always keep the first vertex

	for i in range(1, verts.size() - 1):
		var prev = verts[i - 1]
		var current = verts[i]
		var next = verts[i + 1]

		# Check if the current vertex lies on the line between prev and next
		if !is_point_on_line(prev, current, next):
			result.append(current)  # Keep the vertex if it's not on the line

	result.append(verts[-1])  # Always keep the last vertex
	return result

static func is_point_on_line(a: Vector3, b: Vector3, c: Vector3, epsilon: float = 0.0001) -> bool:
	# Calculate the direction vector from a to c
	var direction = c - a
	var length = direction.length()

	# If the line segment is too short, consider all points collinear
	if length < epsilon:
		return true

	# Normalize the direction vector
	direction = direction.normalized()

	# Calculate the vector from a to b
	var ab = b - a

	# Project ab onto the direction vector
	var projection = ab.dot(direction)

	# Calculate the closest point on the line to b
	var closest_point = a + direction * projection

	# Check if b is close enough to the closest point on the line
	return (b - closest_point).length() < epsilon


static func planesToMesh(planeNormals : PackedVector3Array,planeDists: PackedFloat32Array):
	var csg : CSGPrimitive3D = CSGBox3D.new()
	csg.size = Vector3(1000,1000,1000)
	
	cutCSGwithPlanes(csg,planeNormals,planeDists)
	return csg

static func cutCSGwithPlanes(csg : CSGPrimitive3D,planeNormal : PackedVector3Array,planeDist: PackedFloat32Array):
	for i in planeNormal.size():
		csg.add_child(cutCSGwithPlane(csg,planeNormal[i],planeDist[i]))
	
	
	

static func cutCSGwithPlane(csg : CSGPrimitive3D,planeNormal,planeDist):
	

	var planeBox := CSGBox3D.new()
	planeBox.size = Vector3(1000,1000,1000)
	planeBox.position = (planeNormal*planeDist) + (planeBox.size*0.5)*planeNormal
	planeBox.rotation = normal_to_euler(planeNormal)
	planeBox.operation = CSGShape3D.OPERATION_SUBTRACTION
	planeBox.top_level = true
	csg.add_child(planeBox)

static func vertArrToCSG(points : Array[PackedVector3Array]):
	
	var planeDists = []
	var planeNormals = []
	
	for i in points:
		var plane = pointsToPlane(i)
		planeNormals.append(plane[0])
		planeDists.append(plane[1])
		
	
	var csg = planesToMesh(planeNormals,planeDists)
	csg.name = "filp"
	var mesh : ArrayMesh =  csg.bake_static_mesh()
	ENTG.saveNodeAsScene(csg)
	ResourceSaver.save(mesh,"res://dbg/brush.tres")
	breakpoint
	

static func normal_to_euler(normal: Vector3) -> Vector3:
	var quat = Quaternion(Vector3.FORWARD, normal.normalized()) 
	var euler = quat.get_euler()
	return euler 
	
static func pointsToPlane(points : PackedVector3Array):
	var normal = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var dist = -normal.dot(points[0])
	
	return [normal,dist]
	
static func showMessage(node : Node,message : String):
	var popup := AcceptDialog.new()
	popup.dialog_text = message
	node.add_child(popup)
	
	popup.popup_centered()
	
static func showOption(node : Node,message : String,yesText : String,noText : String) -> ConfirmationDialog:
	var popup := ConfirmationDialog.new()
	popup.dialog_text = message
	popup.ok_button_text = yesText
	popup.cancel_button_text = noText
	node.add_child(popup)
	
	popup.popup_centered()
	return popup

static func drawAABBoultine(mesh_instance: MeshInstance3D):
	var aabb = mesh_instance.mesh.get_aabb()
	var immediate_mesh = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.RED

	var mesh_instance_outline = MeshInstance3D.new()
	mesh_instance_outline.mesh = immediate_mesh
	mesh_instance_outline.material_override = mat
	mesh_instance.get_parent().add_child(mesh_instance_outline)
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var corners = get_aabb_corners(aabb)

	# Connect corners with lines
	var edges = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]

	for edge in edges:
		immediate_mesh.surface_add_vertex(corners[edge[0]])
		immediate_mesh.surface_add_vertex(corners[edge[1]])

	immediate_mesh.surface_end()

	mesh_instance_outline.transform.origin = mesh_instance.transform.origin
	
	return mesh_instance_outline
	
static func get_aabb_corners(aabb: AABB) -> Array:
	var origin = aabb.position
	var size = aabb.size

	return [
		origin,
		origin + Vector3(size.x, 0, 0),
		origin + Vector3(size.x, 0, size.z),
		origin + Vector3(0, 0, size.z),
		origin + Vector3(0, size.y, 0),
		origin + Vector3(size.x, size.y, 0),
		origin + Vector3(size.x, size.y, size.z),
		origin + Vector3(0, size.y, size.z),
	]


static func findCamera3D(node : Node) -> Camera3D:
	var parent : Node = node
	
	while(true):
		parent = parent.get_parent()
		
		if parent == null:
			return null
		
		if parent is Camera3D:
			return parent
			
		
		
	return null
		
	
static func multiHitRaycast(world: World3D, start: Vector3, end: Vector3, max_hits: int = 5) -> Array:
	var results: Array = []
	var from = start
	var direction = (end - start).normalized()
	var remaining_distance = (end - start).length()
	var exclude: Array = []

	for i in range(max_hits):
		var to = from + direction * remaining_distance
		var result = rawRaycast(world, from, to, exclude)

		if result.is_empty():
			break

		results.append(result)

		var hit_position = result.position
		var distance_traveled = (hit_position - from).length()
		remaining_distance -= distance_traveled
		if remaining_distance <= 0.0:
			break

		# Nudge the start slightly beyond the last hit
		from = hit_position + direction * 0.01
		exclude.append(result.collider)

	return results


static func get16AsBytes(b16) -> PackedByteArray:
	var buffer = StreamPeerBuffer.new()
	buffer.put_16(b16)
	buffer.seek(0)   
	var bytes = buffer.get_data_array()
	return bytes

static func quickQuitInput(tree : SceneTree,combo = [KEY_CTRL,KEY_W]):
	if Input.is_key_pressed(combo[0]):
		if Input.is_key_pressed(combo[1]):
			tree.quit()

static func quickFullscreen(tree : SceneTree):
	if Input.is_key_pressed(KEY_ALT):
		if Input.is_key_pressed(KEY_ENTER):
			tree.get_root().get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((tree.get_root().get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (tree.get_root().get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
			
static func createPerformanceInfoOverlay():
	return load("res://addons/gameAssetImporter/scenes/perfOverlay/perfInfo.tscn").instantiate()

static func addActionAndKey(actionName : String,keycode : Key):
	InputMap.add_action(actionName)
	addKeyToAction(actionName,keycode)
	
static func addKeyToAction(actionName : String,keycode : Key):
	var ev = InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(actionName, ev)
	
