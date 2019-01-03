
lootBag = {
    server = {},
    client = {}
}

local defaults = {server={}, client={}}
for _, sc in ipairs{'server', 'client'} do
    for k, v in pairs{x=0, y=0, type='lootBag'} do
        defaults[sc][k] = function() return v end
    end
    defaults[sc].id = function() return lume.uuid() end
    defaults[sc].items = function() return {} end
end
defaults.server.realm = function() return serverRealm end
defaults.client.realm = function() return clientRealm end

lootBagSlots = {}
for j=1, 2 do
    for i=1, 4 do
        table.insert(lootBagSlots, {
            x = 7 + (i-1)*18,
            y = 22 + (j-1)*18,
            w = 15,
            h = 15
        })
    end
end



function lootBag.server:new(o)
    o = o or {}
    for k, v in pairs(defaults.server) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function lootBag.server:spawn()
    self.spawnTime = gameTime

    self.realm.lootBags[self.id] = self
    server.added.lootBags[self.id] = self:serialize()
    return self
end

function lootBag.server:serialize()
    -- todo: realm id
    return {
        id = self.id,
        x = self.x, y = self.y,
        type = self.type,
        items = self.items,
        life = self.life,
        spawnTime = self.spawnTime
    }
end

function lootBag.server:destroy()
    self.realm.lootBags[self.id] = nil
    server.currentState.lootBags[self.id] = nil
    server.removed.lootBags[self.id] = self.id
end



function lootBag.client:new(o)
    o = o or {}
    for k, v in pairs(defaults.client) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function lootBag.client:spawn()
    self.realm.lootBags[self.id] = self
    client.currentState.lootBags[self.id] = self
    return self
end

function lootBag.client:destroy()
    self.realm.lootBags[self.id] = nil
    client.currentState.lootBags[self.id] = nil
end
