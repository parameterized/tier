
extern float percent;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = vec4(0.0);
	vec2 uv = screen_coords;
    if (uv.x < 1.0 || uv.x > love_ScreenSize.x - 1.0
    || uv.y < 1.0 || uv.y > love_ScreenSize.y - 1.0) {
        if (uv.x < 1.0 && uv.y < 1.0 || uv.x < 1.0 && uv.y > love_ScreenSize.y - 1.0
        || uv.x > love_ScreenSize.x - 1.0 && uv.y < 1.0
        || uv.x > love_ScreenSize.x - 1.0 && uv.y > love_ScreenSize.y - 1.0) {
            //pixel = vec4(0.0);
        } else {
            pixel = vec4(vec3(0.0), 1.0);
        }
    } else {
        float uvp = (uv.x - 1.0 - (love_ScreenSize.y - 2.0 - uv.y))
        /(love_ScreenSize.x - 2.0 + (love_ScreenSize.y - 2.0));
        pixel = uvp < percent ? vec4(vec3(105.0, 174.0, 0.0)/255.0, 1.0)
        : vec4(vec3(105.0, 0.0, 0.0)/255.0, 1.0);
    }
    return pixel;
}
