
lootBags = {
    server = {
        container = {}
    },
    client = {
        openRange = 30,
        closest = {id=nil, dist=nil, open=false},
        heldItem = {bagId=nil, slotId=nil, offset={x=0, y=0}}
    }
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

    data.id = lume.uuid()
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
    for k, bag in pairs(lootBags.server.container) do
        if bag.life and gameTime - bag.spawnTime > bag.life then
            lootBags.server.destroy(k)
        end
    end
end



lootBags.client.slots = {}
for j=1, 2 do
    for i=1, 4 do
        table.insert(lootBags.client.slots, {
            x = 7 + (i-1)*18,
            y = 22 + (j-1)*18,
            w = 15,
            h = 15
        })
    end
end

function lootBags.client.update(dt)
    local closestBag = lootBags.client.closest
    local px, py = playerController.player.body:getPosition()
    local lastId = closestBag.id
    closestBag.id = nil
    closestBag.dist = nil
    for _, bag in pairs(client.currentState.lootBags) do
        local dist = math.sqrt((bag.x - px)^2 + (bag.y - py)^2)
        if not closestBag.dist or dist < closestBag.dist then
            closestBag.id = bag.id
            closestBag.dist = dist
        end
    end
    -- todo: open bag should be able to not be closest
    if not closestBag.id or closestBag.id ~= lastId or closestBag.dist > lootBags.client.openRange then
        closestBag.open = false
    end
    local heldItem = lootBags.client.heldItem
    if heldItem.bagId ~= 'inventory' and (not closestBag.id
    or closestBag.id ~= heldItem.bagId or closestBag.dist > lootBags.client.openRange) then
        heldItem.bagId = nil
        heldItem.slotId = nil
    end
end

function lootBags.client.mousepressed(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)
    local closestBag = lootBags.client.closest
    if closestBag.id and closestBag.open then
        local bag = client.currentState.lootBags[closestBag.id]
        local img = gfx.ui.bag
        local bmx = wmx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
        local bmy = wmy - (lume.round(bag.y) - img:getHeight() - 20)
        for slotId, slot in ipairs(lootBags.client.slots) do
            if bmx >= slot.x and bmx <= slot.x + slot.w
            and bmy >= slot.y and bmy <= slot.y + slot.h then
                uiMouseDown = true
                if bag.items[slotId] then
                    local heldItem = lootBags.client.heldItem
                    heldItem.bagId = bag.id
                    heldItem.slotId = slotId
                    heldItem.offset.x = slot.x - bmx
                    heldItem.offset.y = slot.y - bmy
                end
                break
            end
        end
    end
end

function lootBags.client.mousereleased(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)
    local closestBag = lootBags.client.closest
    local heldItem = lootBags.client.heldItem
    if closestBag.id and closestBag.open and heldItem.bagId then
        local bagFrom = client.currentState.lootBags[heldItem.bagId]
        if heldItem.bagId == 'inventory' then
            bagFrom = playerController.player.inventory
        end
        local bagTo = client.currentState.lootBags[closestBag.id]
        local img = gfx.ui.bag
        local bmx = wmx - (lume.round(bagTo.x) - lume.round(img:getWidth()/2))
        local bmy = wmy - (lume.round(bagTo.y) - img:getHeight() - 20)
        for slotId, slot in ipairs(lootBags.client.slots) do
            if bmx >= slot.x and bmx <= slot.x + slot.w
            and bmy >= slot.y and bmy <= slot.y + slot.h then
                client.moveItem{
                    from = {
                        bagId = bagFrom.id,
                        slotId = heldItem.slotId
                    },
                    to = {
                        bagId = bagTo.id,
                        slotId = slotId
                    }
                }
                -- move clientside before response (will be corrected/affirmed)
                local temp = bagTo.items[slotId]
                bagTo.items[slotId] = bagFrom.items[heldItem.slotId]
                bagFrom.items[heldItem.slotId] = temp
                break
            end
        end
    end
end

function lootBags.client.keypressed(k, scancode, isrepeat)
    if scancode == 'e' and not isrepeat then
        local closestBag = lootBags.client.closest
        if closestBag.id and closestBag.dist < lootBags.client.openRange then
            closestBag.open = not closestBag.open
        end
    end
end

function lootBags.client.draw()
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)
    for _, bag in pairs(client.currentState.lootBags) do
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
                local closestBag = lootBags.client.closest
                if bag.id == closestBag.id and closestBag.dist < lootBags.client.openRange then
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
                    for slotId, slot in ipairs(lootBags.client.slots) do
                        if bmx >= slot.x and bmx <= slot.x + slot.w
                        and bmy >= slot.y and bmy <= slot.y + slot.h then
                            love.graphics.setColor(1, 1, 1, 0.4)
                            love.graphics.rectangle('fill', slot.x, slot.y, slot.w, slot.h)
                        end
                        local heldItem = lootBags.client.heldItem
                        if not (heldItem.bagId == bag.id and heldItem.slotId == slotId) then
                            local item = bag.items[slotId]
                            if item then
                                love.graphics.setColor(1, 1, 1)
                                love.graphics.draw(gfx.items[item], slot.x, slot.y)
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
