
projectiles = {
    server = {
        container = {}
    },
    client = {}
}

function projectiles.server.spawn(data)
    -- todo: more validation (type)
    local defaults = {
        x = 0, y = 0,
        angle = 0,
        speed = 2e2,
        life = 3,
        pierce = 2,
        damage = 5,
        color = {192/255, 192/255, 192/255}
    }
    for k, v in pairs(defaults) do
        if data[k] == nil then data[k] = v end
    end

    data.id = lume.uuid()
    data.type = 'playerSwing'
    data.spawnTime = gameTime
    data.body = love.physics.newBody(serverRealm.physics.world, data.x, data.y, 'dynamic')
    data.polys = {
        {-0.2, 0.6, 0, 0.3, -0.1, 0.2},
        {0, 0.3, 0.1, 0, 0, -0.3, -0.1, -0.2, -0.1, 0.2},
        {-0.1, -0.2, 0, -0.3, -0.2, -0.6}
    }
    -- scale - todo: load from file already scaled
    for _, v in pairs(data.polys) do
        for i2, v2 in pairs(v) do
            v[i2] = v2*16
        end
    end
    data.shapes = {}
    data.fixtures = {}
    -- main
    for _, v in pairs(data.polys) do
        local shape = love.physics.newPolygonShape(unpack(v))
        table.insert(data.shapes, shape)
        local fixture = love.physics.newFixture(data.body, shape, 1)
        fixture:setUserData(data)
        fixture:setCategory(2)
        fixture:setMask(1, 2)
        fixture:setSensor(true)
        table.insert(data.fixtures, fixture)
    end
    -- for collision with walls
    local a = -data.angle - math.pi/2
    local shape = love.physics.newCircleShape(math.cos(a)*14, -math.sin(a)*14, 1)
    table.insert(data.shapes, shape)
    local fixture = love.physics.newFixture(data.body, shape, 1)
    fixture:setUserData{type='playerSwingObstacleCollider', data=data}
    fixture:setCategory(2)
    fixture:setMask(1, 2)
    fixture:setSensor(true)
    table.insert(data.fixtures, fixture)

    data.body:setBullet(true)
    data.body:setAngle(-data.angle)
    data.body:setFixedRotation(true)
    data.body:setLinearVelocity(math.cos(data.angle)*data.speed, -math.sin(data.angle)*data.speed)

    projectiles.server.container[data.id] = data
    local state = {
        id = data.id,
        x = data.x, y = data.y,
        angle = data.angle,
        polys = data.polys,
        color = data.color
    }
    server.currentState.projectiles[data.id] = state
    server.added.projectiles[data.id] = state
end

function projectiles.server.destroy(id)
    local v = projectiles.server.container[id]
    if v then
        for _, fix in pairs(v.fixtures) do
            if not fix:isDestroyed() then fix:destroy() end
        end
        if not v.body:isDestroyed() then v.body:destroy() end
        projectiles.server.container[id] = nil
        server.currentState.projectiles[id] = nil
        server.removed.projectiles[id] = id
    end
end

function projectiles.server.reset()
    for k, v in pairs(projectiles.server.container) do
        projectiles.server.destroy(k)
    end
end

function projectiles.server.update(dt)
    for k, v in pairs(projectiles.server.container) do
        local sv = server.currentState.projectiles[v.id]
        if sv then
            sv.x, sv.y = v.body:getPosition()
        end
        if gameTime - v.spawnTime > v.life then
            projectiles.server.destroy(k)
        end
    end
end



function projectiles.client.draw()
    for _, v in pairs(client.currentState.projectiles) do
        if v.startedMoving then
            scene.add{
                draw = function()
                    local _canvas = love.graphics.getCanvas()
                    local _shader = love.graphics.getShader()
                    love.graphics.setCanvas(canvases.tempGame)
                    love.graphics.setShader()
                    love.graphics.clear()
                    love.graphics.setColor(v.color)
                    love.graphics.push()
                    love.graphics.translate(lume.round(v.x), lume.round(v.y))
                    love.graphics.rotate(-v.angle)
                    for _, poly in pairs(v.polys) do
                        love.graphics.polygon('fill', poly)
                    end
                    love.graphics.pop()

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
                    shaders.outline:send('outlineColor', {0, 0, 0, 1})
                    love.graphics.draw(canvases.tempGame, 0, 0)
                    love.graphics.pop()
                    love.graphics.setShader(_shader)
                end,
                y = v.y + 14
            }
        end
    end
end
