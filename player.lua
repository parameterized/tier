
player = {}

function player.load()
    player.walkTimer = 0
    player.swingTimer = 0
    player.swinging = false
    player.direction = 1
    player.spd = 6e2

    player.body = love.physics.newBody(physics.world, 0, 0, 'dynamic')
    player.shape = love.physics.newCircleShape(6)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.body:setLinearDamping(10)
    player.body:setAngularDamping(10)
end

function player.update(dt)
    local mx, my = love.mouse.getPosition()
    mx, my = screen2game(mx, my)

    local dx, dy = 0, 0
	dx = dx + (love.keyboard.isScancodeDown('d') and 1 or 0)
	dx = dx + (love.keyboard.isScancodeDown('a') and -1 or 0)
	dy = dy + (love.keyboard.isScancodeDown('w') and -1 or 0)
	dy = dy + (love.keyboard.isScancodeDown('s') and 1 or 0)
    local spd = player.spd*(love.keyboard.isScancodeDown('lshift') and 2.5 or 1)
    if not (dx == 0 and dy == 0) and not player.swinging then
        local a = math.atan2(dx, dy) - math.pi/2
        player.body:applyForce(math.cos(a)*spd, -math.sin(a)*spd)
    end

    player.body:applyTorque(-player.body:getAngle()*1e5)

    local xv, yv = player.body:getLinearVelocity()
    local vd = math.sqrt(xv^2 + yv^2)
    player.walkTimer = player.walkTimer + vd*0.01*dt

    if player.swinging then
        player.swingTimer = player.swingTimer + dt
        if player.swingTimer > 5/12 then
            player.swinging = false
        end
    else
        if math.abs(xv) > 10 then
            if player.direction == 1 then
                if xv < 0 then player.direction = -1 end
            else
                if xv > 0 then player.direction = 1 end
            end
        end
    end

    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local d = math.min(math.sqrt(dx^2 + dy^2), gsy/2)
    camera.x = math.floor(player.body:getX()) + math.floor(math.cos(a)*d/6)
    camera.y = math.floor(player.body:getY() - 14) + math.floor(-math.sin(a)*d/6)
end

function player.mousepressed(mx, my, btn)
    mx, my = screen2game(mx, my)
    if btn == 1 then
        if not player.swinging then
            player.direction = mx < gsx/2 and -1 or 1
            player.swinging = true
            player.swingTimer = 0
        end
    end
end

function player.draw()
    local px, py = player.body:getPosition()
    love.graphics.setColor(0, 0, 0, 0.2)
    local walkFrameIdx = math.floor(player.walkTimer*12) % #anims.player.walk.quads + 1
    local shadowWidth = ({6, 5, 4, 5, 5})[walkFrameIdx]
    if player.swinging then shadowWidth = 6 end
    love.graphics.ellipse('fill', math.floor(px), math.floor(py), shadowWidth, 2)
    love.graphics.setColor(1, 1, 1)
    if player.swinging then
        local frameIdx = math.floor(player.swingTimer*12) + 1
        frameIdx = clamp(frameIdx, 1, 5)
        local quad = anims.player.swing.quads[frameIdx]
        local _, _, w, h = quad:getViewport()
        love.graphics.draw(anims.player.swing.sheet, quad,
            math.floor(px), math.floor(py),
            0, player.direction, 1,
            22, h)
    else
        local quad = anims.player.walk.quads[walkFrameIdx]
        local _, _, w, h = quad:getViewport()
        love.graphics.draw(anims.player.walk.sheet, quad,
            math.floor(px), math.floor(py),
            0, player.direction, 1,
            math.floor(w/2), h)
    end
    if false then
        love.graphics.setColor(0, 0, 0.5, 0.5)
        love.graphics.circle('fill',
            math.floor(px), math.floor(py), player.shape:getRadius())
    end
end
