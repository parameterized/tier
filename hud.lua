
hud = {}

function hud.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(gfx.hud.frame, 0, 0)
    love.graphics.draw(gfx.hud.xpbar, math.floor(gsx/2), gsy - 5, 0, 1, 1,
        math.floor(gfx.hud.xpbar:getWidth()/2), gfx.hud.xpbar:getHeight())
    love.graphics.draw(gfx.hud.cog, 307, 248, 0, 1, 1,
        math.floor(gfx.hud.cog:getWidth()/2), math.floor(gfx.hud.cog:getHeight()/2))
    love.graphics.draw(gfx.hud.map, 466, 257, 0, 1, 1,
        gfx.hud.map:getWidth(), gfx.hud.map:getHeight())
    love.graphics.draw(gfx.hud.inventory, 0, 265, 0, 1, 1,
        0, gfx.hud.inventory:getHeight())
    love.graphics.draw(gfx.hud.dropDown, 99, 183, math.pi/2, 1, 1,
        math.floor(gfx.hud.dropDown:getWidth()/2), math.floor(gfx.hud.dropDown:getHeight()/2))
    love.graphics.draw(gfx.hud.lifemana, 11, 18)
    love.graphics.draw(gfx.hud.dropDown, 143, 22)
    love.graphics.draw(gfx.hud.pause, 453, 18)

    love.graphics.setFont(fonts.c17)
    text.print(player.name, 44, 5)
end
