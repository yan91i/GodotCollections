extends Node

class_name  WorldWrapObject2D
var objecttowrap
var wrappingcollisionshape : CollisionShape2D
var outercollisionshape
var limitx : int
var limity : int
var sidexwidth : int
var sideywidth : int

var boundary_dup_N: Sprite2D
var boundary_dup_S: Sprite2D
var boundary_dup_E: Sprite2D
var boundary_dup_W: Sprite2D
var boundary_dup_NW: Sprite2D
var boundary_dup_NE: Sprite2D
var boundary_dup_SW: Sprite2D
var boundary_dup_SE: Sprite2D
var boundary_dup_array := []
var boundary_dup_N_RT: RemoteTransform2D
var boundary_dup_S_RT: RemoteTransform2D
var boundary_dup_E_RT: RemoteTransform2D
var boundary_dup_W_RT: RemoteTransform2D
var boundary_dup_NW_RT: RemoteTransform2D
var boundary_dup_NE_RT: RemoteTransform2D
var boundary_dup_SW_RT: RemoteTransform2D
var boundary_dup_SE_RT: RemoteTransform2D
var boundary_dup_RT_array := []
var is_debugging: bool
var is_static: bool

func _init(objecttowrap, wrappingcollisionshape,outercollisionshape,is_debugging = false,is_static = false):
	self.objecttowrap = objecttowrap
	self.wrappingcollisionshape = wrappingcollisionshape # Must be a rectangular shape !!
	self.outercollisionshape = outercollisionshape # Must be a rectangular shape !!
	self.limitx = wrappingcollisionshape.shape.size.x/2
	self.limity = wrappingcollisionshape.shape.size.y/2
	self.sidexwidth = outercollisionshape.shape.size.x/2 - self.limitx
	self.sideywidth = outercollisionshape.shape.size.y/2 - self.limity
	self.is_debugging = is_debugging
	self.is_static = is_static
	if not is_static:
		create_dynamic_duplicates()
	if is_debugging:
		printvalues()
func create_dynamic_duplicates():
	# Create the visual duplicate (needs to be an actual visual node like Sprite2D)
	# Here are the top,bottom,left and right centers
	boundary_dup_N = Sprite2D.new()
	boundary_dup_S = Sprite2D.new()
	boundary_dup_E = Sprite2D.new()
	boundary_dup_W = Sprite2D.new()
	# Here are the Corners
	boundary_dup_NW = Sprite2D.new()
	boundary_dup_NE = Sprite2D.new()
	boundary_dup_SW = Sprite2D.new()
	boundary_dup_SE = Sprite2D.new()
	boundary_dup_array = [boundary_dup_N,boundary_dup_S,boundary_dup_E,boundary_dup_W,boundary_dup_NW,boundary_dup_NE,boundary_dup_SW,boundary_dup_SE]
	var texture = null
	var scale = null
	# Loading Sprite2D texture (Only the first Sprite2D present will be used)

	for child in self.objecttowrap.get_children():
		if child.get_class()=='Sprite2D' :
			texture = child.texture
			scale = child.scale
	if texture == null or scale == null:
		push_error("This node must include a Sprite2D node as child or be a Sprite2D.")
	for boundary_dup in boundary_dup_array:
		boundary_dup.texture = texture
		boundary_dup.scale = scale
		# For debugging purpose, color fake sprites
		if is_debugging:
			boundary_dup.modulate = Color(0, 0, 1)
		
		boundary_dup.visible = false 
		self.objecttowrap.add_child(boundary_dup)
	# Create RemoteTransform2D
	boundary_dup_N_RT = RemoteTransform2D.new()
	boundary_dup_S_RT = RemoteTransform2D.new()
	boundary_dup_E_RT = RemoteTransform2D.new()
	boundary_dup_W_RT = RemoteTransform2D.new()
	boundary_dup_NW_RT = RemoteTransform2D.new()
	boundary_dup_NE_RT = RemoteTransform2D.new()
	boundary_dup_SW_RT = RemoteTransform2D.new()
	boundary_dup_SE_RT = RemoteTransform2D.new()
	boundary_dup_RT_array = [boundary_dup_N_RT,boundary_dup_S_RT,boundary_dup_E_RT,boundary_dup_W_RT,boundary_dup_NW_RT,boundary_dup_NE_RT,boundary_dup_SW_RT,boundary_dup_SE_RT]
	# Set the remote path to point to your visual duplicate
	for i in len(boundary_dup_RT_array):
		boundary_dup_RT_array[i].remote_path = boundary_dup_array[i].get_path()
	# Configure which properties to update
	for boundary_dup_RT in boundary_dup_RT_array:
		boundary_dup_RT.update_position = false
		boundary_dup_RT.update_scale = false
		self.objecttowrap.add_child(boundary_dup_RT)
	
	
