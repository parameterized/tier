
lootBags = {
    server = {
        container = {}
    },
    client = {}
}

function lootBags.server.spawn(data)
    local defaults = {
        x = 0, y = 0,
        type = 'lootBag',
        items = {} -- should be table of strings (serializable)
        -- life defaults to nil (permanent)
    }
    for k, v in pairs(defaults) do
        if data[k] == nil then data[k] = v end
    end

    data.id = uuid()
    data.spawnTime = gameTime

    lootBags.server.container[data.id] = data
    local state = {
        id = data.id,
        x = data.x, y = data.y,
        type = data.type,
        items = data.items,
        life = data.life,
        spawnTime = data.spawnTime
    }
    server.currentState.lootBags[data.id] = state
    server.added.lootBags[data.id] = state
end

function lootBags.server.destroy(id)
    lootBags.server.container[id] = nil
    server.currentState.lootBags[id] = nil
    server.removed.lootBags[id] = id
end

function lootBags.server.reset()
    for k, v in pairs(lootBags.server.container) do
        lootBags.server.destroy(k)
    end
end

function lootBags.server.update(dt)
    for k, v in pairs(lootBags.server.container) do
        if v.life and gameTime - v.spawnTime > v.life then
            lootBags.server.destroy(k)
        end
    end
end



function lootBags.client.draw()
    for _, v in pairs(client.currentState.lootBags) do
        local a = 1
        if v.life and client.serverTime - v.spawnTime > v.life - 3 then
            local t = (client.serverTime - v.spawnTime - v.life + 3)/3
            a = math.cos(t*5*math.pi)/4 + 1/4 + (1-t)/2
        end
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.push()
        love.graphics.translate(math.floor(v.x), math.floor(v.y))
        local img = gfx.items[v.type]
        love.graphics.draw(img, 0, 0, 0, 1, 1, img:getWidth()/2, img:getHeight())
        love.graphics.pop()
    end
end
