
local base = require 'entityDefs._base'
local player = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    player[sc].newDefaults = function()
        local t = {
            id = lume.uuid(),
            name = 'Player',
            x = 0, y = 0,
            xv = 0, yv = 0,
            hpMax = 100, hp = 100,
            walkTimer = 0, swingTimer = 0,
            swinging = false, automaticSwing = true,
            direction = 1, spd = 6e2, xp = 0,
            stats = player[sc].newStats(),
            inventory = {id='inventory', items={}},
            inputState = {keyboard={}, mouse={x=0, y=0}}
        }
        if sc == 'server' then
            t.base = base.server
            t.realm = serverRealm
            t.items = items.server
        elseif sc == 'client' then
            t.base = base.client
            t.realm = clientRealm
            t.items = items.client
        end
        return t
    end

    player[sc].xp2level = function(x)
        return math.sqrt(x)/2
    end

    player[sc].newStats = function()
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

    player[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'dynamic')
        self.shapes = {
            love.physics.newCircleShape(6)
        }
        self.fixtures = {
            love.physics.newFixture(self.body, self.shapes[1], 1)
        }
        local fix = self.fixtures[1]
        fix:setUserData(self)
        fix:setCategory(1)
        if sc == 'client' then
            if self.isLocalPlayer then
                fix:setMask(1, 2)
            else
                fix:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
            end
        end
        self.body:setFixedRotation(true)
        self.body:setLinearDamping(10)
        return self.base.spawn(self)
    end

    player[sc].setInputState = function(self, state)
        for _, v in ipairs{'w', 'a', 's', 'd', 'lshift'} do
            self.inputState.keyboard[v] = state.keyboard[v]
        end
        for _, v in ipairs{'lmb', 'x', 'y'} do
            self.inputState.mouse[v] = state.mouse[v]
        end
    end

    player[sc].update = function(self, dt)
        local dx, dy = 0, 0
        dx = dx + (self.inputState.keyboard.d and 1 or 0)
        dx = dx + (self.inputState.keyboard.a and -1 or 0)
        dy = dy + (self.inputState.keyboard.w and -1 or 0)
        dy = dy + (self.inputState.keyboard.s and 1 or 0)
        dd = math.sqrt(dx^2 + dy^2)
        local spd = self.spd*(self.inputState.keyboard.lshift and 2.5 or 1)
        local tile = self.realm.world:getTile(self.x, self.y)
        if tile == 5 or tile == 6 then spd = spd * 1.5 end -- platform, path
        if tile == 4 then spd = spd / 2 end -- water
        local attackItem = self.items.getItem(self.inventory.items[2])
        if dd ~= 0 then
            self.body:applyForce(dx/dd*spd, dy/dd*spd)
        end

        local xv, yv = self.body:getLinearVelocity()
        local vd = math.sqrt(xv^2 + yv^2)
        self.walkTimer = self.walkTimer + vd*0.01*dt

        if self.swinging then
            self.swingTimer = self.swingTimer + dt
            if self.swingTimer > 5/12 then
                self.swinging = false
            end
        else
            if math.abs(vd) > 10 then
                if self.direction == 1 then
                    if xv < 0 then self.direction = -1 end
                else
                    if xv > 0 then self.direction = 1 end
                end
            end
            if self.automaticSwing and self.inputState.mouse.lmb
            and attackItem and isSword[attackItem.imageId] then
                self:swing()
            end
        end

        self.x, self.y = self.body:getPosition()
        self.xv, self.yv = self.body:getLinearVelocity()
        self.base.update(self, dt)
    end

    player[sc].destroy = function(self)
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

    player[sc].type = 'player'
    player[sc].static = false
end



function player.server:new(o)
    o = o or {}
    for k, v in pairs(self.newDefaults()) do
        if o[k] == nil then o[k] = v end
    end
    o.inventory.items[2] = items.server.newItem{imageId='sword0', atk=10}
    setmetatable(o, self)
    self.__index = self
    return o
end

