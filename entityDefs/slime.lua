
local base = require 'entityDefs._base'
local slime = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in pairs{'server', 'client'} do
    slime[sc].type = 'slime'
    slime[sc].static = false
    slime[sc].enemy = true
end

function slime.server:new(o)
    o = o or {}
    local defaults = {
        id = uuid(),
        x = 0, y = 0,
        xv = 0, yv = 0,
        slimeType = math.random() < 0.5 and 'slime1' or 'slime2',
        hpMax = 5, hp = math.random(1, 5),
        hitBy = {}
    }
    for k, v in pairs(defaults) do
        if o[k] == nil then o[k] = v end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function slime.server:spawn()
    self.body = love.physics.newBody(physics.server.world, self.x, self.y, 'dynamic')
    self.polys = {
        {0.36, 0.64, 0.08, 0.36, 0.08, 0.2, 0.2, 0.08, 0.8, 0.08, 0.92, 0.2, 0.92, 0.36, 0.64, 0.64}
    }
    -- transform - todo: load from file already transformed
    local img = gfx.enemies.slime1
    for _, v in pairs(self.polys) do
        for i2, v2 in pairs(v) do
            if (i2-1) % 2 == 0 then -- x
                v[i2] = v2*img:getWidth() - img:getWidth()/2
            else
                v[i2] = v2*img:getWidth()*-1 + img:getHeight()/2
            end
        end
    end
    self.shapes = {}
    self.fixtures = {}
    for _, v in pairs(self.polys) do
        local shape = love.physics.newPolygonShape(unpack(v))
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(3)
    end
    self.body:setFixedRotation(true)
    self.body:setLinearDamping(10)
    return base.server.spawn(self)
end

function slime.server:serialize()
    return {
        id = self.id, type = self.type,
        x = self.x, y = self.y,
        xv = self.xv, yv = self.yv,
        slimeType = self.slimeType,
        hpMax = self.hpMax, hp = self.hp
    }
end

function slime.server:update(dt)
    self.body:applyForce((math.random()*2 - 1)*6e2, (math.random()*2 - 1)*6e2)
    self.x, self.y = self.body:getPosition()
    self.xv, self.yv = self.body:getLinearVelocity()
    base.server.update(self, dt)
end

function slime.server:damage(d, clientId)
    self.hp = self.hp - d
    if self.hp <= 0 and not self.destroyed then
        --server.addPoints(clientId, 1)
        for i=1, math.random(1, 2) do
            local x = self.x + (math.random()*2-1)*64
            local y = self.y + (math.random()*2-1)*64
            self:new{x=x, y=y}:spawn()
        end
        if math.random() < 0.5 then
            local i = math.min(math.floor(math.random()*3), 2) + 1
            local type = ({'lootBag', 'lootBag1', 'lootBagFuse'})[i]
            lootBags.server.spawn{
                x = self.x, y = self.y,
                items = {'apl', 'banan'},
                life = 10,
                type = type
            }
        end
        self:destroy()
    end
end

function slime.server:destroy()
    if self.fixtures then
        for _, v in pairs(self.fixtures) do
            if not v:isDestroyed() then v:destroy() end
        end
    end
    if self.body and not self.body:isDestroyed() then
        self.body:destroy()
    end
    base.server.destroy(self)
end

--[[
function slime.server:freeze()
    self.body:setType('static')
    base.server.freeze(self)
end

function slime.server:unfreeze()
    self.body:setType('dynamic')
    base.server.unfreeze(self)
end
]]



function slime.client:new(o)
    o = o or {}
    local defaults = {
        id = uuid(),
        x = 0, y = 0,
        hpMax = 5,
        hp = math.random(1, 5),
        hitBy = {}
    }
    for k, v in pairs(defaults) do
        if o[k] == nil then o[k] = v end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end


function slime.client:spawn()
    self.body = love.physics.newBody(physics.client.world, self.x, self.y, 'dynamic')
    self.polys = {
        {0.36, 0.64, 0.08, 0.36, 0.08, 0.2, 0.2, 0.08, 0.8, 0.08, 0.92, 0.2, 0.92, 0.36, 0.64, 0.64}
    }
    -- transform - todo: load from file already transformed
    local img = gfx.enemies.slime1
    for _, v in pairs(self.polys) do
        for i2, v2 in pairs(v) do
            if (i2-1) % 2 == 0 then -- x
                v[i2] = v2*img:getWidth() - img:getWidth()/2
            else
                v[i2] = v2*img:getWidth()*-1 + img:getHeight()/2
            end
        end
    end
    self.shapes = {}
    self.fixtures = {}
    for _, v in pairs(self.polys) do
        local shape = love.physics.newPolygonShape(unpack(v))
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(3)
        fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
    end
    self.body:setFixedRotation(true)
    self.body:setLinearDamping(10)
    return base.client.spawn(self)
end

function slime.client:setState(state)
    for _, v in pairs{'x', 'y', 'xv', 'yv', 'slimeType', 'hpMax', 'hp'} do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end

function slime.client:lerpState(a, b, t)
    local state = {}
    for _, v in pairs{'x', 'y', 'xv', 'yv'} do
        state[v] = lerp(a[v], b[v], t)
    end
    for _, v in pairs{'slimeType', 'hpMax', 'hp'} do
        state[v] = b[v]
    end
    self:setState(state)
end

function slime.client:update(dt)
    -- todo: simulate with future action prediction from server
    base.client.update(self, dt)
end

function slime.client:drawBody()
    local _shader = love.graphics.getShader()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders.outline)
    -- gfx.enemies.slime1
    local img = gfx.enemies[self.slimeType]
    shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
    love.graphics.push()
    local vx, vy = self.body:getPosition()
    love.graphics.translate(math.floor(vx), math.floor(vy))
    love.graphics.draw(img,
        0, 0,
        0, 1, 1,
        math.floor(img:getWidth()/2), math.floor(img:getHeight()/2))
    love.graphics.pop()
    love.graphics.setShader(_shader)
end

function slime.client:drawHP()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas(canvases.hpBar)
    love.graphics.setShader(shaders.hpBar)
    shaders.hpBar:send('percent', self.hp/self.hpMax)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.rectangle('fill', 0, 0, canvases.hpBar:getWidth(), canvases.hpBar:getHeight())
    love.graphics.pop()
    love.graphics.setCanvas(_canvas)
    love.graphics.setShader(_shader)
    love.graphics.push()
    local vx, vy = self.body:getPosition()
    love.graphics.translate(math.floor(vx), math.floor(vy))
    love.graphics.draw(canvases.hpBar, math.floor(-canvases.hpBar:getWidth()/2), 10)
    love.graphics.pop()
end

function slime.client:destroy()
    if self.fixtures then
        for _, v in pairs(self.fixtures) do
            if not v:isDestroyed() then v:destroy() end
        end
    end
    if self.body and not self.body:isDestroyed() then
        self.body:destroy()
    end
    base.client.destroy(self)
end



return slime