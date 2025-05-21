extends Sprite2D

@export var species : Resource: set = set_species

@onready var trail = $Trail


func set_species(value):
	species = value
	if is_inside_tree():
		await self.ready

	texture = species.ship_off