func gridPosition(global_position):
	if self.objecttowrap.global_position.y < - limity + sideywidth:
		if self.objecttowrap.global_position.x < - limitx + sidexwidth:
			return "NW"
		elif  self.objecttowrap.global_position.x > limitx - sidexwidth:
			return "NE"
		else :
			return "N"
	if self.objecttowrap.global_position.y > limity - sideywidth:
		if self.objecttowrap.global_position.x < - limitx + sidexwidth:
			return "SW"
		elif self.objecttowrap.global_position.x > limitx - sidexwidth:
			return "SE"
		else :
			return "S"
	if self.objecttowrap.global_position.x < - limitx + sidexwidth:
		return "W"
	if self.objecttowrap.global_position.x > limitx - sidexwidth:
		return "E"
	return null
# Suppose to work for every static object, Must be embedded in a Node2d(Sprite2D used as an object to wrap will result in error)
func create_static_duplicates(spawn_in):
	var gridposition = gridPosition(objecttowrap.global_position)
	var static_duplicates := []
	var duplicate_options = 0
	print("objecttowrap.position ",objecttowrap,objecttowrap.position)
	print("gridposition ",gridposition)
	if gridposition:
		#print("gridposition ",gridposition)
		# Apply sides first, side could also be a corner
		if "N" in gridposition:
			var Nduplicate = objecttowrap.duplicate(duplicate_options)
			static_duplicates.append(Nduplicate)
			Nduplicate.global_position = objecttowrap.global_position + Vector2(0,limity*2)
			if is_debugging:
				print("Adding static object ",objecttowrap," at position ", Nduplicate.global_position, " from position ", objecttowrap.global_position)
			spawn_in.add_child(Nduplicate)
		if "S" in gridposition:
			var Sduplicate = objecttowrap.duplicate(duplicate_options)
			static_duplicates.append(Sduplicate)
			Sduplicate.global_position = objecttowrap.global_position - Vector2(0,limity*2)
			if is_debugging:
				print("Adding static object ",objecttowrap," at position ", Sduplicate.global_position, " from position ", objecttowrap.global_position)
			spawn_in.add_child(Sduplicate)
		if "W"  in gridposition:
			var Wduplicate = objecttowrap.duplicate(duplicate_options)
			static_duplicates.append(Wduplicate)
			Wduplicate.global_position = objecttowrap.global_position + Vector2(limitx*2,0)
			if is_debugging:
				print("Adding static object ",objecttowrap," at position ", Wduplicate.global_position, " from position ", objecttowrap.global_position)
			spawn_in.add_child(Wduplicate)
		if "E"  in gridposition:
			var Eduplicate = objecttowrap.duplicate(duplicate_options)
			static_duplicates.append(Eduplicate)
			Eduplicate.global_position = objecttowrap.global_position - Vector2(limitx*2,0)
			if is_debugging:
				print("Adding static object ",objecttowrap," at position ", Eduplicate.global_position, " from position ", objecttowrap.global_position)
			spawn_in.add_child(Eduplicate)
		# Apply a corner if it is. Each corner use the opposite corner but also use the 2 opposite sides.
		match gridposition:
			"NW":
				var NWduplicate = objecttowrap.duplicate(duplicate_options)
				static_duplicates.append(NWduplicate)
				NWduplicate.global_position = objecttowrap.global_position + Vector2(limitx*2,limity*2)
				if is_debugging:
					print("Adding static object ",objecttowrap," at position ", NWduplicate.global_position, " from position ", objecttowrap.global_position)
				spawn_in.add_child(NWduplicate)

			"NE":
				var NEduplicate = objecttowrap.duplicate(duplicate_options)
				static_duplicates.append(NEduplicate)
				NEduplicate.global_position = objecttowrap.global_position + Vector2(-limitx*2,limity*2)
				if is_debugging:
					print("Adding static object ",objecttowrap," at position ", NEduplicate.global_position, " from position ", objecttowrap.global_position)
				spawn_in.add_child(NEduplicate)
			"SW":
				var SWduplicate = objecttowrap.duplicate(duplicate_options)
				static_duplicates.append(SWduplicate)
				SWduplicate.global_position = objecttowrap.global_position + Vector2(limitx*2,-limity*2)
				if is_debugging:
					print("Adding static object ",objecttowrap," at position ", SWduplicate.global_position, " from position ", objecttowrap.global_position)
				spawn_in.add_child(SWduplicate)
			"SE":
				var SEduplicate = objecttowrap.duplicate(duplicate_options)
				static_duplicates.append(SEduplicate)
				SEduplicate.global_position = objecttowrap.global_position + Vector2(-limitx*2,-limity*2)
				if is_debugging:
					print("Adding static object ",objecttowrap," at position ", SEduplicate.global_position, " from position ", objecttowrap.global_position)
				spawn_in.add_child(SEduplicate)
	
