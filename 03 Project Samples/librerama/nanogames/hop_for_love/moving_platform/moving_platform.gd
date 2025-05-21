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


func move(remote_target: NodePath) -> void:
	if get_node(remote_target) == null:
		return

	# Make transformer act from the position of the target's landing.
	($CollisionShape2D/RemoteTransform2D as RemoteTransform2D).position.x =\
			(get_node(remote_target) as Area2D).\
			global_position.x - global_position.x

	($CollisionShape2D/RemoteTransform2D as RemoteTransform2D).remote_path =\
			remote_target

	if randi() % 2 == 0:
		($AnimationPlayer as AnimationPlayer).play("move")
	else:
		($AnimationPlayer as AnimationPlayer).play_backwards("move")


func stop() -> void:
	($CollisionShape2D/RemoteTransform2D as RemoteTransform2D).remote_path =\
			NodePath()

	($AnimationPlayer as AnimationPlayer).stop(true)
