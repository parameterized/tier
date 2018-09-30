
uniform Image tiles[5];
uniform Image tileIds;
uniform vec2 tileIdRes;
uniform vec2 camPos;
uniform vec2 tilemapPos;
uniform Image platformFrames[2];
uniform float time;

float tileSize = 15.0;



vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords;
    uv += camPos;
    vec2 tileUV = mod(uv/tileSize, 1.0);
    vec2 tilePos = floor(uv/tileSize);
    //vec2 tilemapPos = floor(camPos/tileSize) - 2.0; // imprecision errors if calculated in shader?
    vec2 tileIdPos = tilePos - tilemapPos;
    vec4 tileIdColor = Texel(tileIds, tileIdPos/(tileIdRes + vec2(1.0)));
    int id = int(tileIdColor.r*255.0);

    // smooth edges
    vec4 topLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 topIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 topRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 leftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 0.0))/(tileIdRes + vec2(1.0)));
    vec4 rightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 0.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 1.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, 1.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 1.0))/(tileIdRes + vec2(1.0)));

    int topLeftId = int(topLeftIdColor.r*255.0);
    int topId = int(topIdColor.r*255.0);
    int topRightId = int(topRightIdColor.r*255.0);
    int leftId = int(leftIdColor.r*255.0);
    int rightId = int(rightIdColor.r*255.0);
    int bottomLeftId = int(bottomLeftIdColor.r*255.0);
    int bottomId = int(bottomIdColor.r*255.0);
    int bottomRightId = int(bottomRightIdColor.r*255.0);

    if (id == 2) {
        vec4 c1 = Texel(tiles[2], tileUV)*color; // sand
        vec4 c2 = Texel(tiles[4], tileUV)*color; // water
        float t = 1.0;
        if (tileUV.x < 0.5) {
            if (tileUV.y < 0.5) {
                // top left
                if (topId == 4 && leftId == 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                // bottom left
                if (bottomId == 4 && leftId == 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        } else {
            if (tileUV.y < 0.5) {
                // top right
                if (topId == 4 && rightId == 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                // bottom right
                if (bottomId == 4 && rightId == 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        }
    } else if (id == 4) {
        vec4 c1 = Texel(tiles[4], tileUV)*color; // water
        vec4 c2 = Texel(tiles[2], tileUV)*color; // sand
        float t = 1.0;
        if (tileUV.x < 0.5) {
            if (tileUV.y < 0.5) {
                // top left
                if (topId == 2 && leftId == 2 && topLeftId != 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                // bottom left
                if (bottomId == 2 && leftId == 2 && bottomLeftId != 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        } else {
            if (tileUV.y < 0.5) {
                // top right
                if (topId == 2 && rightId == 2 && topRightId != 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                // bottom right
                if (bottomId == 2 && rightId == 2 && bottomRightId != 4) {
                    t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        }
    }

    // default
    if (id == 5) {
        int frame = int(mod(floor(time - length(tilePos)/4.0), 2.0));
        return Texel(platformFrames[frame], tileUV)*color;
    } else {
        return Texel(tiles[id], tileUV)*color;
    }
}
