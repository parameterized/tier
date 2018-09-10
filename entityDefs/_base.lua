
local base = {
    server = {},
    client = {}
}

for _, sc in pairs{'server', 'client'} do
    -- entities.server.defs[type]
    base[sc].type = 'base'
    base[sc].static = true
end

function base.server:new(o)
    o = o or {}
    local defaults = {
        id = uuid(),
        x = 0, y = 0
    }
    for k, v in pairs(defaults) do
        if o[k] == nil then o[k] = v end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function base.server:spawn()
    self.destroyed = false
    --[[
    local container = self.static and entities.server.static.container
        or entities.server.dynamic.container
    ]]
    local container = entities.server.container
    local type = self.type
    local id = self.id
    container[type] = container[type] or {}
    container[type][id] = self
    --self:freeze()
    server.currentState.entities[self.id] = self:serialize()
    server.added.entities[self.id] = self:serialize()
    return self
end

function base.server:serialize()
    return {
        id = self.id, type = self.type,
        x = self.x, y = self.y
    }
end

function base.server:update(dt)
    -- update self.x, self.y etc here if controlled by physics
    server.currentState.entities[self.id] = self:serialize()
end

function base.server:destroy()
    self.destroyed = true
    --[[
    local container = self.static and entities.server.static.container
        or entities.server.dynamic.container
    ]]
    local container = entities.server.container
    container[self.type][self.id] = nil
    server.currentState.entities[self.id] = nil
    server.removed.entities[self.id] = self.id
end

--[[
function base.server:freeze()
    self.frozen = true
end

function base.server:unfreeze()
    self.frozen = false
end

function base.server:cull()
    self:destroy()
    self.culled = true
    local container = self.static and entities.server.static.culledContainer
        or entities.server.dynamic.culledContainer
    local cs = entities.chunkSize
    local chunk = math.floor(self.x/cs) .. ',' .. math.floor(self.y/cs)
    self.culledChunk = chunk
    local type = self.type
    local id = self.id
    container[chunk] = container[chunk] or {}
    container[chunk][type] = container[chunk][type] or {}
    container[chunk][type][id] = self
end

function base.server:uncull()
    local container = self.static and entities.server.static.culledContainer
    or entities.server.dynamic.culledContainer
    container[self.culledChunk][self.type][self.id] = nil
    self.culled = false
    self.culledChunk = nil
    self:spawn()
end
]]



function base.client:new(o)
    o = o or {}
    local defaults = {
        id = uuid(),
        x = 0, y = 0
    }
    for k, v in pairs(defaults) do
        if o[k] == nil then o[k] = v end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function base.client:spawn()
    self.destroyed = false
    return self
end

function base.client:setState(state)
    for _, v in pairs{'x', 'y'} do
        self[v] = state[v]
    end
end

function base.client:lerpState(a, b, t)
    for _, v in pairs{'x', 'y'} do
        self[v] = lerp(a[v], b[v], t)
    end
end

function base.client:update(dt)
    -- update self.x, self.y etc here if controlled by physics
end

function base.client:drawBody()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.circle('fill', v.x, v.y, 10)
end

function base.client:destroy()
    self.destroyed = true
end



return base
