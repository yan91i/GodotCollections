class_name HitBox extends Area2D

signal hitbox_hurt(damage_data: DamageData)
signal took_damage

var root_node : CharacterBody2D

# use for headshots/vulnerable points
@export var damage_multiplier = 1.0
@export var spawn_extra_blood_on_hit = false

func hurt(damage_data : DamageData):
	damage_data.damage_amount = roundi(damage_multiplier * damage_data.damage_amount)
	damage_data.spawn_extra_blood = spawn_extra_blood_on_hit
	hitbox_hurt.emit(damage_data)
	if damage_data.damage_amount > 0:
		took_damage.emit()

func disable():
	collision_layer = 0

func enable():
	collision_layer = 4
