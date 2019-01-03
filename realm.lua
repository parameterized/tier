
realm = {
    server = {},
    client = {}
}

local defaults = {server={}, client={}}
for _, sc in ipairs{'server', 'client'} do
    defaults[sc].id = function() return lume.uuid() end
    defaults[sc].name = function() return 'realm' end
    for _, v in ipairs{'entities', 'projectiles', 'slimeBalls', 'lootBags', 'portals'} do
        defaults[sc][v] = function() return {} end
    end
    for _, v in ipairs{{'physics', physics}, {'world', world}} do
        defaults[sc][v[1]] = function() return v[2][sc]:new() end
    end
end



function realm.server:new(o)
    o = o or {}
    for k, v in pairs(defaults.server) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function realm.server:load()
    self.physics:load()
end

function realm.server:update(dt)
    self.physics:update(dt)
    for _, bag in pairs(self.lootBags) do
        if bag.life and gameTime - bag.spawnTime > bag.life then
            bag:destroy()
        end
    end
end

function realm.server:destroy()
    self.world:destroy()
    for _, v in pairs(self.lootBags) do
        v:destroy()
    end
end



function realm.client:new(o)
    o = o or {}
    for k, v in pairs(defaults.client) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function realm.client:load()
    self.physics:load()
end

function realm.client:update(dt)
    self.physics:update(dt)
    self.world:update(dt)
end

function realm.client:destroy()
    self.world:destroy()
    for _, v in pairs(self.lootBags) do
        v:destroy()
    end
end

function realm.client:draw()
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)

    self.world:draw()

    for _, bag in pairs(self.lootBags) do
        scene.add{
            draw = function()
                local tint = 1
                local outlineColor = {0, 0, 0, 1}
                if bag.life and client.serverTime - bag.spawnTime > bag.life - 3 then
                    local t = (client.serverTime - bag.spawnTime - bag.life + 3)/3
                    tint = math.cos(t*5*math.pi)/4 + 1/4 + (1-t)/2
                    tint = tint/2 + 1/2
                    outlineColor = {0.8, 0, 0, 1}
                end
                local closestBag = playerController.closestBag
                if bag.id == closestBag.id and closestBag.dist < playerController.interactRange then
                    outlineColor = {0.8, 0.8, 0.8, 1}
                end
                love.graphics.setColor(tint, tint, tint)
                love.graphics.push()
                love.graphics.translate(lume.round(bag.x), lume.round(bag.y))
                local img = gfx.items[bag.type]
                local _shader = love.graphics.getShader()
                love.graphics.setShader(shaders.outline)
                shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
                shaders.outline:send('outlineColor', outlineColor)
                love.graphics.draw(img, 0, 0, 0, 1, 1, lume.round(img:getWidth()/2), img:getHeight())
                love.graphics.setShader(_shader)
                if bag.id == closestBag.id and closestBag.open then
                    local img = gfx.ui.bag
                    love.graphics.push()
                    love.graphics.translate(-lume.round(img:getWidth()/2), -img:getHeight() - 20)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.draw(img, 0, 0)
                    local bmx = wmx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
                    local bmy = wmy - (lume.round(bag.y) - img:getHeight() - 20)
                    for slotId, slot in ipairs(lootBagSlots) do
                        local item = items.client.getItem(bag.items[slotId])
                        if bmx >= slot.x and bmx <= slot.x + slot.w
                        and bmy >= slot.y and bmy <= slot.y + slot.h then
                            if item then
                                cursor.cursor = cursor.hand
                                playerController.hoveredItem = item
                            end
                            love.graphics.setColor(1, 1, 1, 0.4)
                            love.graphics.rectangle('fill', slot.x, slot.y, slot.w, slot.h)
                        end
                        local heldItem = playerController.heldItem
                        if not (heldItem.bagId == bag.id and heldItem.slotId == slotId) then
                            if item then
                                love.graphics.setColor(1, 1, 1)
                                love.graphics.draw(gfx.items[item.imageId], slot.x, slot.y)
                            end
                        end
                    end
                    love.graphics.pop()
                end
                love.graphics.pop()
            end,
            y = bag.y
        }
    end
end
