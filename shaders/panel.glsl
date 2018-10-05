
uniform vec4 box;

vec4 c1 = vec4(vec3(0.0), 1.0);
vec4 c2 = vec4(vec3(38.0/255.0), 1.0);
vec4 c3 = vec4(vec3(51.0/255.0), 1.0);
vec4 c4 = vec4(vec3(63.0/255.0), 1.0);

int curve_x[7] = int[](6, 4, 3, 2, 2, 1, 1);
int curve_y[6] = int[](7, 5, 3, 2, 1, 1);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec2 uv = screen_coords;
    uv -= box.xy;
    vec2 border_dist = vec2(min(uv.x, box.z-uv.x), min(uv.y, box.w-uv.y));
    int bdx = int(border_dist.x);
    int bdy = int(border_dist.y);
    vec4 pixel = vec4(0.0);
    bool inner = true;
    if (bdx < 7) {
        if (bdy == curve_x[bdx]) {
            pixel = c1;
        }
        if (bdy <= curve_x[bdx]) {
            inner = false;
        }
    }
    if (bdy < 6) {
        if (bdx == curve_y[bdy]) {
            pixel = c1;
        }
        if (bdx <= curve_y[bdy]) {
            inner = false;
        }
    }
    if (inner) {
        pixel = c2;
    }
    if (bdx == 0 && bdy > 6 || bdy == 0 && bdx > 7) {
        pixel = c1;
    }
    if (bdx > 3 && bdy > 4 && !(bdx == 4 && bdy == 5)) {
        pixel = c3;
        if (int(mod(uv.x + uv.y, 9.0)) == 1) {
            pixel = c4;
        }
    }
	return pixel*color;
}