function player.server:serialize()
    local t = {}
    for _, v in ipairs{
        'id', 'type', 'name',
        'x', 'y', 'xv', 'yv',
        'walkTimer', 'swingTimer', 'swinging', 'automaticSwing',
        'direction', 'spd', 'xp',
        'stats', 'inventory'
    } do
        t[v] = self[v]
    end
    return t
end

function player.server:setState(state)
    for _, v in ipairs{
        'x', 'y', 'xv', 'yv',
        'walkTimer', 'swingTimer', 'swinging',
        'direction'
    } do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end



function player.client:serialize()
    local t = {}
    for _, v in ipairs{
        'x', 'y', 'xv', 'yv',
        'walkTimer', 'swingTimer', 'swinging',
        'direction', 'inputState'
    } do
        t[v] = self[v]
    end
    return t
end

function player.client:setState(state)
    for _, v in ipairs{
        'x', 'y', 'xv', 'yv',
        'walkTimer', 'swingTimer', 'automaticSwing', 'swinging',
        'direction', 'spd', 'xp',
        'stats', 'inventory'
    } do
        self[v] = state[v]
    end
    if self.body and not self.body:isDestroyed() then
        self.body:setPosition(self.x, self.y)
        self.body:setLinearVelocity(self.xv, self.yv)
    end
end

function player.client:lerpState(a, b, t)
    local state = {}
    for _, v in ipairs{'x', 'y', 'xv', 'yv', 'walkTimer', 'swingTimer'} do
        state[v] = lume.lerp(a[v], b[v], t)
    end
    -- set instead of interpolate timers if b < a
    -- todo: interpolate flag
    for _, v in ipairs{'walkTimer', 'swingTimer'} do
        if b[v] < a[v] then state[v] = b[v] end
    end
    for _, v in ipairs{'automaticSwing', 'swinging',
    'direction', 'spd', 'xp', 'stats', 'inventory'} do
        state[v] = b[v]
    end
    self:setState(state)
end

function player.client:swing()
    local mx, my = self.inputState.mouse.x, self.inputState.mouse.y
    self.direction = mx < gsx/2 and -1 or 1
    self.swinging = true
    self.swingTimer = 0
    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local px, py = self.body:getPosition()
    local playerDamage = 5
    local attackItem = items.client.getItem(self.inventory.items[2])
    if attackItem and attackItem.atk then
        playerDamage = attackItem.atk
    end
    client.spawnProjectile{
        x = px, y = py - 14,
        angle = a,
        speed = 2e2,
        life = 3,
        pierce = 2,
        damage = playerDamage
    }
end

function player.client:damage(dmg)
    self.hp = self.hp - dmg
    if self.hp <= 0 then
        self.hp = self.hpMax
        local a = math.random()*2*math.pi
        local dist = math.random()*128
        self.x, self.y = math.cos(a)*dist, -math.sin(a)*dist
        self.body:setPosition(self.x, self.y)
    end
end

function player.client:mousepressed(x, y, btn)
    if not self.automaticSwing and not self.swinging then
        self:swing()
    end
end

