///////////////////////////////////////////////////////////////////////////////
// Librerama                                                                 //
// Copyright (c) 2020-present Michael Alexsander.                            //
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

void fragment() {
	// Quick and dirty 2D white noise adapted from "The Book of Shaders".
	COLOR.rgb *= vec3(fract(sin(dot(UV, vec2(TIME, 78.233))) * 43758.5453));
}
