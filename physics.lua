
physics = {
    server = {},
    client = {}
}

love.physics.setMeter(16)

local defaults = {server={}, client={}}
for _, sc in pairs{'server', 'client'} do
    defaults[sc].postUpdateQueue = function() return {} end
end



function physics.server:new(o)
    o = o or {}
    for k, v in pairs(defaults.server) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function physics.server:load()
    self.beginContact = function(a, b, coll)
        for _, v in pairs{{a, b}, {b, a}} do
            local fixa = v[1]
            local fixb = v[2]
            local uda = fixa:getUserData() or {}
            local udb = fixb:getUserData() or {}
            if uda.type == 'playerSwing' and udb.enemy then
                self:postUpdatePush(function()
                    local swing = projectiles.server.container[uda.id]
                    local enemy = udb
                    if swing and enemy and not enemy.hitBy[swing.id] then
                        enemy.hitBy[swing.id] = true
                        enemy:damage(swing.damage, swing.playerId)
                        swing.pierce = swing.pierce - 1
                        if swing.pierce <= 0 then
                            projectiles.server.destroy(swing.id)
                        end
                    end
                end)
            end
        end
    end
    self.endContact = function(a, b, coll) end
    self.preSolve = function(a, b, coll) end
    self.postSolve = function(a, b, coll, normalImpulse, tangentImpulse) end

    if self.world then self.world:destroy() end
    self.world = love.physics.newWorld(0, 0, true)
    self.world:setCallbacks(self.beginContact,
    self.endContact, self.preSolve, self.postSolve)
end

function physics.server:update(dt)
    self.world:update(dt)
    for i, v in pairs(self.postUpdateQueue) do
        v()
        self.postUpdateQueue[i] = nil
    end
end

-- can't do stuff like destroying fixtures in callbacks - queue for update
function physics.server:postUpdatePush(f)
    table.insert(self.postUpdateQueue, f)
end



function physics.client:new(o)
    o = o or {}
    for k, v in pairs(defaults.client) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function physics.client:load()
    self.beginContact = function(a, b, coll)
        for _, v in pairs{{a, b}, {b, a}} do
            local fixa = v[1]
            local fixb = v[2]
            local uda = fixa:getUserData() or {}
            local udb = fixb:getUserData() or {}
            if uda.type == 'slimeBall' and udb.id == playerController.player.id then
                self:postUpdatePush(function()
                    udb:damage(uda.damage)
                    slimeBalls.destroy(uda.id)
                end)
            end
        end
    end
    self.endContact = function(a, b, coll) end
    self.preSolve = function(a, b, coll) end
    self.postSolve = function(a, b, coll, normalImpulse, tangentImpulse) end

    if self.world then self.world:destroy() end
    self.world = love.physics.newWorld(0, 0, true)
    self.world:setCallbacks(self.beginContact,
        self.endContact, self.preSolve, self.postSolve)
end

function physics.client:update(dt)
    self.world:update(dt)
    for i, v in pairs(self.postUpdateQueue) do
        v()
        self.postUpdateQueue[i] = nil
    end
end

function physics.client:postUpdatePush(f)
    table.insert(self.postUpdateQueue, f)
end
