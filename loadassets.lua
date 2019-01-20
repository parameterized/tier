
ssx, ssy = love.graphics.getDimensions()
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
        main = love.graphics.newImage('gfx/ui/cursors/cursor.png'),
        hand = love.graphics.newImage('gfx/ui/cursors/hand.png')
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
        bag = love.graphics.newImage('gfx/ui/bagui.png'),
        itemInfo = love.graphics.newImage('gfx/ui/item_info.png')
    },
    hud = {
        frame = love.graphics.newImage('gfx/ui/hud/frame.png'),
        lifemana = love.graphics.newImage('gfx/ui/hud/lifemana.png'),
        lifemanaEmpty = love.graphics.newImage('gfx/ui/hud/lifemana_empty.png'),
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
        platformSheet = love.graphics.newImage('gfx/tiles/platformSheet.png'),
        tileSheet2 = love.graphics.newImage('gfx/tiles/tilesheet2.png')
    },
    environment = {
        tree = love.graphics.newImage('gfx/environment/tree.png')
    },
    player = {
        walk = {
            body = love.graphics.newImage('gfx/player/walk/body.png')
        },
        swing = {
            body = love.graphics.newImage('gfx/player/swing/body.png')
        },
        walkAndSwing = {
            upperBody = love.graphics.newImage('gfx/player/walk_and_swing/upper_body.png'),
            lowerBody = love.graphics.newImage('gfx/player/walk_and_swing/lower_body.png')
        },
        swords = {
            sword0 = {
                walk = love.graphics.newImage('gfx/player/swords/sword0/walk.png'),
                swing = love.graphics.newImage('gfx/player/swords/sword0/swing.png')
            },
            sword1 = {
                walk = love.graphics.newImage('gfx/player/swords/sword1/walk.png'),
                swing = love.graphics.newImage('gfx/player/swords/sword1/swing.png')
            },
            sword2 = {
                walk = love.graphics.newImage('gfx/player/swords/sword2/walk.png'),
                swing = love.graphics.newImage('gfx/player/swords/sword2/swing.png')
            },
            sword3 = {
                walk = love.graphics.newImage('gfx/player/swords/sword3/walk.png'),
                swing = love.graphics.newImage('gfx/player/swords/sword3/swing.png')
            },
            sword4 = {
                walk = love.graphics.newImage('gfx/player/swords/sword4/walk.png'),
                swing = love.graphics.newImage('gfx/player/swords/sword4/swing.png')
            }
        }
    },
    enemies = {
        slime1 = love.graphics.newImage('gfx/enemies/slime1.png'),
        slime2 = love.graphics.newImage('gfx/enemies/slime2.png'),
        sorcerer = love.graphics.newImage('gfx/enemies/sorcerer.png'),
        spoder = love.graphics.newImage('gfx/enemies/spoder.png'),
        stingy = love.graphics.newImage('gfx/enemies/stingy.png'),
        zombie = love.graphics.newImage('gfx/enemies/zombie.png'),
        ant = love.graphics.newImage('gfx/enemies/ant.png'),
        newMonster1 = love.graphics.newImage('gfx/enemies/new_monster_1.png'),
        newMonster2 = love.graphics.newImage('gfx/enemies/new_monster_2.png'),
        mudskipper = love.graphics.newImage('gfx/enemies/mudskipper.png'),
        mudskipperEvolved = love.graphics.newImage('gfx/enemies/mudskipper_evolved.png'),
        godex = {
            body1 = love.graphics.newImage('gfx/enemies/godex/body1.png'),
            body2 = love.graphics.newImage('gfx/enemies/godex/body2.png'),
            aura = love.graphics.newImage('gfx/enemies/godex/aura.png'),
            flame = love.graphics.newImage('gfx/enemies/godex/godexFlame.png')
        }
    },
    items = {
        lootBag = love.graphics.newImage('gfx/items/loot.png'),
        lootBag1 = love.graphics.newImage('gfx/items/loot1.png'),
        lootBagFuse = love.graphics.newImage('gfx/items/loot-fuse.png'),
        sword0 = love.graphics.newImage('gfx/items/sword0.png'),
        sword1 = love.graphics.newImage('gfx/items/sword1.png'),
        sword2 = love.graphics.newImage('gfx/items/sword2.png'),
        sword3 = love.graphics.newImage('gfx/items/sword3.png'),
        sword4 = love.graphics.newImage('gfx/items/sword4.png'),
        shield = love.graphics.newImage('gfx/items/shield.png'),
        apple = love.graphics.newImage('gfx/items/apple.png')
    },
    slimeBall = love.graphics.newImage('gfx/slime_ball.png')
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

