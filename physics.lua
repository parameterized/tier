
physics = {
    server = {
        postUpdateQueue = {}
    },
    client = {
        postUpdateQueue = {}
    }
}

love.physics.setMeter(16)

function physics.server.load()
    if physics.server.world then physics.server.world:destroy() end
    physics.server.world = love.physics.newWorld(0, 0, true)
    physics.server.world:setCallbacks(physics.server.beginContact,
    physics.server.endContact, physics.server.preSolve, physics.server.postSolve)
end

function physics.server.update(dt)
    physics.server.world:update(dt)
    for i, v in pairs(physics.server.postUpdateQueue) do
        v()
        physics.server.postUpdateQueue[i] = nil
    end
end

-- can't do stuff like destroying fixtures in callbacks - queue for update
function physics.server.postUpdatePush(f)
    table.insert(physics.server.postUpdateQueue, f)
end

function physics.server.beginContact(a, b, coll)
    for _, v in pairs{{a, b}, {b, a}} do
        local fixa = v[1]
        local fixb = v[2]
        local uda = fixa:getUserData() or {}
        local udb = fixb:getUserData() or {}
        if uda.type == 'playerSwing' and udb.enemy then
            physics.server.postUpdatePush(function()
                local swing = projectiles.server.container[uda.id]
                local enemy = udb
                if swing and enemy and not enemy.hitBy[swing.id] then
                    enemy.hitBy[swing.id] = true
                    enemy:damage(2, swing.playerId)
                    swing.pierce = swing.pierce - 1
                    if swing.pierce <= 0 then
                        projectiles.server.destroy(swing.id)
                    end
                end
            end)
        end
    end
end

function physics.server.endContact(a, b, coll)

end

function physics.server.preSolve(a, b, coll)

end

function physics.server.postSolve(a, b, coll, normalImpulse, tangentImpulse)

end



function physics.client.load()
    if physics.client.world then physics.client.world:destroy() end
    physics.client.world = love.physics.newWorld(0, 0, true)
    physics.client.world:setCallbacks(physics.client.beginContact,
        physics.client.endContact, physics.client.preSolve, physics.client.postSolve)
end

function physics.client.update(dt)
    physics.client.world:update(dt)
    for i, v in pairs(physics.client.postUpdateQueue) do
        v()
        physics.client.postUpdateQueue[i] = nil
    end
end

function physics.client.postUpdatePush(f)
    table.insert(physics.client.postUpdateQueue, f)
end

function physics.client.beginContact(a, b, coll)

end

function physics.client.endContact(a, b, coll)

end

function physics.client.preSolve(a, b, coll)

end

function physics.client.postSolve(a, b, coll, normalImpulse, tangentImpulse)

end
