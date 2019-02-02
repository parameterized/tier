
uniform vec2 tileIdRes;
uniform vec2 camPos;
uniform vec2 tilemapPos;
uniform Image tileIds;
uniform Image tiles[10];
uniform Image smoothTiles[16];
uniform float time;
uniform bool drawDebug;

float tileSize = 15.0;

float min3(vec3 v) {
    return min(min(v.x, v.y), v.z);
}

float max3(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords;
    uv += camPos;
    vec2 tileUV = mod(uv/tileSize, 1.0);
    vec2 tilePos = floor(uv/tileSize);
    //vec2 tilemapPos = floor(camPos/tileSize) - 2.0; // imprecision errors if calculated in shader?
    vec2 tileIdPos = tilePos - tilemapPos;

    vec4 topLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 topIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 topRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, -1.0))/(tileIdRes + vec2(1.0)));
    vec4 leftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 0.0))/(tileIdRes + vec2(1.0)));
    vec4 centerIdColor = Texel(tileIds, tileIdPos/(tileIdRes + vec2(1.0)));
    vec4 rightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 0.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 1.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, 1.0))/(tileIdRes + vec2(1.0)));
    vec4 bottomRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 1.0))/(tileIdRes + vec2(1.0)));

    int topLeftId = int(topLeftIdColor.r*255.0);
    int topId = int(topIdColor.r*255.0);
    int topRightId = int(topRightIdColor.r*255.0);
    int leftId = int(leftIdColor.r*255.0);
    int centerId = int(centerIdColor.r*255.0);
    int rightId = int(rightIdColor.r*255.0);
    int bottomLeftId = int(bottomLeftIdColor.r*255.0);
    int bottomId = int(bottomIdColor.r*255.0);
    int bottomRightId = int(bottomRightIdColor.r*255.0);

    int outId = centerId;
    float t = length(1.0 - tileUV*2.0) < 1.0 ? 1.0 : 0.0;

    // this tile, opposite, side1, side2
    vec4 corner;
    if (tileUV.x < 0.5) {
        if (tileUV.y < 0.5) {
            corner = vec4(centerId, topLeftId, topId, leftId);
        } else {
            corner = vec4(centerId, bottomLeftId, bottomId, leftId);
        }
    } else {
        if (tileUV.y < 0.5) {
            corner = vec4(centerId, topRightId, topId, rightId);
        } else {
            corner = vec4(centerId, bottomRightId, bottomId, rightId);
        }
    }

    vec3 debugColor = vec3(0.0);

    float maxNeighbors = max3(corner.yzw);
    float minNeighbors = min3(corner.yzw);
    bool clipped = false;
    if (corner.x > maxNeighbors) {
        outId = int(t > 0.5 ? corner.x : maxNeighbors);
        debugColor.r = 1.0;
        clipped = true;
    }
    if (minNeighbors > corner.x) {
        outId = int(t > 0.5 ? corner.x : minNeighbors);
        debugColor.g = 1.0;
        clipped = true;
    }
    if (minNeighbors != corner.x && minNeighbors == corner.z && minNeighbors == corner.w) {
        outId = int(t > 0.5 ? corner.x : minNeighbors);
        debugColor.b = 1.0;
        clipped = true;
    }

    int smoothId = 0;
    if (outId == 5 || outId == 6 || outId == 8) { // smooth path, floor, platform
        if (corner.x == corner.y && corner.x == corner.z && corner.x == corner.w
        || (corner.x == corner.z || corner.x == corner.w) && corner.z != corner.w && corner.x != corner.y) {
            smoothId = 0;
            if (corner.x < maxNeighbors && (corner.x != corner.z || corner.x != corner.w) && corner.y != corner.z && corner.y != corner.w) {
                smoothId = 3;
            }
        } else if (corner.x == corner.z && corner.z == corner.w
        || corner.x == corner.y && corner.z != corner.w && (corner.x == corner.z || corner.x == corner.w)) {
            smoothId = 3;
        } else if (corner.x != corner.y && corner.x != corner.z && corner.x != corner.w) {
            smoothId = 2;
            if (corner.x < maxNeighbors && (corner.y != corner.z && corner.y != corner.w || (corner.y == corner.z || corner.y == corner.w))) {
                smoothId = 3;
            }
        } else {
            smoothId = 3;
        }
        if (int(corner.x) != outId) {
            smoothId = 1;
        } else if (clipped) {
            smoothId = 2;
        }
    }

    if (drawDebug) {
        return vec4(debugColor, 1.0);
    }


    if (outId == 5) { // path
        return Texel(smoothTiles[0 + smoothId], tileUV)*color;
    } else if (outId == 6) { // floor
        return Texel(smoothTiles[4 + smoothId], tileUV)*color;
    } else if (outId == 8) { // platform
        int frame = int(mod(floor(time - length(tilePos)/4.0), 2.0));
        return Texel(smoothTiles[8 + frame*4 + smoothId], tileUV)*color;
    } else {
        return Texel(tiles[outId], tileUV)*color;
    }
}
