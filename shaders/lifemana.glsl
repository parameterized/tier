
uniform Image lifemanaEmpty;
uniform float hp;
uniform float mana;

vec2 bar_pos[12] = vec2[](
    vec2(32.0, 97.0),
    vec2(32.0, 97.0),
    vec2(31.0, 97.0),
    vec2(31.0, 97.0),
    vec2(30.0, 97.0),
    vec2(29.0, 98.0),
    vec2(28.0, 98.0),

    vec2(26.0, 94.0),
    vec2(25.0, 94.0),
    vec2(24.0, 94.0),
    vec2(23.0, 94.0),
    vec2(22.0, 94.0)
);

vec4 bar_col[12] = vec4[](
    vec4(229.0/255.0, 7.0/255.0, 0.0, 1.0),
    vec4(255.0/255.0, 12.0/255.0, 0.0, 1.0),
    vec4(255.0/255.0, 12.0/255.0, 0.0, 1.0),
    vec4(255.0/255.0, 12.0/255.0, 0.0, 1.0),
    vec4(255.0/255.0, 12.0/255.0, 0.0, 1.0),
    vec4(255.0/255.0, 12.0/255.0, 0.0, 1.0),
    vec4(229.0/255.0, 7.0/255.0, 0.0, 1.0),

    vec4(23.0/255.0, 169.0/255.0, 198.0, 1.0),
    vec4(25.0/255.0, 181.0/255.0, 209.0, 1.0),
    vec4(27.0/255.0, 193.0/255.0, 226.0, 1.0),
    vec4(25.0/255.0, 181.0/255.0, 209.0, 1.0),
    vec4(23.0/255.0, 169.0/255.0, 198.0, 1.0)
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords - vec2(11.0, 18.0);
    vec4 pixel = Texel(lifemanaEmpty, uv/vec2(131.0, 25.0));
    uv = vec2(int(uv.x), int(uv.y));
    if (uv.y > 5 && uv.y < 13) {
        int id = int(uv.y - 6);
        vec2 pos = bar_pos[id];
        if (uv.x > pos.x && uv.x <= pos.x + pos.y*hp) {
            return bar_col[id];
        } else if (uv.x > pos.x + pos.y*hp && uv.x <= pos.x + pos.y) {
            return vec4(bar_col[id].rgb*0.4, 1.0);
        }
    } else if (uv.y > 13 && uv.y < 19) {
        int id = int(uv.y - (6 + 1));
        vec2 pos = bar_pos[id];
        if (uv.x > pos.x && uv.x <= pos.x + pos.y*mana) {
            return bar_col[id];
        } else if (uv.x > pos.x + pos.y*mana && uv.x <= pos.x + pos.y) {
            return vec4(bar_col[id].rgb*0.4, 1.0);
        }
    }
    return pixel;
}
