@tool
extends Gate
class_name PortalGate

@export var linked_to : PortalGate
@export var tint := Color('#ff6600'): set = set_tint
@export var inverted := false: set = set_inverted

func set_tint(v):
	tint = v
	if not is_inside_tree():
		await self.ready
	$RingPart.self_modulate = tint.lightened(0.3)
	$"%BottomRingPart".self_modulate = tint
	$"%Inside".modulate = tint
	$"%SpikeParticles2D".modulate = tint
	$"%ColoredParticles2D".modulate = tint
	
func set_inverted(v):
	inverted = v
	if inverted:
		$PortalEffect.scale.x = -1
		$"%GPUParticles2D".scale.x = -1
		$"%ColoredParticles2D".scale.x = -1
		
func set_width(v: float) -> void:
	super.set_width(v)
	if not is_inside_tree():
		await self.ready
	$"%GPUParticles2D".process_material.emission_box_extents.y = width / 550 * 250
	$"%ColoredParticles2D".process_material.emission_box_extents.y = width / 550 * 250
	$"%SpikeParticles2D".process_material.emission_box_extents.y = width / 550 * 250
	$"%GPUParticles2D".amount = width / 550 * 8
	$"%ColoredParticles2D".amount = width / 550 * 8
	$"%SpikeParticles2D".amount = width / 550 * 8
	$"%Inside".scale.y = width / 550 * 4.5
	
func _on_PortalGate_crossed(sth, _self, trigger):
	if not trigger:
		return
		
	if not self.is_linked():
		return
		
	var vector = sth.global_position - global_position
	sth.global_position = linked_to.global_position + vector
	sth.reset_physics_interpolation() # TBD when https://github.com/godotengine/godot/pull/92218 is merged, check if this is sufficient for correctly displaying player id on Ship wthout jumps
	
	assert(traits.has_trait(sth, 'Tracked'))
	traits.get_trait(sth, 'Tracked').reset()
	
	linked_to.act_as_if_crossed_by(sth)

func is_linked() -> bool:
	return linked_to != null
	
func enable() -> void:
	super.enable()
	$PortalEffect.visible = true
	
func disable() -> void:
	super.disable()
	$PortalEffect.visible = false
