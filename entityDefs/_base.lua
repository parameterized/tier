
local base = {
    server = {},
    client = {}
}

for _, sc in ipairs{'server', 'client'} do
    base[sc].newDefaults = function()
        return {
            id = lume.uuid(),
            x = 0, y = 0
        }
    end

    base[sc].new = function(self, o)
        o = o or {}
        for k, v in pairs(self.newDefaults()) do
            if o[k] == nil then o[k] = v end
        end
        setmetatable(o, self)
        self.__index = self
        return o
    end

    -- entities.server.defs[type]
    base[sc].type = 'base'
    base[sc].static = true
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
    server.currentState.entities[self.id] = self:serialize()
    server.added.entities[self.id] = self:serialize()
    return self
end

function base.server:serialize()
    local t = {}
    for _, v in ipairs{'id', 'type', 'x', 'y'} do
        t[v] = self[v]
    end
    return t
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



function base.client:spawn()
    self.destroyed = false
    client.currentState.entities[self.id] = self
    return self
end

function base.client:setState(state)
    for _, v in ipairs{'x', 'y'} do
        self[v] = state[v]
    end
end

function base.client:lerpState(a, b, t)
    for _, v in ipairs{'x', 'y'} do
        self[v] = lume.lerp(a[v], b[v], t)
    end
end

function base.client:update(dt)
    -- update self.x, self.y etc here if controlled by physics
end

function base.client:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.circle('fill', v.x, v.y, 5)
end

function base.client:destroy()
    self.destroyed = true
    client.currentState.entities[self.id] = nil
end



return base
