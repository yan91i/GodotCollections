extends Node2D


## TO USE: call start_smoke from external node
## note that gpu particles have a custom z index set

## I think I have it set up like this with RemoteTransform because even with 
## global drawing particles will move weirdly if a child of a rotating node


@export var emit_smoke_time = 2.0
@onready var gpu_particles_2d = $GPUParticles2D
@onready var smoke_timer = Timer.new()

func _ready():
	add_child(smoke_timer)
	smoke_timer.wait_time = emit_smoke_time
	smoke_timer.timeout.connect(end_smoke)
	
	gpu_particles_2d.emitting = false
	gpu_particles_2d.reparent.bind(get_tree().get_root()).call_deferred()
	gpu_particles_2d.add_to_group("instanced")

func start_smoke():
	gpu_particles_2d.emitting = true
	smoke_timer.start()

func end_smoke():
	gpu_particles_2d.emitting = false
