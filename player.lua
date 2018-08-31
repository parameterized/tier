
player = {}

function player.load()
    player.walkTimer = 0
    player.swingTimer = 0
    player.swinging = false
    player.automaticSwing = true
    player.direction = 1
    player.spd = 6e2

    player.body = love.physics.newBody(physics.world, 0, 0, 'dynamic')
    player.shape = love.physics.newCircleShape(6)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setUserData(player)
    player.type = 'player'
    player.fixture:setCategory(1)
    player.body:setFixedRotation(true)
    player.body:setLinearDamping(10)
    player.body:setAngularDamping(10)

    player.projectiles = {}
end

function player.destroy()
    if player.fixture and not player.fixture:isDestroyed() then
        player.fixture:destroy()
    end
    if player.body and not player.body:isDestroyed() then
        player.body:destroy()
    end
end

function player.serialize()
    return {
        x = player.body:getX(), y = player.body:getY()
    }
end

function player.swing()
    local mx, my = love.mouse.getPosition()
    mx, my = screen2game(mx, my)
    player.direction = mx < gsx/2 and -1 or 1
    player.swinging = true
    player.swingTimer = 0

    local t = {}
    t.id = uuid()
    t.type = 'playerSwing'

    t.timer = 3
    t.pierce = 2

    local px, py = player.body:getPosition()
    t.body = love.physics.newBody(physics.world, px, py - 14, 'dynamic')
    t.polys = {
        {-0.2, 0.6, 0, 0.3, -0.1, 0.2},
        {0, 0.3, 0.1, 0, 0, -0.3, -0.1, -0.2, -0.1, 0.2},
        {-0.1, -0.2, 0, -0.3, -0.2, -0.6}
    }
    -- scale - todo: load from file already scaled
    for _, v in pairs(t.polys) do
        for i2, v2 in pairs(v) do
            v[i2] = v2*16
        end
    end
    t.shapes = {}
    t.fixtures = {}
    for _, v in pairs(t.polys) do
        local shape = love.physics.newPolygonShape(unpack(v))
        table.insert(t.shapes, shape)
        local fixture = love.physics.newFixture(t.body, shape, 1)
        fixture:setUserData(t)
        fixture:setCategory(2)
        fixture:setMask(1, 2)
        fixture:setSensor(true)
        table.insert(t.fixtures, fixture)
    end
    player.projectiles[t.id] = t

    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    t.body:setAngle(-a)
    t.body:setFixedRotation(true)
    t.body:setLinearVelocity(math.cos(a)*2e2, -math.sin(a)*2e2)
end

function player.update(dt)
    local mx, my = love.mouse.getPosition()
    mx, my = screen2game(mx, my)

    if not chat.active then
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
        if math.abs(vd) > 10 then
            if player.direction == 1 then
                if xv < 0 then player.direction = -1 end
            else
                if xv > 0 then player.direction = 1 end
            end
        end
        if player.automaticSwing and love.mouse.isDown(1) and not menu.buttonDown then
            player.swing()
        end
    end

    for k, v in pairs(player.projectiles) do
        v.timer = v.timer - dt
        if v.timer < 0 then
            for _, fix in pairs(v.fixtures) do
                fix:destroy()
            end
            v.body:destroy()
            player.projectiles[k] = nil
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
    if not player.automaticSwing and not player.swinging then
        player.swing()
    end
end

function player.draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- other players

    for _, v in pairs(client.currentState.players) do
        -- or debugger.show
        if v.id ~= player.id then
            -- shadow
            love.graphics.setColor(0, 0, 0, 0.2)
            local shadowWidth = 5
            love.graphics.ellipse('fill', math.floor(v.x), math.floor(v.y), shadowWidth, 2)

            -- player
            love.graphics.setCanvas(canvases.tempGame)
            love.graphics.setShader()
            love.graphics.clear()
            love.graphics.setColor(1, 1, 1)
            local quad = anims.player.swing.quads[1]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.swing.sheet, quad,
            math.floor(v.x), math.floor(v.y),
            0, 1, 1,
            23, h)

            -- outline
            love.graphics.setCanvas(_canvas)
            love.graphics.setShader(shaders.outline)
            love.graphics.setColor(1, 1, 1)
            love.graphics.push()
            love.graphics.origin()
            shaders.outline:send('stepSize', {
                1/canvases.tempGame:getWidth(),
                1/canvases.tempGame:getHeight()
            })
            love.graphics.draw(canvases.tempGame, 0, 0)
            love.graphics.pop()
            love.graphics.setShader(_shader)
        end
    end

    -- local player

    local px, py = player.body:getPosition()
    local xv, yv = player.body:getLinearVelocity()
    local vd = math.sqrt(xv^2 + yv^2)

    -- shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    local walkFrameIdx = math.floor(player.walkTimer*12) % #anims.player.walk.quads + 1
    local shadowWidth = ({6, 5, 4, 5, 5})[walkFrameIdx]
    if player.swinging or vd < 10 then shadowWidth = 6 end
    love.graphics.ellipse('fill', math.floor(px), math.floor(py), shadowWidth, 2)

    -- player
    love.graphics.setCanvas(canvases.tempGame)
    love.graphics.setShader()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    if player.swinging then
        local frameIdx = math.floor(player.swingTimer*12) + 1
        frameIdx = clamp(frameIdx, 1, 5)
        local quad = anims.player.swing.quads[frameIdx]
        local _, _, w, h = quad:getViewport()
        love.graphics.draw(anims.player.swing.sheet, quad,
        math.floor(px), math.floor(py),
        0, player.direction, 1,
        23, h)
    else
        if vd < 10 then
            local quad = anims.player.swing.quads[1]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.swing.sheet, quad,
            math.floor(px), math.floor(py),
            0, player.direction, 1,
            23, h)
        else
            local quad = anims.player.walk.quads[walkFrameIdx]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.walk.sheet, quad,
            math.floor(px), math.floor(py),
            0, player.direction, 1,
            8, h)
        end
    end

    -- projectiles
    for _, v in pairs(player.projectiles) do
        love.graphics.setColor(192/255, 192/255, 192/255)
        --[[
        for _, shape in pairs(v.shapes) do
            love.graphics.polygon('fill', v.body:getWorldPoints(shape:getPoints()))
        end
        ]]
        -- fix pixel jitter
        love.graphics.push()
        local vx, vy = v.body:getPosition()
        love.graphics.translate(math.floor(vx), math.floor(vy))
        love.graphics.rotate(v.body:getAngle())
        for _, shape in pairs(v.shapes) do
            love.graphics.polygon('fill', shape:getPoints())
        end
        love.graphics.pop()
    end

    -- outline
    love.graphics.setCanvas(_canvas)
    love.graphics.setShader(shaders.outline)
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    shaders.outline:send('stepSize', {
        1/canvases.tempGame:getWidth(),
        1/canvases.tempGame:getHeight()
    })
    love.graphics.draw(canvases.tempGame, 0, 0)
    love.graphics.pop()
    love.graphics.setShader(_shader)

    if drawDebug then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle('fill',
            math.floor(px), math.floor(py), player.shape:getRadius())
    end
end
