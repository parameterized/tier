
player = {}

player.animTimer = 0
player.x, player.y = 0, 0
player.spd = 160

function player.update(dt)
    player.animTimer = player.animTimer + dt
    local dx, dy = 0, 0
    if love.keyboard.isDown('d') then
        dx = dx + 1
    end
    if love.keyboard.isDown('a') then
        dx = dx - 1
    end
    if love.keyboard.isDown('w') then
        dy = dy - 1
    end
    if love.keyboard.isDown('s') then
        dy = dy + 1
    end
    player.x = player.x + dx*player.spd*dt
    player.y = player.y + dy*player.spd*dt

    camera.x = math.floor(player.x)
    camera.y = math.floor(player.y)
end

function player.draw()
    if gameState == 'playing' then
        love.graphics.setColor(1, 1, 1)
        local frameIdx = math.floor(player.animTimer*12) % #anims.player.walk.quads + 1
        local quad = anims.player.walk.quads[frameIdx]
        local _, _, w, h = quad:getViewport()
        love.graphics.draw(anims.player.walk.sheet, quad,
            math.floor(player.x - w/2), math.floor(player.y - h/2))
    end
end
