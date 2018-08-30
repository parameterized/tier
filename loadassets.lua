
ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.keyboard.setKeyRepeat(true)
love.graphics.setDefaultFilter('nearest', 'nearest')

gsx, gsy = 480, 270
canvases = {
    game = love.graphics.newCanvas(gsx, gsy),
    tempGame = love.graphics.newCanvas(gsx, gsy),
    hpBar = love.graphics.newCanvas(18, 4)
}

gfx = {
    cursors = {
        main = love.graphics.newImage('gfx/ui/cursor.png')
    },
    logo = love.graphics.newImage('gfx/logo.png'),
    logoAnim = love.graphics.newImage('gfx/logo_anim.png'),
    hud = {
        frame = love.graphics.newImage('gfx/ui/hud/hudframe.png'),
        xpbar = love.graphics.newImage('gfx/ui/hud/xpbar.png'),
        cog = love.graphics.newImage('gfx/ui/hud/cog.png'),
        map = love.graphics.newImage('gfx/ui/hud/map.png'),
        inventory = love.graphics.newImage('gfx/ui/hud/inventoryOpen.png'),
        dropDown = love.graphics.newImage('gfx/ui/hud/buttonDD.png'),
        lifemana = love.graphics.newImage('gfx/ui/hud/lifemana.png'),
        pause = love.graphics.newImage('gfx/ui/hud/pause.png')
    },
    tiles = {
        tileSheet1 = love.graphics.newImage('gfx/tiles/tilesheet1.png')
    },
    player = {
        walkSheet = love.graphics.newImage('gfx/char/player_walk.png'),
        swingSheet = love.graphics.newImage('gfx/char/player_swing.png')
    },
    enemies = {
        slime1 = love.graphics.newImage('gfx/enemies/slime1.png'),
        slime2 = love.graphics.newImage('gfx/enemies/slime2.png')
    }
}

anims = {}
function newAnim(sheet, w, h, pad, num)
    local t = {
        sheet = sheet,
        quads = {}
    }
    for i=1, num do
        local x = (i-1)*(w + pad*2) + 1
        local y = 1
        local sw, sh = sheet:getDimensions()
        t.quads[i] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return t
end

anims.logo = newAnim(gfx.logoAnim, 54, 41, 1, 8)
anims.player = {
    walk = newAnim(gfx.player.walkSheet, 20, 29, 1, 5),
    swing = newAnim(gfx.player.swingSheet, 43, 34, 1, 5)
}

tileSheets = {}
function newTileSheet(sheet, w, h, pad, num, names)
    local t = {
        sheet = sheet,
        quads = {}
    }
    names = names or {}
    for i=1, num do
        local x = (i-1)*(w + pad*2) + 1
        local y = 1
        local sw, sh = sheet:getDimensions()
        t.quads[names[i] or i] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return t
end

tileSheets.ts1 = newTileSheet(gfx.tiles.tileSheet1, 15, 15, 1, 4, {'grass', 'sand', 'rock', 'water'})

fonts = {
    f10 = love.graphics.newFont(10),
    f12 = love.graphics.newFont(12),
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24),

    c13 = love.graphics.newImageFont('gfx/fonts/small_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>'),
    c17 = love.graphics.newImageFont('gfx/fonts/big_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>')
}

shaders = {
    fontAlias = love.graphics.newShader('shaders/fontAlias.glsl'),
    outline = love.graphics.newShader('shaders/outline.glsl'),
    hpBar = love.graphics.newShader('shaders/hpBar.glsl'),
    mapGen = love.graphics.newShader('shaders/mapGen.glsl')
}

local tileCanv = love.graphics.newCanvas(15, 15)
love.graphics.setColor(1, 1, 1)
local tileImgs = {}
for _, v in pairs({'grass', 'sand', 'rock', 'water'}) do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(tileSheets.ts1.sheet, tileSheets.ts1.quads[v], 0, 0)
    love.graphics.setCanvas()
    table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapGen:send('tiles', unpack(tileImgs))
