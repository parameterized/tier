
uniform Image tiles[5];
uniform Image tileIds;
uniform vec2 tileIdRes;
uniform vec2 camPos;
uniform vec2 tilemapPos;

float tileSize = 15.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords;
    uv += camPos;
    vec2 tilePos = floor(uv/tileSize);
    //vec2 tilemapPos = floor(camPos/tileSize) - 2.0; // imprecision errors if calculated in shader?
    vec2 tileIdPos = tilePos - tilemapPos;
    vec4 tileIdColor = Texel(tileIds, tileIdPos/(tileIdRes + vec2(1.0)));
    int id = int(tileIdColor.r*255.0);
    return Texel(tiles[id], mod(uv/tileSize, 1.0))*color;
}
