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

var _debug_code := 0


func _ready() -> void:
	($Hopper as Area2D).position_limit =\
			($Bunbun/HopperLimit as Marker2D).global_position.x

	($Hopper as Area2D).goal_area = $Bunbun as Area2D


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	if difficulty >= 2:
		($PlatformPosition/Platform as Area2D).hide()
		($PlatformPosition/Platform/CollisionShape2D as CollisionShape2D).\
				disabled = true
		($PlatformPosition/MovingPlatform as InstancePlaceholder).\
				create_instance(true)
	if difficulty == 3:
		($PlatformPosition2/Platform as Area2D).hide()
		($PlatformPosition2/Platform/CollisionShape2D as CollisionShape2D).\
				disabled = true
		($PlatformPosition2/MovingPlatform as InstancePlaceholder).\
				create_instance(true)

	_debug_code = debug_code
	if debug_code == 1:
		($Hopper as Area2D).is_never_splashing = true


func nanogame_start() -> void:
	($Hopper as Area2D).activate_target()


func _on_hopper_landed(area: Area2D) -> void:
	if area == null:
		if _debug_code != 1:
			($Bunbun as Area2D).laugh()

			ended.emit(false)

		return

	area.monitorable = false

	if area == ($Bunbun as Area2D):
		($Bunbun as Area2D).love()

		ended.emit(true)
	elif area.has_method("move"): # Check if it's a moving platform.
		area.move(($Hopper as Area2D).get_path())

		($Hopper as Area2D).jumped.connect(area.stop, CONNECT_ONE_SHOT)
