///////////////////////////////////////////////////////////////////////////////
// Librerama                                                                 //
// Copyright (C) 2023 Michael Alexsander                                     //
//---------------------------------------------------------------------------//
// This file is part of Librerama.                                           //
//                                                                           //
// Librerama is free software: you can redistribute it and/or modify         //
// it under the terms of the GNU General Public License as published by      //
// the Free Software Foundation, either version 3 of the License, or         //
// (at your option) any later version.                                       //
//                                                                           //
// Librerama is distributed in the hope that it will be useful,              //
// but WITHOUT ANY WARRANTY; without even the implied warranty of            //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             //
// GNU General Public License for more details.                              //
//                                                                           //
// You should have received a copy of the GNU General Public License         //
// along with Librerama.  If not, see <http://www.gnu.org/licenses/>.        //
///////////////////////////////////////////////////////////////////////////////

shader_type canvas_item;

uniform vec2 direction_speed = vec2(0);

uniform float offset_x : hint_range(0, 1) = 0;
uniform float offset_y : hint_range(0, 1) = 0;

void vertex() {
	UV -= TIME * direction_speed - vec2(offset_x, offset_y);
}
