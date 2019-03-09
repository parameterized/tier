
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


float noiseAlt(vec2 uv)
{
    vec2 _uv = uv;
    uv /= 512.0;
    uv += vec2(500.0);
    float v = snoise(uv)*0.5+0.5;
    v += snoise(uv*2.0)*0.4;
    v += snoise(uv*4.0)*0.2;
    v += snoise(uv*8.0)*0.1;
    v += snoise(uv*16.0)*0.05;
    v += snoise(uv*32.0)*0.02;
    v -= 0.2;
    v = max(v, 0.0);
    v = pow(v, 2.0);
    float d = length(_uv);
    v -= pow(d/256.0, 2.0);
    v += snoise(_uv/128.0 - vec2(500.0))*0.15 + 0.7;
    //v = max(v, 0.0);
    return v;
}

float noiseMoist(vec2 uv)
{
    uv /= 512.0;
    float v = snoise(uv)*0.5+0.5;
    v += snoise(uv*2.0)*0.4;
    v += snoise(uv*4.0)*0.2;
    v += snoise(uv*8.0)*0.1;
    v += snoise(uv*16.0)*0.05;
    v += snoise(uv*32.0)*0.02;
    v += 0.1;
    v = max(v, 0.0);
    v = pow(v, 2.0);
    return v;
}


// water: 1, sand1: 2, sand2: 3, grass1: 4, grass2: 5, grass3: 6, grass4: 7, grass5: 8,
// snow: 9, ice: 10, path: 11, floor: 12, wall: 13, platform: 14, platform2: 15

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec2 uv = screen_coords;
    uv += camPos;
    vec2 p = floor(uv);
	int choice = 0;

	float alt = noiseAlt(p);
    float moist = noiseMoist(p);

    choice = 1; // water
    if (alt > 0.01) {
        choice = 2; // sand
    }
    if (alt > 0.1) {
        choice = 3; // sand2
        if (moist > 0.1) {
            choice = 4; // grass1
        }
        if (moist > 0.2) {
            choice = 5; // grass2
        }
        if (moist > 0.4) {
            choice = 6; // grass3
        }
        if (moist > 0.6) {
            choice = 7; // grass4
        }
        if (moist > 0.8) {
            choice = 8; // grass5
        }
    }
    if (alt > 0.8) {
        if (moist < 0.6) {
            choice = 9; // snow
        } else {
            choice = 10; // ice
        }
    }

    if (alt > 0.1) {
    	// buildings
        float freq = 64.0;
        vec2 vp = p/freq;
        vec4 vpts = voronoi(vp, 0.5);
        vec2 vd = vec2(floor(abs(vp.x - vpts.x)*freq), floor(abs(vp.y - vpts.y)*freq));
        // inside
        // floor
        if (vd.x <= 4.0 && vd.y <= 6.0) {
            choice = 12;
        }
        // path
        if (distance(vp, vpts.xy)*freq < 2.0) {
            choice = 11;
        }
        // walls
        if ((vd.x == 4.0 && vd.y <= 6.0 || vd.y == 6.0 && vd.x <= 4.0)
        && vd.x > 1.0  && vd.y > 1.0) {
            choice = 13;
        }

        // paths
		float d = length(p);
        float angle = atan(p.y, p.x);
        angle += snoise(2000.0 + p/64.0)/d*4.0;
        if (distance(mod(angle/(2.0*M_PI)*8.0, 1.0), 0.5) < 0.3/(d/8.0)) {
            choice = 11;
        }

        // platform
        if (length(p) < 8.0) {
            choice = 14;
        }
    }

    return vec4(float(choice)/255.0, 0.0, 0.0, 1.0);
}
