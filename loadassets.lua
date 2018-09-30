
ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.keyboard.setKeyRepeat(true)
love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineStyle('rough')

gsx, gsy = 480, 270
canvases = {
    game = love.graphics.newCanvas(gsx, gsy),
    game2x = love.graphics.newCanvas(gsx*2, gsy*2),
    tempGame = love.graphics.newCanvas(gsx, gsy),
    hpBar = love.graphics.newCanvas(18, 4)
}

gfx = {
    cursors = {
        main = love.graphics.newImage('gfx/ui/cursors/cursor.png')
    },
    logo = love.graphics.newImage('gfx/logo.png'),
    logoAnim = love.graphics.newImage('gfx/logo_anim.png'),
    ui = {
        buttons = {
            up = love.graphics.newImage('gfx/ui/buttons/up.png'),
            down = love.graphics.newImage('gfx/ui/buttons/down.png'),
            left = love.graphics.newImage('gfx/ui/buttons/left.png'),
            right = love.graphics.newImage('gfx/ui/buttons/right.png')
        },
        bag = love.graphics.newImage('gfx/ui/bagui.png')
    },
    hud = {
        frame = love.graphics.newImage('gfx/ui/hud/frame.png'),
        lifemana = love.graphics.newImage('gfx/ui/hud/lifemana.png'),
        panels = {
            map = love.graphics.newImage('gfx/ui/hud/panels/map.png'),
            chat = love.graphics.newImage('gfx/ui/hud/panels/chat.png'),
            stats = love.graphics.newImage('gfx/ui/hud/panels/stats.png'),
            inventory = love.graphics.newImage('gfx/ui/hud/panels/inventory.png')
        },
        buttons = {
            chat = love.graphics.newImage('gfx/ui/hud/buttons/chat.png'),
            chatField = love.graphics.newImage('gfx/ui/hud/buttons/chatField.png'),
            stats = love.graphics.newImage('gfx/ui/hud/buttons/stats.png'),
            backpack = love.graphics.newImage('gfx/ui/hud/buttons/backpack.png')
        }
    },
    tiles = {
        tileSheet1 = love.graphics.newImage('gfx/tiles/tilesheet1.png'),
        platformSheet = love.graphics.newImage('gfx/tiles/platformSheet.png')
    },
    player = {
        walk = {
            body = love.graphics.newImage('gfx/player/walk/body.png'),
            sword = love.graphics.newImage('gfx/player/walk/sword.png')
        },
        swing = {
            body = love.graphics.newImage('gfx/player/swing/body.png'),
            sword = love.graphics.newImage('gfx/player/swing/sword.png')
        }
    },
    enemies = {
        slime1 = love.graphics.newImage('gfx/enemies/slime1.png'),
        slime2 = love.graphics.newImage('gfx/enemies/slime2.png')
    },
    items = {
        lootBag = love.graphics.newImage('gfx/items/loot.png'),
        lootBag1 = love.graphics.newImage('gfx/items/loot1.png'),
        lootBagFuse = love.graphics.newImage('gfx/items/loot-fuse.png'),
        sword = love.graphics.newImage('gfx/items/sword.png'),
        shield = love.graphics.newImage('gfx/items/shield.png')
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
    walk = {
        body = newAnim(gfx.player.walk.body, 20, 29, 1, 5),
        sword = newAnim(gfx.player.walk.sword, 20, 29, 1, 5)
    },
    swing = {
        body = newAnim(gfx.player.swing.body, 43, 34, 1, 5),
        sword = newAnim(gfx.player.swing.sword, 43, 34, 1, 5)
    }
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
tileSheets.platform = newTileSheet(gfx.tiles.platformSheet, 15, 15, 1, 2)

fonts = {
    f10 = love.graphics.newFont(10),
    f12 = love.graphics.newFont(12),
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24),

    c13 = love.graphics.newImageFont('gfx/fonts/small_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>'),
    c17 = love.graphics.newImageFont('gfx/fonts/big_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>'),
    stats = love.graphics.newImageFont('gfx/fonts/stat_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
}
-- todo: test
-- love.graphics.newFont([filename, ] size, "mono")

shaders = {
    fontAlias = love.graphics.newShader('shaders/fontAlias.glsl'),
    outline = love.graphics.newShader('shaders/outline.glsl'),
    hpBar = love.graphics.newShader('shaders/hpBar.glsl'),
    mapGen = love.graphics.newShader('shaders/mapGen.glsl'),
    mapRender = love.graphics.newShader('shaders/mapRender.glsl')
}

local tileCanv = love.graphics.newCanvas(15, 15)
love.graphics.setColor(1, 1, 1)
local tileImgs = {}
love.graphics.setCanvas(tileCanv)
love.graphics.clear(0, 0, 0)
love.graphics.setCanvas()
-- black tile
table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
for _, v in pairs{'grass', 'sand', 'rock', 'water'} do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.ts1.sheet, tileSheets.ts1.quads[v], 0, 0)
    love.graphics.setCanvas()
    table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('tiles', unpack(tileImgs))

local platformFrames = {}
for _, quad in pairs(tileSheets.platform.quads) do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.platform.sheet, quad, 0, 0)
    love.graphics.setCanvas()
    table.insert(platformFrames, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('platformFrames', unpack(platformFrames))
