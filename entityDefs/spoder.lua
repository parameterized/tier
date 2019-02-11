
local base = require 'entityDefs._base'
local spoder = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    spoder[sc].newDefaults = function()
        local t = {
            id = lume.uuid(),
            x = 0, y = 0,
            xv = 0, yv = 0,
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

    spoder[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'dynamic')
        self.shapes = {}
        self.fixtures = {}

        -- collision
        local shape = love.physics.newCircleShape(8)
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(3)
        if sc == 'client' then
            fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
        end

        -- projectile damage
        local img = gfx.enemies.spoder
        local shape = love.physics.newRectangleShape(
            0, -img:getHeight()/2, img:getWidth(), img:getHeight())
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(3)
        if sc == 'client' then
            fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
        end
        fixture:setSensor(true)

        self.body:setFixedRotation(true)
        self.body:setLinearDamping(10)
        return self.base.spawn(self)
    end

    spoder[sc].destroy = function(self)
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

    spoder[sc].type = 'spoder'
    spoder[sc].static = false
    spoder[sc].enemy = true
end



function spoder.server:serialize()
    local t = {}
    for _, v in ipairs{
        'id', 'type',
        'x', 'y', 'xv', 'yv',
        'level', 'hpMax', 'hp'
    } do
        t[v] = self[v]
    end
    return t
end

function spoder.server:update(dt)
    self.body:applyForce((math.random()*2 - 1)*6e2, (math.random()*2 - 1)*6e2)
    self.x, self.y = self.body:getPosition()
    self.xv, self.yv = self.body:getLinearVelocity()
    base.server.update(self, dt)
end

function spoder.server:damage(d, clientId)
    serverEnemyDamage(self, d, clientId)
end



function spoder.client:new(o)
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

function spoder.client:setState(state)
    for _, v in ipairs{'x', 'y', 'xv', 'yv', 'hpMax', 'hp'} do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end

function spoder.client:lerpState(a, b, t)
    local state = {}
    for _, v in ipairs{'x', 'y', 'xv', 'yv'} do
        state[v] = lume.lerp(a[v], b[v], t)
    end
    for _, v in ipairs{'hpMax', 'hp'} do
        state[v] = b[v]
    end
    self:setState(state)
end

function spoder.client:update(dt)
    -- todo: simulate with future action prediction from server
    self.attackTimer = self.attackTimer - dt
    if self.attackTimer < 0 then
        self.attackTimer = self.attackTimer + self.attackTimerMax
        local p = playerController.player
        local a = math.atan2(p.x - self.x, p.y - self.y) - math.pi/2
        slimeBalls.spawn{x=self.x, y=self.y, angle=a}
    end
    base.client.update(self, dt)
end

function spoder.client:draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- body
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders.outline)
    local img = gfx.enemies.spoder
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
        local name = string.format('Spoder [Level %i]', self.level)
        text.printSmall(name,
            lume.round(vx) - lume.round(font:getWidth(name)/4),
            lume.round(vy) - img:getHeight() - 12)
    end
end



return spoder
