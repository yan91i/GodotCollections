extends Card
class_name DraftCardGraphicNode

var card_content: DraftCard
@export var order_id : int
const SEPARATION = 0.25

@onready var chosen : bool = false: set = set_chosen

signal zoomed_in

func set_chosen(v):
	chosen = v
	if not is_inside_tree():
		await self.ready
	$Ground/Select.visible = chosen
	
func set_minigame_label(name):
	$"%MinigameLabel".text = name
	if card_content is MysteryCard:
		$"%BottomLabel".text = 'minigame'

func set_minigame_icon(texture):
	$Ground/Front/MinigameIcon.texture = texture
	$Ground/Front/MinigameIconShadow.texture = texture

func set_content_card(card: DraftCard):
	# default
	card_content = card
	set_minigame_label(card.get_name())
	set_minigame_icon(card.get_icon())
	
	#$Ground/Front/Background.modulate = Color('#e0e0e0')
	var tint = card.get_tint()
	if tint:
		$'%Border'.self_modulate = tint
	else:
		$'%Border'.self_modulate = Color(0,0,0,0) # invisible
	
	# new
	get_node('%NewLabel').visible = card_content.is_new()
	
	# mystery
	#$Ground/Front/MinigameLabelWrapper.visible = not card is MysteryCard
	$Ground/Front/MinigameIcon.visible = not card is MysteryCard and not card is RandomCard
	$Ground/Front/MinigameIconShadow.visible = not card is MysteryCard and not card is RandomCard
	if card is MysteryCard or card is RandomCard:
		$Ground/Front/Background.texture = card.get_cover()
		$Ground/Front/Background.modulate = Color.WHITE
		$"%BottomLabel".visible = true
	else:
		# winter
		if card.is_winter():
			$Ground/Front/MinigameLabelWrapper/WinterLabel.visible = true
			$Ground/Front/Border.self_modulate = Color('#9be9ff')
			$Ground/Front/Border.self_modulate.b = 1.2 # glow
			$Ground/Front/Border.z_index = -1
		
		# perfectionist
		if card.is_perfectionist():
			get_node('%PerfectionistStar').visible = true
			get_node('%BottomLabel').visible = true
	#		$Ground/Front/Border.self_modulate = Color('#ff5577') # takes priority over winter
		
	# suits
	if card is MysteryCard or card is RandomCard:
		$'%MinigameLabel'.visible = false
		$'%BottomLabel'.visible = false
#		$'%MinigameLabel'.self_modulate = global.SUIT_COLORS[card.get_color()].lightened(0.2)
#		$'%BottomLabel'.modulate = global.SUIT_COLORS[card.get_color()].lightened(0.2)
	else:
		var suit_top = card.get_suit_top()
		var suit_bottom = card.get_suit_bottom()
		if suit_top:
			$"%SuitTopLeft".texture = load("res://assets/sprites/signs/suits/"+suit_top+".png")
			$'%SuitTopLeft'.self_modulate = global.SUIT_COLORS[suit_top]
			$'%Background'.self_modulate = global.SUIT_COLORS[suit_top]
		if suit_bottom:
			$"%SuitBottomRight".texture = load("res://assets/sprites/signs/suits/"+suit_bottom+".png")
			$'%SuitBottomRight'.self_modulate = global.SUIT_COLORS[suit_bottom]
			$'%MinigameLabel'.self_modulate = global.SUIT_COLORS[suit_bottom].lightened(0.2) # TBD double color
			
		if suit_top != suit_bottom:
			$'%HalfBackground'.self_modulate = global.SUIT_COLORS[suit_bottom]
			$'%HalfBackground'.visible = true
			
# @override
func select():
	super.select()
	$"%SuitTopLeft".self_modulate = Color(0,0,0,0.75)
	$"%SuitBottomRight".self_modulate = Color(0,0,0,0.75)
	$'%Background'.modulate = Color(1.15,1.15,1.15)
	
# @override
func tap(author):
	super.tap(author)
	if author is Ship:
		Events.emit_signal("card_tapped", author, self)
		print("{minigame} tapped by {author_name}".format({"minigame": card_content.get_id(), "author_name":author.info_player.get_id()}))

func gracefully_go_to(point: Vector2, angle: float = 0.0, duration: float = 0.7, easing = Tween.EASE_IN_OUT) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(easing)
	tween.tween_property(self, 'position', point, duration)
	tween.parallel().tween_property(self, 'rotation', angle, duration)

@onready var normal_scale = scale
@onready var normal_position = global_position
@onready var normal_rotation = rotation_degrees

func back_to_normal():
	global_position = normal_position
	rotation_degrees =  normal_rotation
	scale = normal_scale
	 
func gracefully_zoom_in():
	normal_position = global_position
	normal_rotation = rotation_degrees
	normal_scale = scale
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	tween.tween_property(self, 'global_position', Vector2(0, 300), 0.8)
	var waiting_tweener = tween.parallel().tween_property(self, 'rotation_degrees', 0.0, 0.7)
	tween.tween_property(self, 'scale', Vector2(8, 8), 1.4)
	await waiting_tweener.finished
	emit_signal("zoomed_in")
	await tween.finished
	back_to_normal()
	
func reposition(target_position: Vector2, target_rotation := 0.0):
	gracefully_go_to(target_position, deg_to_rad(target_rotation))
	return 
	# called to reposition the card. need a tween animation
	self.position = target_position
	self.rotation = deg_to_rad(target_rotation)
