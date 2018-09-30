
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

    // blended
    if (tileUV.x < 1.0/3.0) {
        if (tileUV.y < 1.0/3.0) {
            // top left
            if (id == 2) { // sand
                vec4 topIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, -1.0))/(tileIdRes + vec2(1.0)));
                vec4 leftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 0.0))/(tileIdRes + vec2(1.0)));
                vec4 topLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, -1.0))/(tileIdRes + vec2(1.0)));
                int topId = int(topIdColor.r*255.0);
                int leftId = int(leftIdColor.r*255.0);
                int topLeftId = int(topLeftIdColor.r*255.0);
                if (topId == 4 && leftId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = max(1.0 - length(1.0 - tileUV*3.0), 0.0);
                    return c1*t + c2*(1.0-t);
                } else if (topId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (leftId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (topLeftId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = length(tileUV*3.0);
                    return c1*t + c2*(1.0-t);
                }
            }
        } else if (tileUV.y < 2.0/3.0) {
            // center left
            if (id == 2) { // sand
                vec4 leftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 0.0))/(tileIdRes + vec2(1.0)));
                int leftId = int(leftIdColor.r*255.0);
                if (leftId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                }
            }
        } else {
            // bottom left
            if (id == 2) { //sand
                vec4 bottomIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, 1.0))/(tileIdRes + vec2(1.0)));
                vec4 leftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 0.0))/(tileIdRes + vec2(1.0)));
                vec4 bottomLeftIdColor = Texel(tileIds, (tileIdPos + vec2(-1.0, 1.0))/(tileIdRes + vec2(1.0)));
                int bottomId = int(bottomIdColor.r*255.0);
                int leftId = int(leftIdColor.r*255.0);
                int bottomLeftId = int(bottomLeftIdColor.r*255.0);
                if (bottomId == 4 && leftId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = max(1.0 - length(vec2(1.0, 2.0) - tileUV*3.0), 0.0);
                    return c1*t + c2*(1.0-t);
                } else if (bottomId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (leftId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (bottomLeftId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = length(vec2(0.0, 3.0) - tileUV*3.0);
                    return c1*t + c2*(1.0-t);
                }
            }
        }
    } else if (tileUV.x < 2.0/3.0) {
        if (tileUV.y < 1.0/3.0) {
            // top center
            if (id == 2) { // sand
                vec4 topIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, -1.0))/(tileIdRes + vec2(1.0)));
                int topId = int(topIdColor.r*255.0);
                if (topId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                }
            }
        } else if (tileUV.y < 2.0/3.0) {
            // center
        } else {
            // bottom center
            if (id == 2) { // sand
                vec4 bottomIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, 1.0))/(tileIdRes + vec2(1.0)));
                int bottomId = int(bottomIdColor.r*255.0);
                if (bottomId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                }
            }
        }
    } else {
        if (tileUV.y < 1.0/3.0) {
            // top right
            if (id == 2) { // sand
                vec4 topIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, -1.0))/(tileIdRes + vec2(1.0)));
                vec4 rightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 0.0))/(tileIdRes + vec2(1.0)));
                vec4 topRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, -1.0))/(tileIdRes + vec2(1.0)));
                int topId = int(topIdColor.r*255.0);
                int rightId = int(rightIdColor.r*255.0);
                int topRightId = int(topRightIdColor.r*255.0);
                if (topId == 4 && rightId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = max(1.0 - length(vec2(2.0, 1.0) - tileUV*3.0), 0.0);
                    return c1*t + c2*(1.0-t);
                } else if (topId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (rightId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (topRightId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = length(vec2(3.0, 0.0) - tileUV*3.0);
                    return c1*t + c2*(1.0-t);
                }
            }
        } else if (tileUV.y < 2.0/3.0) {
            // center right
            if (id == 2) { // sand
                vec4 rightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 0.0))/(tileIdRes + vec2(1.0)));
                int rightId = int(rightIdColor.r*255.0);
                if (rightId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                }
            }
        } else {
            // bottom right
            if (id == 2) { // sand
                vec4 bottomIdColor = Texel(tileIds, (tileIdPos + vec2(0.0, 1.0))/(tileIdRes + vec2(1.0)));
                vec4 rightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 0.0))/(tileIdRes + vec2(1.0)));
                vec4 bottomRightIdColor = Texel(tileIds, (tileIdPos + vec2(1.0, 1.0))/(tileIdRes + vec2(1.0)));
                int bottomId = int(bottomIdColor.r*255.0);
                int rightId = int(rightIdColor.r*255.0);
                int bottomRightId = int(bottomRightIdColor.r*255.0);
                if (bottomId == 4 && rightId == 4) { // water
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = max(1.0 - length(2.0 - tileUV*3.0), 0.0);
                    return c1*t + c2*(1.0-t);
                } else if (bottomId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.y*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (rightId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = 3.0 - tileUV.x*3.0;
                    return c1*t + c2*(1.0-t);
                } else if (bottomRightId == 4) {
                    vec4 c1 = Texel(tiles[id], tileUV)*color;
                    vec4 c2 = Texel(tiles[4], tileUV)*color;
                    float t = length(vec2(3.0, 3.0) - tileUV*3.0);
                    return c1*t + c2*(1.0-t);
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
