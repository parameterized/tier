
playerController = {
    interactRange = 30,
    closestBag = {id=nil, dist=nil, open=false},
    hoveredItem = nil,
    heldItem = {itemId=nil, bagId=nil, slotId=nil, offset={x=0, y=0}},
    closestQuestBlock = {id=nil, dist=nil, open=false}
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
        local dist = lume.distance(bag.x, bag.y, px, py)
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
    if heldItem.bagId ~= 'inventory' and heldItem.bagId ~= 'quest' and (not closestBag.id
    or closestBag.id ~= heldItem.bagId or closestBag.dist > playerController.interactRange) then
        heldItem.itemId = nil
        heldItem.bagId = nil
        heldItem.slotId = nil
    end
    playerController.hoveredItem = nil

    -- update closest questBlock
    local cqb = playerController.closestQuestBlock
    local lastId = cqb.id
    cqb.id = nil
    cqb.dist = nil
    for _, v in pairs(client.currentState.entities) do
        if not v.destroyed and v.type == 'questBlock' then
            local dist = math.max(math.abs(v.x + 8 - px), math.abs(v.y + 8 - py))
            if not cqb.dist or dist < cqb.dist then
                cqb.id = v.id
                cqb.dist = dist
            end
        end
    end
    if not cqb.id or cqb.id ~= lastId or cqb.dist > playerController.interactRange then
        cqb.open = false
    end
end

function playerController.mousepressed(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    local wmx, wmy = camera:screen2world(mx, my)

    -- player attack
    if not uiMouseDown then
        playerController.player:mousepressed(x, y, btn)
    end
end

function playerController.mousereleased(x, y, btn)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
    local wmx, wmy = camera:screen2world(mx, my)
end

function playerController.keypressed(k, scancode, isrepeat)
    if scancode == 'e' and not isrepeat then
        local closestBag = playerController.closestBag
        if closestBag.id and closestBag.dist < playerController.interactRange then
            closestBag.open = not closestBag.open
        end
        local cqb = playerController.closestQuestBlock
        if cqb.id and cqb.dist < playerController.interactRange then
            cqb.open = not cqb.open
        end
    end
end
