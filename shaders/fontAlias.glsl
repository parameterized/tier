
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords);
	pixel.a = pixel.a > 0.5 ? 1.0 : 0.0;
	return pixel*color;
}
