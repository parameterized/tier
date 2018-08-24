
physics = {}

love.physics.setMeter(16)

function physics.load()
    physics.world = love.physics.newWorld(0, 0, true)
end

function physics.update(dt)
    physics.world:update(dt)
end
