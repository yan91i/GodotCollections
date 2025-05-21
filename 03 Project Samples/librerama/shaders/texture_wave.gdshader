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

const float MODULUS = 1000.0;

varying float modulate;

uniform vec2 speed;
uniform vec2 waves;
uniform vec2 strength;

uniform float interval;

void vertex() {
	modulate = COLOR.a;
}

void fragment() {
	float time = TIME;
	if (interval > 0.0) {
		time = floor(time / interval);
	}

	// Use modulo to lower the total value and avoid precision errors.
	time = mod(time, MODULUS);

	vec2 distortion;
	distortion.x = sin(time * speed.y + UV.y * waves.y * PI) * strength.y;
	distortion.y = sin(time * speed.x + UV.x * waves.x * PI) * strength.x;

	vec4 result = texture(TEXTURE, UV + distortion * TEXTURE_PIXEL_SIZE);
	COLOR = result;
	COLOR.a *= modulate;
}
