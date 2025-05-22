class_name DamageData extends Node

## For HealthManager
var damage_amount = 0

## For BloodSpawner
var spawn_blood : bool = true
var spawn_extra_blood : bool = false
var spawn_blood_cloud : bool = false
var play_sound : bool = true
var damage_direction : Vector2 = Vector2.RIGHT
var damage_position : Vector2 # point on hitbox that was hit
var hit_normal : Vector2 = Vector2.RIGHT

## Other
var source_of_damage : Node2D # character responsible for dealing this damage
var stun_time = -1
var knockback_modifier = 1.0
