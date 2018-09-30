
entities = {
    server = {
        defs = {},
        container = {}
    },
    client = {
        defs = {},
    }
}

local entityDefs = {
    require 'entityDefs.player',
    require 'entityDefs.slime'
}

for _, sc in pairs{'server', 'client'} do
    -- entities.server.defs.slime = slime.server
    for _, v in pairs(entityDefs) do
        entities[sc].defs[v.server.type] = v[sc]
    end
end

function entities.server.load()
    -- todo: load chunks
    for i=1, 8 do
        local x, y = (math.random()*2-1)*256, (math.random()*2-1)*256
        entities.server.defs.slime:new{x=x, y=y}:spawn()
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
    -- todo: load chunks, cull/uncull

    for etype, _ in pairs(entities.server.defs) do
        for _, v in pairs(entities.server.container[etype] or {}) do
            v:update(dt)
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
