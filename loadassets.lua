
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
        icons = {
            vit = love.graphics.newImage('gfx/ui/icons/vit.png'),
            atk = love.graphics.newImage('gfx/ui/icons/atk.png'),
            spd = love.graphics.newImage('gfx/ui/icons/spd.png'),
            wis = love.graphics.newImage('gfx/ui/icons/wis.png'),
            def = love.graphics.newImage('gfx/ui/icons/def.png'),
            reg = love.graphics.newImage('gfx/ui/icons/reg.png')
        },
        buttons = {
            up = love.graphics.newImage('gfx/ui/buttons/up.png'),
            down = love.graphics.newImage('gfx/ui/buttons/down.png'),
            left = love.graphics.newImage('gfx/ui/buttons/left.png'),
            right = love.graphics.newImage('gfx/ui/buttons/right.png')
        },
        bag = love.graphics.newImage('gfx/ui/bagui.png'),
        itemInfo = {
            base = love.graphics.newImage('gfx/ui/item_info/base.png'),
            tierColor = love.graphics.newImage('gfx/ui/item_info/tier_color.png'),
            specialIcon = love.graphics.newImage('gfx/ui/item_info/special_icon.png')
        },
        quest = love.graphics.newImage('gfx/ui/questui.png')
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
        allTiles = love.graphics.newImage('gfx/tiles/all_tiles.png'),
        smoothTiles = love.graphics.newImage('gfx/tiles/smooth_tiles.png')
    },
    environment = {
        wall = love.graphics.newImage('gfx/environment/wall.png'),
        tree = love.graphics.newImage('gfx/environment/tree.png'),
        bush = love.graphics.newImage('gfx/environment/bush.png'),
        bigRock = love.graphics.newImage('gfx/environment/bigRock.png'),
        smallRock = love.graphics.newImage('gfx/environment/smallRock.png'),
        questBlock = love.graphics.newImage('gfx/environment/questBlock.png')
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
        armor = {
            armor0 = {
                chest = {
                    walk = love.graphics.newImage('gfx/player/armor/armor0/chest/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor0/chest/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor0/chest/walk_and_swing.png')
                },
                helmet = {
                    walk = love.graphics.newImage('gfx/player/armor/armor0/helmet/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor0/helmet/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor0/helmet/walk_and_swing.png')
                },
                pants = {
                    walk = love.graphics.newImage('gfx/player/armor/armor0/pants/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor0/pants/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor0/pants/walk_and_swing.png')
                }
            },
            armor1 = {
                chest = {
                    walk = love.graphics.newImage('gfx/player/armor/armor1/chest/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor1/chest/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor1/chest/walk_and_swing.png')
                },
                helmet = {
                    walk = love.graphics.newImage('gfx/player/armor/armor1/helmet/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor1/helmet/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor1/helmet/walk_and_swing.png')
                },
                pants = {
                    walk = love.graphics.newImage('gfx/player/armor/armor1/pants/walk.png'),
                    swing = love.graphics.newImage('gfx/player/armor/armor1/pants/swing.png'),
                    walkAndSwing = love.graphics.newImage('gfx/player/armor/armor1/pants/walk_and_swing.png')
                }
            }
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
        apple = love.graphics.newImage('gfx/items/apple.png'),
        armor0Helmet = love.graphics.newImage('gfx/items/armor0_helmet.png'),
        armor0Chest = love.graphics.newImage('gfx/items/armor0_chest.png'),
        armor0Pants = love.graphics.newImage('gfx/items/armor0_pants.png'),
        armor1Helmet = love.graphics.newImage('gfx/items/armor1_helmet.png'),
        armor1Chest = love.graphics.newImage('gfx/items/armor1_chest.png'),
        armor1Pants = love.graphics.newImage('gfx/items/armor1_pants.png')
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
    armor = {
        armor0 = {
            chest = {
                walk = newAnim(gfx.player.armor.armor0.chest.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor0.chest.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor0.chest.walkAndSwing, 43, 34, 1, 5)
            },
            helmet = {
                walk = newAnim(gfx.player.armor.armor0.helmet.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor0.helmet.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor0.helmet.walkAndSwing, 43, 34, 1, 5)
            },
            pants = {
                walk = newAnim(gfx.player.armor.armor0.pants.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor0.pants.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor0.pants.walkAndSwing, 43, 34, 1, 5)
            }
        },
        armor1 = {
            chest = {
                walk = newAnim(gfx.player.armor.armor1.chest.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor1.chest.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor1.chest.walkAndSwing, 43, 34, 1, 5)
            },
            helmet = {
                walk = newAnim(gfx.player.armor.armor1.helmet.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor1.helmet.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor1.helmet.walkAndSwing, 43, 34, 1, 5)
            },
            pants = {
                walk = newAnim(gfx.player.armor.armor1.pants.walk, 20, 31, 1, 5),
                swing = newAnim(gfx.player.armor.armor1.pants.swing, 43, 34, 1, 5),
                walkAndSwing = newAnim(gfx.player.armor.armor1.pants.walkAndSwing, 43, 34, 1, 5)
            }
        }
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
        local quad = love.graphics.newQuad(x, y, w, h, sw, sh)
        t.quads[i] = quad
        if names[i] then
            t.quads[names[i]] = quad
        end
    end
    return t
end

tileSheets.allTiles = newTileSheet(gfx.tiles.allTiles, 15, 15, 1, 9,
    {'water', 'sand', 'grass', 'rock', 'path', 'floor', 'wall', 'platform', 'platform2'})
tileSheets.smoothTiles = newTileSheet(gfx.tiles.smoothTiles, 15, 15, 1, 16)

fonts = {
    f10 = love.graphics.newFont(10),
    f12 = love.graphics.newFont(12),
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24),

    c13 = love.graphics.newImageFont('gfx/fonts/small_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>'),
    c17 = love.graphics.newImageFont('gfx/fonts/big_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`\'*#=[]"|~@$^_{}<>'),
    stats = love.graphics.newImageFont('gfx/fonts/stat_font.png', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/\'"%')
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
for i=1, 9 do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.allTiles.sheet, tileSheets.allTiles.quads[i], 0, 0)
    love.graphics.setCanvas()
    table.insert(tileImgs, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('tiles', unpack(tileImgs))

smoothTileImgs = {}
for i=1, 16 do
    love.graphics.setCanvas(tileCanv)
    love.graphics.clear()
    love.graphics.draw(tileSheets.smoothTiles.sheet, tileSheets.smoothTiles.quads[i], 0, 0)
    love.graphics.setCanvas()
    table.insert(smoothTileImgs, love.graphics.newImage(tileCanv:newImageData()))
end
shaders.mapRender:send('smoothTiles', unpack(smoothTileImgs))

shaders.lifemana:send('lifemanaEmpty', gfx.hud.lifemanaEmpty)

sfx = {
    select = love.audio.newSource('sfx/Select.wav', 'static'),
    select2 = love.audio.newSource('sfx/Select2.wav', 'static'),
    death = love.audio.newSource('sfx/Death.wav', 'static'),
    heal = love.audio.newSource('sfx/Heal2.wav', 'static'),
    hurt = love.audio.newSource('sfx/Hurt.wav', 'static'),
    scream = love.audio.newSource('sfx/Scream.wav', 'static'),
    spider = love.audio.newSource('sfx/Spider.wav', 'static')
}
