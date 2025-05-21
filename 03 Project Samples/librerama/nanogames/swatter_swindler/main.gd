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

extends Node2D


signal ended(has_won: bool)

const Swatter = preload("swatter/swatter.tscn")

var _difficulty := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	var swatter_scale := 1.0
	match _difficulty:
		2:
			swatter_scale = 1.5
		3:
			swatter_scale = 2

	($Swatter as Area2D).set_swatter_scale(swatter_scale)

	if debug_code == 1:
		($Fly as Area2D).disable_hitbox()


func nanogame_start() -> void:
	_swat()


func _swat() -> void:
	($Swatter as Area2D).swat(($Fly as Area2D).position)


func _on_fly_hit() -> void:
	var music := $Music as AudioStreamPlayer
	music.stop()
	music.stream = preload("res://nanogames/swatter_swindler/_assets/fail.wav")
	music.play()

	ended.emit(false)
