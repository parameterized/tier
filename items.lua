
items = {
    server = {
        container = {}
    },
    client = {
        container = {},
        requested = {}
    }
}

function items.server.newItem(data)
    if not data.id then
        data.id = lume.uuid()
    end
    if not data.imageId then
        data.imageId = 'apple'
    end
    if not data.type then
        data.type = data.imageId
        if isSword[data.imageId] then
            data.type = 'sword'
        end
        if data.imageId == 'armor0Helmet' or data.imageId == 'armor1Helmet' then
            data.type = 'helmet'
        end
        if data.imageId == 'armor0Chest' or data.imageId == 'armor1Chest' then
            data.type = 'chest'
        end
        if data.imageId == 'armor0Pants' or data.imageId == 'armor1Pants' then
            data.type = 'pants'
        end
    end
    items.server.container[data.id] = data
    return data.id
end

function items.server.reset()
    items.server.container = {}
end

function items.server.getItem(id)
    if id == nil then return nil end
    return items.server.container[id]
end



function items.client.reset()
    items.client.container = {}
    items.client.requested = {}
end

function items.client.getItem(id)
    if id == nil then return nil end
    local item = items.client.container[id]
    if item then
        return item
    else
        if not items.client.requested[id] then
            client.nutClient:sendRPC('getItem', bitser.dumps{id=id})
            items.client.requested[id] = true
        end
        return nil
    end
end

-- todo: refactor

