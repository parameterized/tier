
hud = {}

function hud.draw()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.draw(gfx.hud,
        math.floor(gsx/2 - gfx.hud:getWidth()/2), math.floor(gsy - gfx.hud:getHeight() - 2))
end
