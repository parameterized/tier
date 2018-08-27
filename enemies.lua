
enemies = {}

function enemies.spawn(etype, x, y)
    local t = {}
    t.type = etype
    t.hpMax = 5
    t.hp = math.random(1, t.hpMax)

    t.body = love.physics.newBody(physics.world, x, y, 'dynamic')
    t.polys = {
        {0.36, 0.64, 0.08, 0.36, 0.08, 0.2, 0.2, 0.08, 0.8, 0.08, 0.92, 0.2, 0.92, 0.36, 0.64, 0.64}
    }
    -- transform - todo: load from file already transformed
    local img = gfx.enemies.slime1
    for _, v in pairs(t.polys) do
        for i2, v2 in pairs(v) do
            if (i2-1) % 2 == 0 then -- x
                v[i2] = v2*img:getWidth() - img:getWidth()/2
            else
                v[i2] = v2*img:getWidth()*-1 + img:getHeight()/2
            end
        end
    end
    t.shapes = {}
    t.fixtures = {}
    for _, v in pairs(t.polys) do
        local shape = love.physics.newPolygonShape(unpack(v))
        table.insert(t.shapes, shape)
        local fixture = love.physics.newFixture(t.body, shape, 1)
        table.insert(t.fixtures, fixture)
        fixture:setCategory(3)
    end

    table.insert(enemies.container, t)
end

function enemies.load()
    enemies.container = {}
    for i=1, 8 do
        local etype = math.random() < 0.5 and 'slime1' or 'slime2'
        local x, y = (math.random()*2-1)*256, (math.random()*2-1)*256
        enemies.spawn(etype, x, y)
    end
end

function enemies.update(dt)

end

function enemies.draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- bodies
    for _, v in pairs(enemies.container) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader(shaders.outline)
        local img = gfx.enemies[v.type]
        shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
        love.graphics.push()
        local vx, vy = v.body:getPosition()
        love.graphics.translate(math.floor(vx), math.floor(vy))
        love.graphics.rotate(v.body:getAngle())
        love.graphics.draw(img,
            0, 0,
            0, 1, 1,
            math.floor(img:getWidth()/2), math.floor(img:getHeight()/2))
        love.graphics.pop()
    end

    -- hp bars
    love.graphics.setColor(1, 1, 1)
    for _, v in pairs(enemies.container) do
        love.graphics.setCanvas(canvases.hpBar)
        love.graphics.setShader(shaders.hpBar)
        shaders.hpBar:send('percent', v.hp/v.hpMax)
        love.graphics.push()
        love.graphics.origin()
        love.graphics.rectangle('fill', 0, 0, canvases.hpBar:getWidth(), canvases.hpBar:getHeight())
        love.graphics.pop()
        love.graphics.setCanvas(_canvas)
        love.graphics.setShader(_shader)
        love.graphics.push()
        local vx, vy = v.body:getPosition()
        love.graphics.translate(math.floor(vx), math.floor(vy))
        love.graphics.rotate(v.body:getAngle())
        love.graphics.draw(canvases.hpBar, math.floor(-canvases.hpBar:getWidth()/2), -15)
        love.graphics.pop()
    end

    -- collision debug
    if drawDebug then
        love.graphics.setColor(1, 0, 0, 0.5)
        for _, v in pairs(enemies.container) do
            love.graphics.push()
            local vx, vy = v.body:getPosition()
            love.graphics.translate(math.floor(vx), math.floor(vy))
            love.graphics.rotate(v.body:getAngle())
            for _, shape in pairs(v.shapes) do
                love.graphics.polygon('fill', shape:getPoints())
            end
            love.graphics.pop()
        end
    end
end
