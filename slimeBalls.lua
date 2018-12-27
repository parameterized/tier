
-- todo: generalize projectiles and put code there

slimeBalls = {
    container = {}
}

slimeBalls.slimeType2color = {
    slime1 = {0/255, 101/255, 234/255, 174/255},
    slime2 = {0/255, 234/255, 101/255, 174/255}
}

function slimeBalls.spawn(t)
    local defaults = {
        slimeType = 'slime1',
        x = 0, y = 0,
        angle = 0,
        speed = 1.5e2,
        life = 1,
        pierce = 0,
        damage = 5
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end

    t.id = lume.uuid()
    t.type = 'slimeBall'
    t.color = slimeBalls.slimeType2color[t.slimeType]
    t.spawnTime = gameTime
    t.body = love.physics.newBody(clientRealm.physics.world, t.x, t.y, 'dynamic')
    t.shape = love.physics.newCircleShape(5)
    t.fixture = love.physics.newFixture(t.body, t.shape, 1)
    t.fixture:setUserData(t)
    t.fixture:setCategory(3)

    t.body:setAngle(-t.angle)
    t.body:setFixedRotation(true)
    t.body:setLinearVelocity(math.cos(t.angle)*t.speed, -math.sin(t.angle)*t.speed)

    slimeBalls.container[t.id] = t
end

function slimeBalls.destroy(id)
    local v = slimeBalls.container[id]
    if v then
        if not v.fixture:isDestroyed() then v.fixture:destroy() end
        if not v.body:isDestroyed() then v.body:destroy() end
        slimeBalls.container[id] = nil
    end
end

function slimeBalls.reset()
    for k, v in pairs(slimeBalls.container) do
        slimeBalls.destroy(k)
    end
end

function slimeBalls.update(dt)
    for k, v in pairs(slimeBalls.container) do
        if gameTime - v.spawnTime > v.life then
            slimeBalls.destroy(k)
        end
    end
end

function slimeBalls.draw()
    for k, v in pairs(slimeBalls.container) do
        scene.add{
            draw = function()
                local _shader = love.graphics.getShader()
                love.graphics.setShader(shaders.outline)
                shaders.outline:send('stepSize', {
                    1/gfx.slimeBall:getWidth(),
                    1/gfx.slimeBall:getHeight()
                })
                shaders.outline:send('outlineColor', {0, 0, 0, 1})
                love.graphics.setColor(v.color)
                local x, y = v.body:getPosition()
                love.graphics.draw(gfx.slimeBall, lume.round(x), lume.round(y), 0, 1, 1,
                    lume.round(gfx.slimeBall:getWidth()/2), lume.round(gfx.slimeBall:getHeight()/2))
                love.graphics.setShader(_shader)
            end,
            y = v.body:getY()
        }
    end
end