function player.client:draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()
    love.graphics.push()

    -- offset if on platform or path
    local tile = clientRealm.world:getTile(self.x, self.y)
    if tile == 5 or tile == 6 then
        love.graphics.translate(0, -2)
    end

    local px, py = self.body:getPosition()
    local xv, yv = self.body:getLinearVelocity()
    local vd = math.sqrt(xv^2 + yv^2)

    -- shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    local walkFrameIdx = math.floor(self.walkTimer*12) % #anims.player.walk.body.quads + 1
    local shadowWidth = ({6, 5, 4, 5, 5})[walkFrameIdx]
    if vd < 10 then shadowWidth = 6 end
    love.graphics.ellipse('fill', lume.round(px), lume.round(py), shadowWidth, 2)

    -- player
    love.graphics.setCanvas{canvases.tempGame, stencil=true}
    love.graphics.setShader()
    love.graphics.clear()

    -- offset/clip feet if in water
    if tile == 4 then
        love.graphics.translate(0, 4)
        love.graphics.stencil(function()
            love.graphics.rectangle('fill', self.x - 50, self.y - 4, 100, 100)
        end, 'replace', 1)
        love.graphics.setStencilTest('equal', 0)
    end

    love.graphics.setColor(1, 1, 1)
    local attackItem = items.client.getItem(self.inventory.items[2])
    if self.swinging then
        local swingFrameIdx = math.floor(self.swingTimer*12) + 1
        swingFrameIdx = lume.clamp(swingFrameIdx, 1, 5)
        if vd < 10 then
            -- swinging and standing still
            local quad = anims.player.swing.body.quads[swingFrameIdx]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.swing.body.sheet, quad,
                lume.round(px), lume.round(py),
                0, self.direction, 1,
                23, h)
            if attackItem and isSword[attackItem.imageId] then
                local quad = anims.player.swords[attackItem.imageId].swing.quads[swingFrameIdx]
                local _, _, w, h = quad:getViewport()
                love.graphics.draw(anims.player.swords[attackItem.imageId].swing.sheet, quad,
                    lume.round(px), lume.round(py),
                    0, self.direction, 1,
                    23, h)
            end
        else
            -- swinging and walking
            -- lower body
            if xv > 10 and self.direction == -1
            or xv < -10 and self.direction == 1 then
                walkFrameIdx = math.floor(-self.walkTimer*12) % #anims.player.walk.body.quads + 1
            end
            local quad = anims.player.walkAndSwing.lowerBody.quads[walkFrameIdx]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.walkAndSwing.lowerBody.sheet, quad,
                lume.round(px), lume.round(py),
                0, self.direction, 1,
                23, h)
            -- upper body
            love.graphics.push()
            if swingFrameIdx == 4 then love.graphics.translate(0, 1) end
            if walkFrameIdx == 4 then love.graphics.translate(0, -1) end
            local quad = anims.player.walkAndSwing.upperBody.quads[swingFrameIdx]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.walkAndSwing.upperBody.sheet, quad,
                lume.round(px), lume.round(py),
                0, self.direction, 1,
                23, h)
            love.graphics.pop()
            -- sword
            if attackItem and isSword[attackItem.imageId] then
                local quad = anims.player.swords[attackItem.imageId].swing.quads[swingFrameIdx]
                local _, _, w, h = quad:getViewport()
                love.graphics.draw(anims.player.swords[attackItem.imageId].swing.sheet, quad,
                    lume.round(px), lume.round(py),
                    0, self.direction, 1,
                    23, h)
            end
        end
    else
        if vd < 10 then
            -- standing still
            local quad = anims.player.swing.body.quads[1]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.swing.body.sheet, quad,
                lume.round(px), lume.round(py),
                0, self.direction, 1,
                23, h)
            if attackItem and isSword[attackItem.imageId] then
                local quad = anims.player.swords[attackItem.imageId].swing.quads[1]
                local _, _, w, h = quad:getViewport()
                love.graphics.draw(anims.player.swords[attackItem.imageId].swing.sheet, quad,
                    lume.round(px), lume.round(py),
                    0, self.direction, 1,
                    23, h)
            end
        else
            -- walking
            local quad = anims.player.walk.body.quads[walkFrameIdx]
            local _, _, w, h = quad:getViewport()
            love.graphics.draw(anims.player.walk.body.sheet, quad,
                lume.round(px), lume.round(py),
                0, self.direction, 1,
                8, h)
            if attackItem and isSword[attackItem.imageId] then
                local quad = anims.player.swords[attackItem.imageId].walk.quads[walkFrameIdx]
                local _, _, w, h = quad:getViewport()
                love.graphics.draw(anims.player.swords[attackItem.imageId].walk.sheet, quad,
                    lume.round(px), lume.round(py),
                    0, self.direction, 1,
                    8, h)
            end
        end
    end

    love.graphics.setStencilTest()

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

    -- name
    local font = fonts.c17
    love.graphics.setFont(font)
    text.printSmall(self.name, lume.round(px) - font:getWidth(self.name)/4, lume.round(py) - 40)

    if drawDebug then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle('fill',
            lume.round(px), lume.round(py), self.shapes[1]:getRadius())
    end

    love.graphics.pop()
end



return player
