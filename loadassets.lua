
ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.graphics.setDefaultFilter('nearest', 'nearest')

gsx, gsy = 480, 270
canvases = {
    game = love.graphics.newCanvas(gsx, gsy)
}

gfx = {
    logo = love.graphics.newImage('gfx/logo.png'),
    player = {
        walkSheet = love.graphics.newImage('gfx/char/char-walk.png')
    },
    tiles = {
        tileSheet1 = love.graphics.newImage('gfx/tiles/tilesheet1.png')
    }
}

anims = {}
function newAnim(sheet, w, h, pad, num)
    local t = {
        sheet = sheet,
        quads = {}
    }
    for i=1, num do
        local x = (i-1)*(w + pad)
        local y = 0
        local sw, sh = sheet:getDimensions()
        t.quads[i] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return t
end

anims.player = {
    walk = newAnim(gfx.player.walkSheet, 14, 22, 0, 6)
}

tileSheets = {}
function newTileSheet(sheet, w, h, pad, num, names)
    local t = {
        sheet = sheet,
        quads = {}
    }
    names = names or {}
    for i=1, num do
        local x = (i-1)*(w + pad)
        local y = 0
        local sw, sh = sheet:getDimensions()
        t.quads[names[i] or i] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return t
end

tileSheets.ts1 = newTileSheet(gfx.tiles.tileSheet1, 15, 15, 0, 4, {'grass', 'sand', 'rock', 'water'})

fonts = {
    f10 = love.graphics.newFont(10),
    f12 = love.graphics.newFont(12),
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24)
}

shaders = {
    fontAlias = love.graphics.newShader('shaders/fontAlias.glsl')
}