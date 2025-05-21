###############################################################################
# Librerama                                                                   #
# Copyright (C) 2023 Michael Alexsander                                       #
#-----------------------------------------------------------------------------#
# This file is part of Librerama.                                             #
#                                                                             #
# Librerama is free software: you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# Librerama is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with Librerama.  If not, see <http://www.gnu.org/licenses/>.          #
###############################################################################

extends Area2D


signal selected(index: int)
signal animation_flip_ended

var _face := -1


func _input_event(
		_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		flip_card()

		selected.emit(get_index())


func make_correct() -> void:
	_face = randi() % 2


func flip_card(is_animating:=true) -> void:
	if not is_animating:
		_switch_face()

		return

	($AnimationPlayer as AnimationPlayer).play("card_flip")


func set_selection(is_enabled: bool) -> void:
	($CollisionShape2D as CollisionShape2D).disabled = not is_enabled

	if is_enabled:
		($AnimationPlayer as AnimationPlayer).play("highlight_blink")
	else:
		($Highlight as Sprite2D).self_modulate.a = 0

		if ($AnimationPlayer as AnimationPlayer).current_animation ==\
				"highlight_blink":
			($AnimationPlayer as AnimationPlayer).stop()


func _switch_face() -> void:
	var card := $Card as Sprite2D
	if card.frame > 0:
		card.frame = 0 # Set to the backwards frame, as it was facing fowards.
	else:
		if _face != -1:
			# Set the face frame, if correct, past the backwards index.
			card.frame = _face + 1
		else:
			# Pick one of the wrong faces.
			card.frame = card.hframes + randi() % 2


func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "card_flip":
		animation_flip_ended.emit()
