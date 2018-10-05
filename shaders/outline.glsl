
uniform vec2 stepSize;
uniform vec4 outlineColor;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords);
    if (pixel.a < 0.5) {
        vec2 coord_left = texture_coords + vec2(-1.0, 0.0)*stepSize;
        vec2 coord_right = texture_coords + vec2(1.0, 0.0)*stepSize;
        vec2 coord_up = texture_coords + vec2(0.0, 1.0)*stepSize;
        vec2 coord_down = texture_coords + vec2(0.0, -1.0)*stepSize;
        if (Texel(texture, coord_left).a > 0.5 || Texel(texture, coord_right).a > 0.5
        || Texel(texture, coord_up).a > 0.5 || Texel(texture, coord_down).a > 0.5) {
            pixel = outlineColor;
        }
    }
	return pixel*color;
}
