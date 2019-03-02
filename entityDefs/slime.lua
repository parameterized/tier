
local base = require 'entityDefs._base'
local slime = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    slime[sc].newDefaults = function()
        local t = {
            id = lume.uuid(),
            x = 0, y = 0,
            xv = 0, yv = 0,
            slimeType = math.random() < 0.5 and 'slime1' or 'slime2',
            hitBy = {}
        }
        t.level = math.random(1, 5)
        t.hpMax = 20 + 50*t.level
        t.hp = t.hpMax
        if sc == 'server' then
            t.base = base.server
            t.realm = serverRealm
        elseif sc == 'client' then
            t.base = base.client
            t.realm = clientRealm
        end
        return t
    end

    slime[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'dynamic')
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
                    v[i2] = v2*img:getWidth()*-1
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
            if sc == 'client' then
                fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
            end
        end
        self.body:setFixedRotation(true)
        self.body:setLinearDamping(10)
        return self.base.spawn(self)
    end

    slime[sc].destroy = function(self)
        if self.fixtures then
            for _, v in pairs(self.fixtures) do
                if not v:isDestroyed() then v:destroy() end
            end
        end
        if self.body and not self.body:isDestroyed() then
            self.body:destroy()
        end
        self.base.destroy(self)
    end

    slime[sc].type = 'slime'
    slime[sc].static = false
    slime[sc].enemy = true
end



function slime.server:serialize()
    local t = {}
    for _, v in ipairs{
        'id', 'type',
        'x', 'y', 'xv', 'yv',
        'slimeType', 'level', 'hpMax', 'hp'
    } do
        t[v] = self[v]
    end
    return t
end

function slime.server:update(dt)
    self.body:applyForce((math.random()*2 - 1)*6e2, (math.random()*2 - 1)*6e2)
    self.x, self.y = self.body:getPosition()
    self.xv, self.yv = self.body:getLinearVelocity()
    base.server.update(self, dt)
end

function slime.server:damage(d, clientId)
    serverEnemyDamage(self, d, clientId)
end



function slime.client:new(o)
    o = o or {}
    for k, v in pairs(self.newDefaults()) do
        if o[k] == nil then o[k] = v end
    end
    -- client-side attacking
    o.attackTimerMax = 3
    o.attackTimer = math.random()*o.attackTimerMax
    setmetatable(o, self)
    self.__index = self
    return o
end

function slime.client:setState(state)
    for _, v in ipairs{'x', 'y', 'xv', 'yv', 'slimeType', 'hpMax', 'hp'} do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end

function slime.client:lerpState(a, b, t)
    local state = {}
    for _, v in ipairs{'x', 'y', 'xv', 'yv'} do
        state[v] = lume.lerp(a[v], b[v], t)
    end
    for _, v in ipairs{'slimeType', 'hpMax', 'hp'} do
        state[v] = b[v]
    end
    self:setState(state)
end

function slime.client:update(dt)
    -- todo: simulate with future action prediction from server
    self.attackTimer = self.attackTimer - dt
    if self.attackTimer < 0 then
        self.attackTimer = self.attackTimer + self.attackTimerMax
        local p = playerController.player
        local a = math.atan2(p.x - self.x, p.y - self.y) - math.pi/2
        slimeBalls.spawn{slimeType=self.slimeType, x=self.x, y=self.y, angle=a}
    end
    base.client.update(self, dt)
end

function slime.client:draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- body
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders.outline)
    -- gfx.enemies.slime1
    local img = gfx.enemies[self.slimeType]
    shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
    shaders.outline:send('outlineColor', {0, 0, 0, 1})
    love.graphics.push()
    local vx, vy = self.body:getPosition()
    love.graphics.translate(lume.round(vx), lume.round(vy))
    love.graphics.draw(img, 0, 0, 0, 1, 1,
        lume.round(img:getWidth()/2), img:getHeight())
    love.graphics.pop()

    -- hp
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
    love.graphics.translate(lume.round(vx), lume.round(vy))
    love.graphics.draw(canvases.hpBar, lume.round(-canvases.hpBar:getWidth()/2), 2)
    love.graphics.pop()

    -- name, level
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    local wmx, wmy = camera:screen2world(mx, my)
    if wmx > vx - img:getWidth()/2 and wmx < vx + img:getWidth()/2
    and wmy > vy - img:getHeight() and wmy < vy then
        love.graphics.setColor(1, 1, 1)
        local font = fonts.c17
        love.graphics.setFont(font)
        local name = string.format('Slime [Level %i]', self.level)
        text.printSmall(name,
            lume.round(vx) - lume.round(font:getWidth(name)/4),
            lume.round(vy) - img:getHeight() - 12)
    end
end



return slime
