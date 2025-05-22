class_name Destructible extends Node3D
var healt_points = 2
var current_tween
@export var explosion:PackedScene
@export var body:RigidBody3D

@export var drop_object:PackedScene = null #should be Collectable
@export_range(0,1) var drop_probability = 0

func _ready():
	if body != null:
		body.body_entered.connect(self._on_frozen_body_entered)


func _input(event):
	# Use for test purposes
	pass
	#if event.is_action_pressed("p1_jump"):
		#healt_points -= 1
		#run_animation()
		#print("health: ", healt_points)
		#if healt_points < 0:
			#print("dead!")
			#queue_free()
			#run_explosion()


func run_animation():
	if current_tween != null and current_tween.is_running():
		current_tween.kill()
		self.scale = Vector3.ONE 
	current_tween = self.create_tween()
	current_tween.tween_property(self, "scale", Vector3(0.8,1.2,0.8), 0.2).set_trans(Tween.TRANS_BACK)
	current_tween.tween_property(self, "scale", Vector3.ONE, 0.1)
	#tween.tween_property(node, "modulate", Color.RED, 1)


func run_explosion():
	if explosion == null:
		return
	var node = explosion.instantiate()
	node.emitting = true
	node.position = self.position + Vector3(0,2,0)
	add_sibling(node)

func drop_item():
	if drop_probability <= 0 or drop_object == null:
		return
	if randf() <= drop_probability:
		var node  = drop_object.instantiate()
		node.position = self.position
		add_sibling(node) 

func _on_frozen_body_entered(colliding_body):
	if colliding_body.is_in_group("bullet"):
		print("hit by", colliding_body.name, "!")
		healt_points -= 1
		colliding_body.remove_from_group("bullet")
		run_animation()
	if healt_points <= 0:
		queue_free()
		run_explosion()
		drop_item()
