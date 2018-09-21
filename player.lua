
player = {}

function player.load()
    player.walkTimer = 0
    player.swingTimer = 0
    player.swinging = false
    player.automaticSwing = true
    player.direction = 1
    player.spd = 6e2

    player.xp = 0
    player.level = 0
    player.stats = player.newStats()

    player.body = love.physics.newBody(physics.client.world, 0, 0, 'dynamic')
    player.shape = love.physics.newCircleShape(6)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setUserData(player)
    player.type = 'player'
    player.fixture:setCategory(1)
    player.body:setFixedRotation(true)
    player.body:setLinearDamping(10)
end

function player.xp2level(x)
    return math.sqrt(x)/2
end

function player.newStats()
    local t = {
        vit = {base = 100, arm = 14},
        atk = {base = 80, arm = 25},
        spd = {base = 50, arm = 9},
        wis = {base = 100, arm = 8},
        def = {base = 20, arm = 25},
        reg = {base = 50, arm = 10}
    }
    for _, v in pairs(t) do
        v.total = v.base + v.arm
    end
    return t
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
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    player.direction = mx < gsx/2 and -1 or 1
    player.swinging = true
    player.swingTimer = 0
    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local px, py = player.body:getPosition()
    client.spawnProjectile{
        x = px, y = py - 14,
        angle = a,
        speed = 2e2,
        life = 3,
        pierce = 2
    }
end

function player.update(dt)
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)

    if not chat.active then
        local dx, dy = 0, 0
        dx = dx + (love.keyboard.isScancodeDown('d') and 1 or 0)
        dx = dx + (love.keyboard.isScancodeDown('a') and -1 or 0)
        dy = dy + (love.keyboard.isScancodeDown('w') and -1 or 0)
        dy = dy + (love.keyboard.isScancodeDown('s') and 1 or 0)
        local spd = player.spd*(love.keyboard.isScancodeDown('lshift') and 2.5 or 1)
        if not (dx == 0 and dy == 0)
        and not (player.swinging or player.automaticSwing and love.mouse.isDown(1) and not uiMouseDown) then
            local a = math.atan2(dx, dy) - math.pi/2
            player.body:applyForce(math.cos(a)*spd, -math.sin(a)*spd)
        end
    end

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
        if player.automaticSwing and love.mouse.isDown(1) and not uiMouseDown then
            player.swing()
        end
    end

    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local d = math.min(math.sqrt(dx^2 + dy^2), gsy/2)
    camera.x = lume.round(player.body:getX()) + lume.round(math.cos(a)*d/6)
    camera.y = lume.round(player.body:getY() - 14) + lume.round(-math.sin(a)*d/6)
end

function player.mousepressed(x, y, btn)
    if not player.automaticSwing and not player.swinging and not uiMouseDown then
        player.swing()
    end
end

function player.mousereleased(x, y, btn)

end

function player.draw()

    -- other players

    for _, v in pairs(client.currentState.players) do
        -- or debugger.show
        if v.id ~= player.id then
            scene.add{
                draw = function()
                    local _canvas = love.graphics.getCanvas()
                    local _shader = love.graphics.getShader()
                    -- shadow
                    love.graphics.setColor(0, 0, 0, 0.2)
                    local shadowWidth = 5
                    love.graphics.ellipse('fill', lume.round(v.x), lume.round(v.y), shadowWidth, 2)

                    -- player
                    love.graphics.setCanvas(canvases.tempGame)
                    love.graphics.setShader()
                    love.graphics.clear()
                    love.graphics.setColor(1, 1, 1)
                    local quad = anims.player.swing.quads[1]
                    local _, _, w, h = quad:getViewport()
                    love.graphics.draw(anims.player.swing.sheet, quad,
                        lume.round(v.x), lume.round(v.y),
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

                    -- name
                    local font = fonts.c17
                    love.graphics.setFont(font)
                    text.printSmall(v.name, lume.round(v.x) - font:getWidth(v.name)/4, lume.round(v.y) - 40)
                end,
                y = v.y
            }
        end
    end

    -- local player

    local px, py = player.body:getPosition()
    local xv, yv = player.body:getLinearVelocity()
    local vd = math.sqrt(xv^2 + yv^2)

    scene.add{
        draw = function()
            local _canvas = love.graphics.getCanvas()
            local _shader = love.graphics.getShader()
            -- shadow
            love.graphics.setColor(0, 0, 0, 0.2)
            local walkFrameIdx = math.floor(player.walkTimer*12) % #anims.player.walk.quads + 1
            local shadowWidth = ({6, 5, 4, 5, 5})[walkFrameIdx]
            if player.swinging or vd < 10 then shadowWidth = 6 end
            love.graphics.ellipse('fill', lume.round(px), lume.round(py), shadowWidth, 2)

            -- player
            love.graphics.setCanvas(canvases.tempGame)
            love.graphics.setShader()
            love.graphics.clear()
            love.graphics.setColor(1, 1, 1)
            if player.swinging then
                local frameIdx = math.floor(player.swingTimer*12) + 1
                frameIdx = lume.clamp(frameIdx, 1, 5)
                local quad = anims.player.swing.quads[frameIdx]
                local _, _, w, h = quad:getViewport()
                love.graphics.draw(anims.player.swing.sheet, quad,
                    lume.round(px), lume.round(py),
                    0, player.direction, 1,
                    23, h)
            else
                if vd < 10 then
                    local quad = anims.player.swing.quads[1]
                    local _, _, w, h = quad:getViewport()
                    love.graphics.draw(anims.player.swing.sheet, quad,
                        lume.round(px), lume.round(py),
                        0, player.direction, 1,
                        23, h)
                else
                    local quad = anims.player.walk.quads[walkFrameIdx]
                    local _, _, w, h = quad:getViewport()
                    love.graphics.draw(anims.player.walk.sheet, quad,
                        lume.round(px), lume.round(py),
                        0, player.direction, 1,
                        8, h)
                end
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

            -- name
            local font = fonts.c17
            love.graphics.setFont(font)
            text.printSmall(player.name, lume.round(px) - font:getWidth(player.name)/4, lume.round(py) - 40)

            if drawDebug then
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.circle('fill',
                    lume.round(px), lume.round(py), player.shape:getRadius())
            end
        end,
        y = py
    }
end
