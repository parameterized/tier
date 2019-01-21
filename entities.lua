
entities = {
    server = {
        defs = {},
        container = {},
        activeChunks = {}
    },
    client = {
        defs = {},
    }
}

-- 306px visible on screen, 465 visible on map
entities.activeRadius = 500
entities.chunkSize = 8

local entityDefs = {}
for _, v in ipairs{'player', 'slime', 'tree', 'wall', 'sorcerer', 'spoder', 'stingy', 'zombie', 'ant',
'newMonster1', 'newMonster2', 'mudskipper', 'mudskipperEvolved', 'godex'} do
    table.insert(entityDefs, require('entityDefs.' .. v))
end

for _, sc in ipairs{'server', 'client'} do
    -- entities.server.defs.slime = slime.server
    for _, v in pairs(entityDefs) do
        entities[sc].defs[v.server.type] = v[sc]
    end
end

function entities.server.reset()
    for etype, _ in pairs(entities.server.defs) do
        for _, v in pairs(entities.server.container[etype] or {}) do
            v:destroy()
        end
    end
end

function entities.server.update(dt)
    -- spawn if new chunks active
    local newActiveChunks = {}
    for _, v in pairs(server.currentState.players) do
        local cx1 = math.floor((v.x - entities.activeRadius)/15/entities.chunkSize)
        local cx2 = math.floor((v.x + entities.activeRadius)/15/entities.chunkSize)
        local cy1 = math.floor((v.y - entities.activeRadius)/15/entities.chunkSize)
        local cy2 = math.floor((v.y + entities.activeRadius)/15/entities.chunkSize)
        for cx=cx1, cx2 do
            for cy=cy1, cy2 do
                if newActiveChunks[cx] == nil then newActiveChunks[cx] = {} end
                newActiveChunks[cx][cy] = true
                if not entities.server.activeChunks[cx] or not entities.server.activeChunks[cx][cy] then
                    -- spawn enemies
                    local choices = {none=80, slime=2, sorcerer=2, spoder=2, stingy=2, zombie=2, ant=2,
                    newMonster1=2, newMonster2=2, mudskipper=1, mudskipperEvolved=1, godex=2}
                    for _=1, 3 do
                        choice = lume.weightedchoice(choices)
                        if choice ~= 'none' then
                            local x = (cx*entities.chunkSize + math.random()*entities.chunkSize)*15
                            local y = (cy*entities.chunkSize + math.random()*entities.chunkSize)*15
                            -- if not in spawn area
                            if not (x^2 + y^2 < 192^2) then
                                entities.server.defs[choice]:new{x=x, y=y}:spawn()
                            end
                        end
                    end
                    -- spawn trees
                    if math.random() < 0.5 then
                        local x = (cx*entities.chunkSize + math.random()*entities.chunkSize)*15
                        local y = (cy*entities.chunkSize + math.random()*entities.chunkSize)*15
                        -- if on grass
                        if serverRealm.world:getTile(x, y) == 1 then
                            entities.server.defs.tree:new{x=x, y=y}:spawn()
                        end
                    end
                    -- spawn walls
                    for i=1, entities.chunkSize do
                        for j=1, entities.chunkSize do
                            local x = (cx*entities.chunkSize + (i-1))*15
                            local y = (cy*entities.chunkSize + (j-1))*15
                            if serverRealm.world:getTile(x, y) == 8 then
                                entities.server.defs.wall:new{x=x, y=y}:spawn()
                            end
                        end
                    end
                end
            end
        end
    end
    entities.server.activeChunks = newActiveChunks

    -- update, destroy if not in active chunk
    for etype, _ in pairs(entities.server.defs) do
        for _, v in pairs(entities.server.container[etype] or {}) do
            v:update(dt)
            local cx = math.floor(v.x/15/entities.chunkSize)
            local cy = math.floor(v.y/15/entities.chunkSize)
            if not entities.server.activeChunks[cx] or not entities.server.activeChunks[cx][cy] then
                v:destroy()
            end
        end
    end
end



function entities.client.reset()
    for _, v in pairs(client.currentState.entities) do
        v:destroy()
    end
end

function entities.client.update(dt)
    -- todo: local cull
    for _, v in pairs(client.currentState.entities) do
        v:update(dt)
    end
end

function entities.client.draw()
    for _, v in pairs(client.currentState.entities) do
        if not v.destroyed and v.draw and v.id ~= playerController.serverId then
            scene.add{
                draw = function()
                    v:draw()
                end,
                y = v.y
            }
        end
    end
end
