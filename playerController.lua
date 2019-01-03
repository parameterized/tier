
playerController = {
    interactRange = 30,
    closestBag = {id=nil, dist=nil, open=false},
    hoveredItem = nil,
    heldItem = {bagId=nil, slotId=nil, offset={x=0, y=0}}
}

function playerController.load()
    playerController.player = entities.client.defs.player:new{isLocalPlayer=true}:spawn()
    playerController.serverId = nil
end

function playerController.update(dt)
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)

    -- update player input
    local inputState = {keyboard={}, mouse={}}
    for _, key in ipairs{'w', 'a', 's', 'd', 'lshift'} do
        inputState.keyboard[key] = love.keyboard.isScancodeDown(key) and not chat.active
    end
    inputState.mouse.lmb = love.mouse.isDown(1) and not uiMouseDown
    inputState.mouse.x = mx
    inputState.mouse.y = my

    local p = playerController.player
    p:setInputState(inputState)

    -- update camera
    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local d = math.min(math.sqrt(dx^2 + dy^2), gsy/2)
    camera.x = lume.round(p.body:getX()) + lume.round(math.cos(a)*d/6)
    camera.y = lume.round(p.body:getY() - 14) + lume.round(-math.sin(a)*d/6)

    -- update closest lootBag, heldItem
    local closestBag = playerController.closestBag
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
    if not closestBag.id or closestBag.id ~= lastId or closestBag.dist > playerController.interactRange then
        closestBag.open = false
    end
    local heldItem = playerController.heldItem
    if heldItem.bagId ~= 'inventory' and (not closestBag.id
    or closestBag.id ~= heldItem.bagId or closestBag.dist > playerController.interactRange) then
        heldItem.bagId = nil
        heldItem.slotId = nil
    end
    playerController.hoveredItem = nil
end

function playerController.mousepressed(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)

    -- lootBags
    local closestBag = playerController.closestBag
    if closestBag.id and closestBag.open then
        local bag = client.currentState.lootBags[closestBag.id]
        local img = gfx.ui.bag
        local bmx = wmx - (lume.round(bag.x) - lume.round(img:getWidth()/2))
        local bmy = wmy - (lume.round(bag.y) - img:getHeight() - 20)
        for slotId, slot in ipairs(lootBagSlots) do
            if bmx >= slot.x and bmx <= slot.x + slot.w
            and bmy >= slot.y and bmy <= slot.y + slot.h then
                uiMouseDown = true
                if bag.items[slotId] then
                    if btn == 1 then
                        local heldItem = playerController.heldItem
                        heldItem.bagId = bag.id
                        heldItem.slotId = slotId
                        heldItem.offset.x = slot.x - bmx
                        heldItem.offset.y = slot.y - bmy
                    elseif btn == 2 then
                        local p = playerController.player
                        for invSlotId, _ in ipairs(hud.inventorySlots) do
                            if p.inventory.items[invSlotId] == nil then
                                client.moveItem{
                                    from = {
                                        bagId = bag.id,
                                        slotId = slotId
                                    },
                                    to = {
                                        bagId = p.inventory.id,
                                        slotId = invSlotId
                                    }
                                }
                                break
                            end
                        end
                    end
                end
                break
            end
        end
    end

    -- player attack
    if not uiMouseDown then
        playerController.player:mousepressed(x, y, btn)
    end
end

function playerController.mousereleased(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    wmx, wmy = camera:screen2world(mx, my)

    -- lootBags
    local closestBag = playerController.closestBag
    local heldItem = playerController.heldItem
    if closestBag.id and closestBag.open and heldItem.bagId then
        local bagFrom = client.currentState.lootBags[heldItem.bagId]
        if heldItem.bagId == 'inventory' then
            bagFrom = playerController.player.inventory
        end
        local bagTo = client.currentState.lootBags[closestBag.id]
        local img = gfx.ui.bag
        local bmx = wmx - (lume.round(bagTo.x) - lume.round(img:getWidth()/2))
        local bmy = wmy - (lume.round(bagTo.y) - img:getHeight() - 20)
        for slotId, slot in ipairs(lootBagSlots) do
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

function playerController.keypressed(k, scancode, isrepeat)
    if scancode == 'e' and not isrepeat then
        local closestBag = playerController.closestBag
        if closestBag.id and closestBag.dist < playerController.interactRange then
            closestBag.open = not closestBag.open
        end
    end
end