func process_dup_position():
	var gridposition = gridPosition(objecttowrap.global_position)
	# Hide everything by default
	for boundary_dup in boundary_dup_array:
		boundary_dup.visible = false
		
	if gridposition:
		#print("gridposition ",gridposition)
		# Apply sides first, side could also be a corner
		if "N" in gridposition:
			boundary_dup_N.visible = true
			boundary_dup_N.global_position = objecttowrap.global_position + Vector2(0,limity*2)
		if "S" in gridposition:
			boundary_dup_S.visible = true
			boundary_dup_S.global_position = objecttowrap.global_position - Vector2(0,limity*2)
		if "W"  in gridposition:
			boundary_dup_W.visible = true
			boundary_dup_W.global_position = objecttowrap.global_position + Vector2(limitx*2,0)
		if "E"  in gridposition:
			boundary_dup_E.visible = true
			boundary_dup_E.global_position = objecttowrap.global_position - Vector2(limitx*2,0)
		# Apply a corner if it is. Each corner use the opposite corner but also use the 2 opposite sides.
		match gridposition:
			"NW":
				boundary_dup_NW.visible = true
				boundary_dup_NW.global_position = objecttowrap.global_position + Vector2(limitx*2,limity*2)

			"NE":
				boundary_dup_NE.visible = true
				boundary_dup_NE.global_position = objecttowrap.global_position + Vector2(-limitx*2,limity*2)
			"SW":
				boundary_dup_SW.visible = true
				boundary_dup_SW.global_position = objecttowrap.global_position + Vector2(limitx*2,-limity*2)
			"SE":
				boundary_dup_SE.visible = true
				boundary_dup_SE.global_position = objecttowrap.global_position + Vector2(-limitx*2,-limity*2)

func printvalues():
	print("objecttowrap,wrappingcollisionshape,outercollisionshape")
	print(objecttowrap,wrappingcollisionshape,outercollisionshape)
	print("limitx,limity")
	print(limitx," ",limity)
	print("self.sidexwidth, self.sideywidth")
	print(self.sidexwidth," ",self.sideywidth)
