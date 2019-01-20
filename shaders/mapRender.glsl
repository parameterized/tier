
uniform vec2 tileIdRes;
uniform vec2 camPos;
uniform vec2 tilemapPos;
uniform Image tileIds;
uniform Image tiles[5];
uniform Image platformFrames[2];
uniform Image tiles2[3];
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
    int centerId = int(tileIdColor.r*255.0);

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

    if (centerId < 5) {
        vec4 c1 = Texel(tiles[centerId], tileUV)*color;
        if (tileUV.x < 0.5) {
            if (tileUV.y < 0.5) {
                if (topId != centerId && leftId != centerId
                && topLeftId != centerId && topLeftId < 5) {
                    vec4 c2 = Texel(tiles[topLeftId], tileUV)*color;
                    float t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                if (bottomId != centerId && leftId != centerId
                && bottomLeftId != centerId && bottomLeftId < 5) {
                    vec4 c2 = Texel(tiles[bottomLeftId], tileUV)*color;
                    float t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        } else {
            if (tileUV.y < 0.5) {
                if (topId != centerId && rightId != centerId
                && topRightId != centerId && topRightId < 5) {
                    vec4 c2 = Texel(tiles[topRightId], tileUV)*color;
                    float t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            } else {
                if (bottomId != centerId && rightId != centerId
                && bottomRightId != centerId && bottomRightId < 5) {
                    vec4 c2 = Texel(tiles[bottomRightId], tileUV)*color;
                    float t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;
                    return t > 0.5 ? c1 : c2;
                }
            }
        }
    }

    if (centerId == 5) {
        int frame = int(mod(floor(time - length(tilePos)/4.0), 2.0));
        return Texel(platformFrames[frame], tileUV)*color;
    } else if (centerId > 5) {
        return Texel(tiles2[centerId - 6], tileUV)*color;
    } else {
        return Texel(tiles[centerId], tileUV)*color;
    }
}
