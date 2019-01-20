
uniform vec2 camPos;


const float M_PI = 3.1415926535897932384626433832795;

float rand(vec2 n)
{
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

//(n1x, n1y, n2x, n2y) n=closest points
vec4 voronoi(vec2 pos, float jitter)
{
	vec2 posi = floor(pos);
	vec2 pos2 = vec2(0, 0);
	float dist = 0.0;
	vec2 n1 = vec2(0, 0);
	vec2 n2 = vec2(0, 0);
	float n1d = 9.0;
	float n2d = 9.0;
	for (int i=-2; i < 2; i++) {
		for (int j=-2; j < 2; j++) {
			pos2 = posi+vec2(i,j)+vec2(0.5)+(vec2(rand(posi+vec2(i,j)), rand(posi+vec2(i,j)+0.5))*2.0-1.0)*jitter*0.5;
			dist = dot(pos-pos2, pos-pos2);
			if (dist < n2d) {
				if (dist < n1d) {
					n2d = n1d;
					n1d = dist;
					n2 = n1;
					n1 = pos2;
				} else {
					n2d = dist;
					n2 = pos2;
				}
			}
		}
	}
	return vec4(n1, n2);
}

vec4 voronoi(vec2 pos)
{
	return voronoi(pos, 1.0);
}

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
    vec2 p = floor(uv);

    // grass/sand/rock/water
    int tileChoices[3] = int[](1, 2, 4);
    float r1 = snoise(p/32.0)*0.5 + 0.5;
    int choice = 0;
    for (int i=0; i < 3; i++) {
        if (r1 < (i+1)/3.0) {
            choice = tileChoices[i];
            break;
        }
    }
    float r2 = snoise(1000.0 + p/64.0)*0.5 + 0.5;
    if (r1 < 0.2 && r2 < 0.5) {
        choice = 3;
    }

    // buildings
    float freq = 64.0;
    vec2 vp = p/freq;
    vec4 vpts = voronoi(vp, 0.5);
    vec2 vd = vec2(floor(abs(vp.x - vpts.x)*freq), floor(abs(vp.y - vpts.y)*freq));
    // inside
    if (vd.x <= 4.0 && vd.y <= 6.0) {
        choice = 7;
    }
    if (distance(vp, vpts.xy)*freq < 2.0) {
        choice = 6;
    }
    // walls
    if ((vd.x == 4.0 && vd.y <= 6.0 || vd.y == 6.0 && vd.x <= 4.0)
    && vd.x > 1.0  && vd.y > 1.0) {
        choice = 8;
    }

    // paths
    float d = distance(p, vec2(0.0));
    float angle = atan(p.y, p.x);
    angle += snoise(2000.0 + p/64.0)/d*4.0;
    if (distance(mod(angle/(2.0*M_PI)*8.0, 1.0), 0.5) < 0.3/(d/8.0)) {
        choice = 6;
    }

    // platform
    if (length(p) < 8.0) {
        choice = 5;
    }


    return vec4(choice/255.0, 0.0, 0.0, 1.0);
}
