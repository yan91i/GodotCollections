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

var _punching_bag: Node2D


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	match difficulty:
		1:
			_punching_bag = load("res://nanogames/punchbag_wallop/" +
					"punching_bags/bag_1/bag_1.tscn").instantiate()
		2:
			_punching_bag = load("res://nanogames/punchbag_wallop/" +
					"punching_bags/bag_2/bag_2.tscn").instantiate()
		3:
			_punching_bag = load("res://nanogames/punchbag_wallop/" +
					"punching_bags/bag_3/bag_3.tscn").instantiate()

	($BagPosition as Marker2D).add_child(_punching_bag)

	_punching_bag.broke.connect(_on_punching_bag_broke)


func _on_punching_bag_broke() -> void:
	ended.emit(true)

	($Effects as AudioStreamPlayer).stream = preload("_assets/applause.wav")
	($Effects as AudioStreamPlayer).play()

	($Boxer as Node2D).celebrate()


func _on_boxer_punched() -> void:
	var did_hit: bool = _punching_bag.hit()
	if did_hit:
		(%Hits as HBoxContainer).get_child(_punching_bag.get_hit_count() - 1).\
				texture = preload("res://nanogames/punchbag_wallop/_assets/" +
						"indicator_hit.png")

	($Boxer as Node2D).set_punch_hit(did_hit)
