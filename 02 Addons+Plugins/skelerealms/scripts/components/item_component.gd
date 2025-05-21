@tool
class_name ItemComponent
extends SKEntityComponent
## Keeps track of item data


const DROP_DISTANCE:float = 2
const NONE:StringName = &""


## What inventory this item is in.
@export var contained_inventory: StringName = NONE:
	get:
		return contained_inventory
	set(val):
		contained_inventory = val
		if parent_entity:
			parent_entity.supress_spawning = not contained_inventory == NONE # prevent spawning if item is in inventory
## Whether this item is in inventory or not.
@export var in_inventory:bool:
	get:
		return not contained_inventory == NONE
## If this is a quest item.
@export var quest_item:bool
## If this item is "owned" by someone.
@export var item_owner:StringName = NONE:
	get:
		return item_owner
	set(val):
		item_owner = val
		if get_parent() == null: #stops this from being called while setting up
			return
		if val == &"":
			inv.interact_verb = "TAKE"
		else:
			# TODO: Determine using worth and owner relationships
			inv.interact_verb = "STEAL"
var stolen:bool ## If this has been stolen or not.
var durability:float ## This item's durability, if your game has condition/durability mechanics like Fallout or Morrowind.
var psc:PuppetSpawnerComponent
var inv:InteractiveComponent


## Shorthand to get an item component for an entity by ID.
static func get_item_component(id:StringName) -> ItemComponent:
	var eop = SKEntityManager.instance.get_entity(id)
	if not eop:
		return null
	var icop = eop.get_component("ItemComponent")
	if icop:
		return icop
	else:
		return null


func _init() -> void:
	name = "ItemComponent"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super._ready()
	if parent_entity:
			parent_entity.supress_spawning = in_inventory
	psc = parent_entity.get_component("PuppetSpawnerComponent")
	inv = parent_entity.get_component("InteractiveComponent")


func _entity_ready() -> void:
	inv.interacted.connect(interact.bind())
	inv.translation_callback = get_translated_name.bind()
	if item_owner == &"":
		inv.interact_verb = "TAKE"
	else:
		# TODO: Determine using worth and owner relationships
		inv.interact_verb = "STEAL"


func _process(delta):
	if Engine.is_editor_hint():
		return
	if in_inventory:
		parent_entity.position = SKEntityManager.instance.get_entity(contained_inventory).position
		parent_entity.world = SKEntityManager.instance.get_entity(contained_inventory).world


## Move this to another inventory. Adds and removes the item from the inventories.
func move_to_inventory(refID:StringName):
	# remove from inventory if we are in one
	if in_inventory:
		SKEntityManager.instance\
			.get_entity(contained_inventory)\
			.get_component("InventoryComponent")\
			.remove_from_inventory(parent_entity.name)
	
	# drop if moved to inventory is empty
	if refID == "":
		drop()
		return
	
	# add to new inventory
	SKEntityManager.instance\
		.get_entity(refID)\
		.get_component("InventoryComponent")\
		.add_to_inventory(parent_entity.name)
	
	contained_inventory = refID
	
	if in_inventory:
		psc.despawn()


## Drop this on the ground.
func drop():
	var e:SKEntity = SKEntityManager.instance.get_entity(contained_inventory)
	var drop_dir:Quaternion = e.quaternion
	print(drop_dir.get_euler().normalized() * DROP_DISTANCE)
	# This whole bit is genericizing dropping the item in front of the player. It's meant to be used with the player, it should work with anything with a puppet.
	if in_inventory:
		SKEntityManager.instance.get_entity(contained_inventory)\
			.get_component(&"InventoryComponent")\
			.remove_from_inventory(parent_entity.name)

	# raycast in front of puppet if possible to do wall check
	if e.in_scene and psc:
		print("has puppet component, in scene")
		if psc.puppet:
			print("puppet exists")
			# construct raycast
			var from = parent_entity.position + Vector3(0, 1.5, 0)
			var to = parent_entity.position + Vector3(0, 1.5, 0) + (drop_dir.get_euler().normalized() * DROP_DISTANCE)
			var query = PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, SkeleRealmsGlobal.get_child_rids(psc.unwrap().puppet))
			await get_tree().physics_frame
			var space = (psc.puppet as Node3D).get_world_3d().direct_space_state
			# FIXME: Direction is weird
			var res = space.intersect_ray(query)
			if res.is_empty():
				# else spawn in front
				print("didn't hit anything")
				parent_entity.position = to
				contained_inventory = NONE
				psc.spawn()
				return
			else:
				# if hit something, spawn at hit position
				print(res)
				parent_entity.position = res["position"] # TODO: Compensate for item size
				contained_inventory = NONE
				psc.spawn()
				return

	parent_entity.position = parent_entity.position + Vector3(0, 1.5, 0)

	contained_inventory = NONE
	psc.spawn()


## Interact with this item. Called from [InteractiveComponent].
func interact(interacted_refID):
	move_to_inventory(interacted_refID)
	if not interacted_refID == item_owner and not item_owner == "":
		printe("Stolen.")
		stolen = true
		CrimeMaster.crime_committed.emit(
			Crime.new(&"theft",
			interacted_refID,
			item_owner),
			parent_entity.position
			)


## Allows an item to be taken without being stolen.
func allow() -> void:
	item_owner = &"";


## Whether it has a component type. [code]c[/code] is the name of the component type, like "HoldableDataComponent".
func has_component(c:String) -> bool:
	return get_children().any(func(x:ItemDataComponent): return x.get_type() == c)


## Gets the first component of a type. [code]c[/code] is the name of the component type, like "HoldableDataComponent".
func get_component(c:String) -> ItemDataComponent:
	var valid_components = get_children().filter(func(x:ItemDataComponent): return x.get_type() == c)
	if valid_components.is_empty():
		return null
	else:
		return valid_components[0]


func save() -> Dictionary:
	return {
		"contained_inventory" = contained_inventory,
		"item_owner" = item_owner
	}


func load_data(data:Dictionary):
	contained_inventory = data["contained_inventory"]
	item_owner = data["item_owner"]


func get_translated_name() -> String:
	var t = tr(parent_entity.name)
	if t == parent_entity.name:
		return tr(parent_entity.form_id)
	else :
		return t


func gather_debug_info() -> String:
	return """
[b]ItemComponent[/b]
	Contained Inventory: %s
	Owner: %s
	Quest Item?: %s
	""" % [
		contained_inventory if in_inventory else "None",
		item_owner,
		quest_item
	]


func get_dependencies() -> Array[String]:
	return [
		"PuppetSpawnerComponent",
		"InteractiveComponent"
	]
