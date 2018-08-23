
ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.graphics.setDefaultFilter('nearest', 'nearest')

gsx, gsy = 480, 270
canvases = {
    game = love.graphics.newCanvas(gsx, gsy)
}

fonts = {
    f10 = love.graphics.newFont(10),
    f12 = love.graphics.newFont(12),
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24)
}

gfx = {
    logo = love.graphics.newImage('gfx/logo.png'),
    player = {
        walkSheet = love.graphics.newImage('gfx/char/char-walk.png')
    }
}

anim = {}
function newAnim(sheet, w, h, pad, num)
    local t = {
        sheet = sheet,
        quads = {}
    }
    for i=1, num do
        local x = (i-1)*(w + pad)
        local y = 0
        table.insert(t.quads, love.graphics.newQuad(
            x, y, w, h, sheet:getWidth(), sheet:getHeight()
        ))
    end
    return t
end

anim.player = {
    walk = newAnim(gfx.player.walkSheet, 14, 22, 0, 6)
}
