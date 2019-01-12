
local base = require 'entityDefs._base'
local godex = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    godex[sc].newDefaults = function()
        local t = {
            id = lume.uuid(),
            x = 0, y = 0,
            xv = 0, yv = 0,
            hpMax = 25, hp = math.random(20, 25),
            hitBy = {}
        }
        if sc == 'server' then
            t.base = base.server
            t.realm = serverRealm
        elseif sc == 'client' then
            t.base = base.client
            t.realm = clientRealm
        end
        return t
    end

    godex[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'dynamic')
        self.shapes = {}
        self.fixtures = {}
        local shape = love.physics.newCircleShape(8)
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(3)
        if sc == 'client' then
            fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
        end
        self.body:setFixedRotation(true)
        self.body:setLinearDamping(10)
        return self.base.spawn(self)
    end

    godex[sc].destroy = function(self)
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

    godex[sc].type = 'godex'
    godex[sc].static = false
    godex[sc].enemy = true
end



function godex.server:serialize()
    local t = {}
    for _, v in ipairs{
        'id', 'type',
        'x', 'y', 'xv', 'yv',
        'hpMax', 'hp'
    } do
        t[v] = self[v]
    end
    return t
end

function godex.server:update(dt)
    self.body:applyForce((math.random()*2 - 1)*6e2, (math.random()*2 - 1)*6e2)
    self.x, self.y = self.body:getPosition()
    self.xv, self.yv = self.body:getLinearVelocity()
    base.server.update(self, dt)
end

function godex.server:damage(d, clientId)
    self.hp = self.hp - d
    if self.hp <= 0 and not self.destroyed then
        server.addXP(clientId, math.random(3, 5))
        local bagItems = {}
        local choices = {
            none=50, shield=15, apple=20,
            sword0=3, sword1=3, sword2=3, sword3=3, sword4=3
        }
        for _=1, 3 do
            choice = lume.weightedchoice(choices)
            if choice ~= 'none' then
                local itemData = {imageId=choice}
                if choice == 'sword0' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+10))
                elseif choice =='sword1' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+12))
                elseif choice =='sword2' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+14))
                elseif choice =='sword3' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+16))
                elseif choice =='sword4' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+18))
                end
                local itemId = items.server.newItem(itemData)
                table.insert(bagItems, itemId)
            end
        end
        local numItems = #bagItems
        if numItems ~= 0 then
            local type = lume.randomchoice{'lootBag', 'lootBag1', 'lootBagFuse'}
            lootBag.server:new{
                realm = serverRealm,
                x = self.x, y = self.y,
                items = bagItems,
                type = type,
                life = 30
            }:spawn()
        end
        self:destroy()
    end
end



function godex.client:new(o)
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

function godex.client:setState(state)
    for _, v in ipairs{'x', 'y', 'xv', 'yv', 'hpMax', 'hp'} do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end

function godex.client:lerpState(a, b, t)
    local state = {}
    for _, v in ipairs{'x', 'y', 'xv', 'yv'} do
        state[v] = lume.lerp(a[v], b[v], t)
    end
    for _, v in ipairs{'hpMax', 'hp'} do
        state[v] = b[v]
    end
    self:setState(state)
end

function godex.client:update(dt)
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

function godex.client:draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- body
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    local vx, vy = self.body:getPosition()
    love.graphics.translate(lume.round(vx), lume.round(vy))

    local img = gfx.enemies.godex.aura
    love.graphics.draw(img, 1, -19, 0, 1, 1,
    lume.round(img:getWidth()/2), lume.round(img:getHeight()/2))
    local bodyFrame = (time/3) % 1 < 0.1 and 1 or 2
    local img = gfx.enemies.godex['body' .. bodyFrame]
    love.graphics.draw(img, 0, 0, 0, 1, 1, 11, 30)
    local flameFrame = (math.floor(gameTime*12) % 5) + 1
    local quad = anims.enemies.godexFlame.quads[flameFrame]
    local _, _, w, h = quad:getViewport()
    love.graphics.draw(anims.enemies.godexFlame.sheet, quad,
        14, -16, 0, 1, 1, lume.round(w/2), h)

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
end



return godex
