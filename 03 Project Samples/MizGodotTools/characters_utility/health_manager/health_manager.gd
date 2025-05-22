class_name HealthManager extends Node2D

@onready var blood_spawner = $BloodSpawner

@export var max_health = 100
@onready var cur_health = max_health

@export var health_regen_rate = -1.0 # health per second, negative is no regen
var fractional_health_regened = 0.0

# save space in save files for enemies and things that will never upgrade/change
# max health or health regen
@export var only_save_cur_health = true 

signal health_updated(cur_health: int, max_health: int)
signal health_updated_percentage(health_full_percentage: float)
signal died
signal healed
signal healed_from_regen
signal took_damage

func _ready():
	set_health_regen_rate(health_regen_rate)

func set_health_regen_rate(regen_rate: float):
	health_regen_rate = regen_rate
	set_process(health_regen_rate > 0)

func set_cur_health(h: int):
	cur_health = h
	on_health_updated()

func set_max_health(h : int):
	max_health = h
	on_health_updated()

func hurt(damage_data : DamageData):
	if is_dead():
		return
	if damage_data.damage_amount > 0:
		blood_spawner.spawn_blood_from_damage_data(damage_data)
	
	took_damage.emit()
	cur_health -= damage_data.damage_amount
	on_health_updated()
	if is_dead():
		died.emit()
		if has_node("DeathSounds") and damage_data.play_sound:
			get_node("DeathSounds").play()
	else:
		if has_node("HurtSounds") and damage_data.play_sound:
			get_node("HurtSounds").play()

func heal(amount: int, from_regen=false):
	cur_health += amount
	if cur_health > max_health:
		cur_health = max_health
	on_health_updated()
	
	if from_regen:
		healed_from_regen.emit()
	else:
		healed.emit() # connect to a healing item sound or something

func on_health_updated():
	health_updated.emit(cur_health, max_health)
	health_updated_percentage.emit(clamp(float(cur_health) / max_health, 0.0, 1.0))

func is_dead():
	return cur_health <= 0

func _process(delta):
	process_health_regen(delta)

func process_health_regen(delta):
	fractional_health_regened += health_regen_rate * delta
	var health_int = int(fractional_health_regened)
	fractional_health_regened -= health_int
	heal(health_int, true)

func get_save_data() -> Dictionary:
	var save_data = {}
	save_data.cur_health = cur_health
	if !only_save_cur_health:
		save_data.max_health = max_health
		save_data.health_regen_rate = health_regen_rate
	return save_data

func load_save_data(save_data: Dictionary):
	if "cur_health" in save_data:
		set_cur_health(roundi(save_data.cur_health))
	if "max_health" in save_data:
		set_max_health(roundi(save_data.max_health))
	if "health_regen_rate" in save_data:
		set_health_regen_rate(roundi(save_data.health_regen_rate))
	if is_dead():
		died.emit()
