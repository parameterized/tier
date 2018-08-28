
physics = {}

physics.postUpdateQueue = {}

love.physics.setMeter(16)

function physics.load()
    physics.world = love.physics.newWorld(0, 0, true)
    physics.world:setCallbacks(physics.beginContact,
        physics.endContact, physics.preSolve, physics.postSolve)
end

function physics.update(dt)
    physics.world:update(dt)
    for i, v in pairs(physics.postUpdateQueue) do
        v()
        physics.postUpdateQueue[i] = nil
    end
end

-- can't do stuff like destroying fixtures in callbacks - queue for update
function physics.postUpdatePush(f)
    table.insert(physics.postUpdateQueue, f)
end

function physics.beginContact(a, b, coll)
    for _, v in pairs({{a, b}, {b, a}}) do
        local fixa = v[1]
        local fixb = v[2]
        local uda = fixa:getUserData() or {}
        local udb = fixb:getUserData() or {}
        if uda.type == 'playerSwing' and udb.type == 'enemy' then
            physics.postUpdatePush(function()
                local swing = player.projectiles[uda.id]
                local enemy = enemies.container[udb.id]
                if swing and enemy and not enemy.hitBy[swing.id] then
                    enemy.hitBy[swing.id] = true
                    enemies.damage(enemy.id, 2)
                    swing.pierce = swing.pierce - 1
                    if swing.pierce <= 0 then
                        for _, fix in pairs(swing.fixtures) do
                            fix:destroy()
                        end
                        swing.body:destroy()
                        player.projectiles[swing.id] = nil
                    end
                end
            end)
        end
    end
end

function physics.endContact(a, b, coll)

end

function physics.preSolve(a, b, coll)

end

function physics.postSolve(a, b, coll, normalImpulse, tangentImpulse)

end
