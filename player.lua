
player = {}

player.animTimer = 0

function player.update(dt)
    player.animTimer = player.animTimer + dt
end

function player.draw()
    love.graphics.setColor(1, 1, 1)
    local frameIdx = math.floor(player.animTimer*12) % #anim.player.walk.quads + 1
    local quad = anim.player.walk.quads[frameIdx]
    local _, _, w, h = quad:getViewport()
    love.graphics.draw(anim.player.walk.sheet, quad,
        math.floor(gsx/2 - w/2), math.floor(gsy/2 - h/2)
    )
end
