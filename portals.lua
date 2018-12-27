
portals = {
    server = {
        container = {}
    },
    client = {}
}

function portals.server.spawn(data)
    local defaults = {
        x = 0, y = 0,
        -- life defaults to nil (permanent)
    }
    for k, v in pairs(defaults) do
        if data[k] == nil then data[k] = v end
    end

    data.id = lume.uuid()
    data.spawnTime = gameTime

    portals.server.container[data.id] = data
    local state = {
        id = data.id,
        x = data.x, y = data.y,
        life = data.life
    }
    server.currentState.portals[data.id] = state
    server.added.portals[data.id] = state
end

function portals.server.destroy(id)
    portals.server.container[id] = nil
    server.currentState.portals[id] = nil
    server.removed.portals[id] = id
end

function portals.server.reset()
    for k, v in pairs(portals.server.container) do
        portals.server.destroy(k)
    end
end

function portals.server.update(dt)
    for k, v in pairs(portals.server.container) do
        if gameTime - v.spawnTime > v.life then
            portals.server.destroy(k)
        end
    end
end



function portals.client.keypressed(k, scancode, isrepeat)
    if scancode == 'e' and not isrepeat then
        -- todo: closest like lootBags
        local px, py = playerController.player.body:getPosition()
        for k, v in pairs(client.currentState.portals) do
            if (px-v.x)^2+(py-v.y)^2 < 24^2 then
                client.usePortal{id=v.id}
            end
        end
    end
end

function portals.client.draw()
    for _, v in pairs(client.currentState.portals) do
        scene.add{
            draw = function()
                love.graphics.setColor(0.2, 0.2, 0.8)
                local px, py = playerController.player.body:getPosition()
                if (px-v.x)^2+(py-v.y)^2 < 24^2 then
                    love.graphics.setColor(0.5, 0.5, 0.9)
                end
                local w, h = 16, 24
                love.graphics.rectangle('fill', lume.round(v.x - w/2), lume.round(v.y - h), w, h)
            end,
            y = v.y
        }
    end
end