-- for procedural outline - 1px pad in quad (w,h +2) for outline, 1px pad between frames

anims.logo = newAnim(gfx.logoAnim, 54, 41, 1, 8)
anims.player = {
    walk = {
        body = newAnim(gfx.player.walk.body, 20, 29, 1, 5)
    },
    swing = {
        body = newAnim(gfx.player.swing.body, 43, 34, 1, 5)
    },
    walkAndSwing = {
        upperBody = newAnim(gfx.player.walkAndSwing.upperBody, 43, 34, 1, 5),
        lowerBody = newAnim(gfx.player.walkAndSwing.lowerBody, 43, 34, 1, 5)
    },
    swords = {
        sword0 = {
            walk = newAnim(gfx.player.swords.sword0.walk, 20, 29, 1, 5),
            swing = newAnim(gfx.player.swords.sword0.swing, 43, 34, 1, 5)
        },
        sword1 = {
            walk = newAnim(gfx.player.swords.sword1.walk, 20, 29, 1, 5),
            swing = newAnim(gfx.player.swords.sword1.swing, 43, 34, 1, 5)
        },
        sword2 = {
            walk = newAnim(gfx.player.swords.sword2.walk, 20, 29, 1, 5),
            swing = newAnim(gfx.player.swords.sword2.swing, 43, 34, 1, 5)
        },
        sword3 = {
            walk = newAnim(gfx.player.swords.sword3.walk, 20, 29, 1, 5),
            swing = newAnim(gfx.player.swords.sword3.swing, 43, 34, 1, 5)
        },
        sword4 = {
            walk = newAnim(gfx.player.swords.sword4.walk, 20, 29, 1, 5),
            swing = newAnim(gfx.player.swords.sword4.swing, 43, 34, 1, 5)
        }
    }
}
anims.enemies = {
    mudskipper = newAnim(gfx.enemies.mudskipper, 31, 16, 1, 2),
    mudskipperEvolved = newAnim(gfx.enemies.mudskipperEvolved, 55, 31, 1, 2),
    godexFlame = newAnim(gfx.enemies.godex.flame, 8, 19, 1, 5)
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
tileSheets.ts2 = newTileSheet(gfx.tiles.tileSheet2, 15, 15, 1, 3, {'path', 'floor', 'wall'})

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
    mapRender = love.graphics.newShader('shaders/mapRender.glsl'),
    panel = love.graphics.newShader('shaders/panel.glsl'),
    lifemana = love.graphics.newShader('shaders/lifemana.glsl')
}

local tileCanv = love.graphics.newCanvas(15, 15)
love.graphics.setColor(1, 1, 1)
local tileImgs = {}
love.graphics.setCanvas(tileCanv)
love.graphics.clear(0, 0, 0)
love.graphics.setCanvas()
-- black tile
table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
for _, v in ipairs{'grass', 'sand', 'rock', 'water'} do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.ts1.sheet, tileSheets.ts1.quads[v], 0, 0)
    love.graphics.setCanvas()
    table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('tiles', unpack(tileImgs))

local platformFrames = {}
for _, quad in ipairs(tileSheets.platform.quads) do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.platform.sheet, quad, 0, 0)
    love.graphics.setCanvas()
    table.insert(platformFrames, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('platformFrames', unpack(platformFrames))

local tileImgs2 = {}
for _, v in ipairs{'path', 'floor', 'wall'} do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.ts2.sheet, tileSheets.ts2.quads[v], 0, 0)
    love.graphics.setCanvas()
    table.insert(tileImgs2, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('tiles2', unpack(tileImgs2))

shaders.lifemana:send('lifemanaEmpty', gfx.hud.lifemanaEmpty)
