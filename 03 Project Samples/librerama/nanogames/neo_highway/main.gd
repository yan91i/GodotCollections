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

var _difficulty := 0

var _border_top := 0
var _border_bottom := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	_border_bottom = int(get_viewport_rect().size.y)

	var movement_line := Vector2(0, _border_bottom)
	if difficulty == 3:
		var top_obstacle := $Scenery/TopObstacle as TextureRect
		top_obstacle.show()
		_border_top = int(top_obstacle.size.y * top_obstacle.scale.y)

		var bottom_obstacle := $Scenery/BottomObstacle as TextureRect
		bottom_obstacle.show()
		_border_bottom -= int(bottom_obstacle.size.y * bottom_obstacle.scale.y)

		movement_line = Vector2(_border_top, _border_bottom)

	($Driver as Area2D).set_movement_line(movement_line)

	if debug_code == 1:
		($Driver as Area2D).disable_hitbox()


func nanogame_start() -> void:
	(%WarningTexture as TextureRect).visible = true

	_spawn_enemy()


func _spawn_enemy() -> void:
	var driver_height: int = ($Driver as Area2D).get_height()
	# Define the enemy position at the "Driver"'s current position randomly
	# offsetted by the "Driver"'s height, avoiding the top and bottom obstacles.
	@warning_ignore("narrowing_conversion")
	var enemy_position: int = clampi(($Driver as Area2D).position.y +
			randf_range(-driver_height, driver_height),
			_border_top + driver_height, _border_bottom - driver_height)

	(%WarningAnchor as Control).position.y = enemy_position

	if _difficulty == 1 or randi() % 2 == 0:
		(%WarningAnchor as Control).anchor_left = 1
		(%WarningAnchor as Control).anchor_right = 1

		(%WarningTexture as TextureRect).flip_h = false
		(%WarningTexture as TextureRect).pivot_offset.x = 52
	else:
		(%WarningAnchor as Control).anchor_left = 0
		(%WarningAnchor as Control).anchor_right = 0

		(%WarningTexture as TextureRect).flip_h = true
		(%WarningTexture as TextureRect).pivot_offset.x = -5

	(%WarningAnchor/Alarm as AudioStreamPlayer2D).play()

	($EnemySpawn as Timer).start()


func _on_driver_hit() -> void:
	($Music as AudioStreamPlayer).stop()

	($AnimationPlayer as AnimationPlayer).play("crash")

	($EnemySpawn as Timer).stop()

	ended.emit(false)


func _on_enemy_spawn_timeout() -> void:
	($CrashHitbox/CollisionShape2D as CollisionShape2D).position.y =\
			(%WarningAnchor as Control).position.y

	($Foreground/Enemy as TextureRect).flip_h =\
			not (%WarningTexture as TextureRect).flip_h
	($Foreground/Enemy as TextureRect).position.y =\
			(%WarningAnchor as Control).position.y

	($AnimationPlayer as AnimationPlayer).play("enemy_move")

	_spawn_enemy()