function items.client.mousepressed(x, y, btn, isTouch, presses)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    local wmx, wmy = camera:screen2world(mx, my)

    -- hud
    local bag = playerController.player.inventory
    local panel = hud.inventoryPanel
    local pmx = mx - lume.round(panel.x)
    local pmy = my - lume.round(panel.y)
    for slotId, slot in ipairs(hud.inventorySlots) do
        if pmx >= slot.x and pmx <= slot.x + slot.w
        and pmy >= slot.y and pmy <= slot.y + slot.h and panel.open then
            uiMouseDown = true
            if bag.items[slotId] then
                -- use item
                if btn == 1 and (love.keyboard.isScancodeDown('lshift') or presses > 1) then
                    client.useItem{
                        bagId = bag.id,
                        slotId = slotId
                    }
                end
                -- move items
                if btn == 1 then
                    local heldItem = playerController.heldItem
                    heldItem.itemId = bag.items[slotId]
                    heldItem.bagId = bag.id
                    heldItem.slotId = slotId
                    heldItem.offset.x = slot.x - pmx
                    heldItem.offset.y = slot.y - pmy
                elseif btn == 2 then
                    local closestBag = playerController.closestBag
                    local cqb = playerController.closestQuestBlock
                    if closestBag.id and closestBag.open then
                        local bagTo = client.currentState.lootBags[closestBag.id]
                        for bagSlotId, _ in ipairs(lootBagSlots) do
                            if bagTo.items[bagSlotId] == nil then
                                client.moveItem{
                                    from = {
                                        bagId = bag.id,
                                        slotId = slotId
                                    },
                                    to = {
                                        bagId = bagTo.id,
                                        slotId = bagSlotId
                                    }
                                }
                                break
                            end
                        end
                    elseif cqb.id and cqb.open then
                        local qb = client.currentState.entities[cqb.id]
                        if qb then
                            local item = items.client.getItem(bag.items[slotId])
                            if not item then break end
                            for questSlotId, questItemId in pairs(quests.current.cost) do
                                local questItem = items.client.getItem(questItemId)
                                if not questItem then break end
                                if quests.current.heldItems[questSlotId] == nil
                                and item.imageId == questItem.imageId then
                                    quests.current.heldItems[questSlotId] = bag.items[slotId]
                                    client.setInventorySlot{
                                        slotId = slotId,
                                        itemId = nil
                                    }
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

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
                        heldItem.itemId = bag.items[slotId]
                        heldItem.bagId = bag.id
                        heldItem.slotId = slotId
                        heldItem.offset.x = slot.x - bmx
                        heldItem.offset.y = slot.y - bmy
                    elseif btn == 2 then
                        local p = playerController.player
                        local item = items.client.getItem(bag.items[slotId])
                        if not item then break end
                        for invSlotId, _ in ipairs(hud.inventorySlots) do
                            local slotType = slot2type[invSlotId]
                            if p.inventory.items[invSlotId] == nil
                            and (slotType == nil or slotType == item.type) then
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

    -- quest
    local cqb = playerController.closestQuestBlock
    if cqb.id and cqb.open then
        local qb = client.currentState.entities[cqb.id]
        if qb then
            local img = gfx.ui.quest
            local bmx = wmx - (lume.round(qb.x + 8) - lume.round(img:getWidth()/2))
            local bmy = wmy - (lume.round(qb.y + 8) - img:getHeight() - 20)
            for slotId, slot in ipairs(questBlockSlots) do
                local exists = true
                local item = items.client.getItem(quests.current.heldItems[slotId])
                if not item then
                    exists = false
                    if slotId <= 4 then
                        item = items.client.getItem(quests.current.cost[slotId])
                    else
                        item = items.client.getItem(quests.current.reward[slotId - 4])
                    end
                end
                if slotId >= 5 then
                    local allExist = true
                    for i, item in ipairs(quests.current.cost) do
                        if not quests.current.heldItems[i] then
                            allExist = false
                            break
                        end
                    end
                    exists = allExist
                end
                if bmx >= slot.x and bmx <= slot.x + slot.w
                and bmy >= slot.y and bmy <= slot.y + slot.h then
                    uiMouseDown = true
                    if item and exists then
                        if btn == 1 then
                            local heldItem = playerController.heldItem
                            heldItem.itemId = item.id
                            heldItem.bagId = 'quest'
                            heldItem.slotId = slotId
                            heldItem.offset.x = slot.x - bmx
                            heldItem.offset.y = slot.y - bmy
                        elseif btn == 2 then
                            local bag = playerController.player.inventory
                            for invSlotId, _ in ipairs(hud.inventorySlots) do
                                local slotType = slot2type[invSlotId]
                                if bag.items[invSlotId] == nil
                                and (slotType == nil or slotType == item.type) then
                                    client.setInventorySlot{
                                        slotId = invSlotId,
                                        itemId = item.id
                                    }
                                    if slot.type == 'cost' then
                                        quests.current.heldItems[slotId] = nil
                                    elseif slot.type == 'reward' then
                                        quests.refresh()
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function items.client.mousereleased(x, y, btn, isTouch, presses)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    local wmx, wmy = camera:screen2world(mx, my)

    if btn == 1 then
        -- hud
        local heldItem = playerController.heldItem
        local itemIsHeld = true
        if heldItem.bagId then
            local bagFrom = client.currentState.lootBags[heldItem.bagId]
            if heldItem.bagId == 'inventory' then
                bagFrom = playerController.player.inventory
            end
            local bagTo = playerController.player.inventory
            local panel = hud.inventoryPanel
            local pmx = mx - lume.round(panel.x)
            local pmy = my - lume.round(panel.y)
            if pmx > 0 and pmx < panel.img:getWidth()
            and pmy > 0 and pmy < panel.img:getHeight() then
                for slotId, slot in ipairs(hud.inventorySlots) do
                    if pmx >= slot.x and pmx <= slot.x + slot.w
                    and pmy >= slot.y and pmy <= slot.y + slot.h then
                        local item = items.client.getItem(heldItem.itemId)
                        if not item then break end
                        local slotType = slot2type[slotId]
                        if (slotType == nil or slotType == item.type) then
                            if heldItem.bagId == 'quest' then
                                client.setInventorySlot{
                                    slotId = slotId,
                                    itemId = heldItem.itemId
                                }
                                if heldItem.slotId <= 4 then
                                    quests.current.heldItems[heldItem.slotId] = nil
                                elseif heldItem.slotId == 5 then
                                    quests.refresh()
                                end
                                itemIsHeld = false
                                break
                            end
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
                            itemIsHeld = false
                            -- move clientside before response (will be corrected/affirmed)
                            local temp = bagTo.items[slotId]
                            bagTo.items[slotId] = bagFrom.items[heldItem.slotId]
                            bagFrom.items[heldItem.slotId] = temp
                            break
                        end
                    end
                end
                -- move to open slot if dropped in inventory panel
                if itemIsHeld then
                    for invSlotId, _ in ipairs(hud.inventorySlots) do
                        local item = items.client.getItem(heldItem.itemId)
                        if not item then break end
                        local slotType = slot2type[invSlotId]
                        if bagTo.items[invSlotId] == nil
                        and (slotType == nil or slotType == item.type) then
                            if heldItem.bagId == 'quest' then
                                client.setInventorySlot{
                                    slotId = invSlotId,
                                    itemId = heldItem.itemId
                                }
                                if heldItem.slotId <= 4 then
                                    quests.current.heldItems[heldItem.slotId] = nil
                                elseif heldItem.slotId == 5 then
                                    quests.refresh()
                                end
                                itemIsHeld = false
                                break
                            end
                            client.moveItem{
                                from = {
                                    bagId = bagFrom.id,
                                    slotId = heldItem.slotId
                                },
                                to = {
                                    bagId = bagTo.id,
                                    slotId = invSlotId
                                }
                            }
                            itemIsHeld = false
                            break
                        end
                    end
                end
            end
        end

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
                    if heldItem.bagId == 'quest' then
                        break
                    end
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
                    itemIsHeld = false
                    -- move clientside before response (will be corrected/affirmed)
                    local temp = bagTo.items[slotId]
                    bagTo.items[slotId] = bagFrom.items[heldItem.slotId]
                    bagFrom.items[heldItem.slotId] = temp
                    break
                end
            end
        end

        -- quest
        local cqb = playerController.closestQuestBlock
        if cqb.id and cqb.open and heldItem.bagId == 'inventory' then
            local qb = client.currentState.entities[cqb.id]
            if qb then
                local p = playerController.player
                local img = gfx.ui.quest
                local bmx = wmx - (lume.round(qb.x + 8) - lume.round(img:getWidth()/2))
                local bmy = wmy - (lume.round(qb.y + 8) - img:getHeight() - 20)
                for slotId=1, 4 do
                    local slot = questBlockSlots[slotId]
                    if bmx >= slot.x and bmx <= slot.x + slot.w
                    and bmy >= slot.y and bmy <= slot.y + slot.h then
                        local item = items.client.getItem(heldItem.itemId)
                        if not item then break end
                        local questItemId = quests.current.cost[slotId]
                        local questItem = items.client.getItem(questItemId)
                        if not questItem then break end
                        if quests.current.heldItems[slotId] == nil
                        and item.imageId == questItem.imageId then
                            quests.current.heldItems[slotId] = p.inventory.items[heldItem.slotId]
                            itemIsHeld = false
                            client.setInventorySlot{
                                slotId = heldItem.slotId,
                                itemId = nil
                            }
                            break
                        end
                    end
                end
            end
        end
        if heldItem.bagId == 'inventory' and itemIsHeld then
            client.dropItem{
                slotId = heldItem.slotId
            }
            itemIsHeld = false
        end
    end
end
