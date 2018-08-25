
uniform Image tiles[4];
uniform vec2 camPos;


vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
        dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec2 uv = screen_coords;
    uv += camPos;
    float tileSize = 15.0;
    vec2 p = floor(uv/tileSize);
    int tileChoices[3] = int[](0, 1, 3);
    float r1 = snoise(p/32.0)*0.5 + 0.5;
    int choice = 0;
    for (int i=0; i < 3; i++) {
        if (r1 < (i+1)/3.0) {
            choice = tileChoices[i];
            break;
        }
    }
    float r2 = snoise(1000 + p/64.0)*0.5 + 0.5;
    if (r1 < 0.2 && r2 < 0.5) {
        choice = 2;
    }
    return Texel(tiles[choice], mod(uv/tileSize, 1.0))*color;
}
