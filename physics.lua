
physics = {
    server = {},
    client = {}
}

love.physics.setMeter(16)

-- categories: 1=player, 2=projectile, 3=enemy, 4=obstacle

local defaults = {server={}, client={}}
for _, sc in ipairs{'server', 'client'} do
    physics[sc].newDefaults = function()
        return {
            postUpdateQueue = {}
        }
    end

    physics[sc].new = function(self, o)
        o = o or {}
        for k, v in pairs(self.newDefaults()) do
            if o[k] == nil then o[k] = v end
        end
        setmetatable(o, self)
        self.__index = self
        return o
    end

    physics[sc].update = function(self, dt)
        self.world:update(dt)
        for i, v in pairs(self.postUpdateQueue) do
            v()
            self.postUpdateQueue[i] = nil
        end
    end

    -- can't do stuff like destroying fixtures in callbacks - queue for update
    physics[sc].postUpdatePush = function(self, f)
        table.insert(self.postUpdateQueue, f)
    end

    physics[sc].draw = function(self)
        if sc == 'server' then
            love.graphics.setColor(1, 0, 0, 0.4)
        elseif sc == 'client' then
            love.graphics.setColor(0, 1, 0, 0.4)
        end
        for _, body in pairs(self.world:getBodies()) do
            for _, fixture in pairs(body:getFixtures()) do
                local shape = fixture:getShape()
                if shape:typeOf('CircleShape') then
                    local cx, cy = body:getWorldPoints(shape:getPoint())
                    love.graphics.circle('fill', cx, cy, shape:getRadius())
                elseif shape:typeOf('PolygonShape') then
                    love.graphics.polygon('fill', body:getWorldPoints(shape:getPoints()))
                else
                    love.graphics.line(body:getWorldPoints(shape:getPoints()))
                end
            end
        end
    end
end



function physics.server:load()
    self.beginContact = function(a, b, coll)
        for _, v in ipairs{{a, b}, {b, a}} do
            local fixa = v[1]
            local fixb = v[2]
            local uda = fixa:getUserData() or {}
            local udb = fixb:getUserData() or {}
            if uda.type == 'playerSwing' then
                if udb.enemy then
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
            elseif uda.type == 'playerSwingObstacleCollider' then
                -- check if first category is obstacle
                if fixb:getCategory() == 4 then
                    self:postUpdatePush(function()
                        local swing = projectiles.server.container[uda.data.id]
                        if swing then
                            projectiles.server.destroy(swing.id)
                        end
                    end)
                end
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



function physics.client:load()
    self.beginContact = function(a, b, coll)
        for _, v in ipairs{{a, b}, {b, a}} do
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
