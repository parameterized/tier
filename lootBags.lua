
lootBags = {
    server = {
        container = {}
    },
    client = {
        closest = {id=nil, dist=nil},
        heldItem = {bagId=nil, itemId=nil, offset={x=0, y=0}}
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
for i=1, 4 do
    for j=1, 2 do
        table.insert(lootBags.client.slots, {
            x = 7 + (i-1)*18,
            y = 22 + (j-1)*18,
            w = 15,
            h = 15
        })
    end
end

function lootBags.client.update(dt)
    local closest = {id=nil, dist=nil}
    local px, py = player.body:getPosition()
    for _, bag in pairs(client.currentState.lootBags) do
        local dist = math.sqrt((bag.x - px)^2 + (bag.y - py)^2)
        if not closest.dist or dist < closest.dist then
            closest.id = bag.id
            closest.dist = dist
        end
    end
    lootBags.client.closest = closest
end

function lootBags.client.mousepressed(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    mx, my = camera:screen2world(mx, my)
    local bagId = lootBags.client.closest.id
    if bagId and lootBags.client.closest.dist < 30 then
        local bag = client.currentState.lootBags[bagId]
        local img = gfx.ui.bag
        local bmx = mx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
        local bmy = my - (lume.round(bag.y) - img:getHeight() - 20)
        for _, slot in ipairs(lootBags.client.slots) do
            if bmx >= slot.x and bmx <= slot.x + slot.w
            and bmy >= slot.y and bmy <= slot.y + slot.h then
                local heldItem = lootBags.client.heldItem
                heldItem.bagId = bag.id
                -- item id
                heldItem.offset.x = slot.x - bmx
                heldItem.offset.y = slot.y - bmy
                uiMouseDown = true
                break
            end
        end
    end
end

function lootBags.client.mousereleased(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    mx, my = camera:screen2world(mx, my)
    local bagId = lootBags.client.closest.id
    local heldItem = lootBags.client.heldItem
    if bagId and lootBags.client.closest.dist < 30 then
        local bag = client.currentState.lootBags[bagId]
        local img = gfx.ui.bag
        local bmx = mx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
        local bmy = my - (lume.round(bag.y) - img:getHeight() - 20)
        for _, slot in ipairs(lootBags.client.slots) do
            if bmx >= slot.x and bmx <= slot.x + slot.w
            and bmy >= slot.y and bmy <= slot.y + slot.h then
                -- drop item in slot
                break
            end
        end
    end
    heldItem.bagId = nil
end

function lootBags.client.draw()
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    mx, my = camera:screen2world(mx, my)
    for _, bag in pairs(client.currentState.lootBags) do
        scene.add{
            draw = function()
                local a = 1
                if bag.life and client.serverTime - bag.spawnTime > bag.life - 3 then
                    local t = (client.serverTime - bag.spawnTime - bag.life + 3)/3
                    a = math.cos(t*5*math.pi)/4 + 1/4 + (1-t)/2
                end
                love.graphics.setColor(1, 1, 1, a)
                love.graphics.push()
                love.graphics.translate(lume.round(bag.x), lume.round(bag.y))
                local img = gfx.items[bag.type]
                love.graphics.draw(img, 0, 0, 0, 1, 1, lume.round(img:getWidth()/2), img:getHeight())
                if bag.id == lootBags.client.closest.id and lootBags.client.closest.dist < 30 then
                    local img = gfx.ui.bag
                    love.graphics.push()
                    love.graphics.translate(-lume.round(img:getWidth()/2), -img:getHeight() - 20)
                    love.graphics.draw(img, 0, 0)
                    local bmx = mx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
                    local bmy = my - (lume.round(bag.y) - img:getHeight() - 20)
                    for _, slot in ipairs(lootBags.client.slots) do
                        if bmx >= slot.x and bmx <= slot.x + slot.w
                        and bmy >= slot.y and bmy <= slot.y + slot.h then
                            love.graphics.setColor(1, 1, 1, 0.8)
                        else
                            love.graphics.setColor(1, 1, 1, 0.2)
                        end
                        love.graphics.rectangle('fill', slot.x, slot.y, slot.w, slot.h)
                    end
                    love.graphics.setColor(1, 0, 0, 0.4)
                    love.graphics.rectangle('fill', bmx, bmy, 2, 2)
                    love.graphics.pop()
                end
                love.graphics.pop()
            end,
            y = bag.y
        }
    end
end
