
hud = {}

function hud.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(gfx.hud,
        math.floor(gsx/2 - gfx.hud:getWidth()/2), math.floor(gsy - gfx.hud:getHeight()))
end
