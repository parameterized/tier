
playerController = {}

function playerController.load()
    playerController.player = entities.client.defs.player:new{isLocalPlayer=true}:spawn()
    playerController.serverId = nil
end

function playerController.update(dt)
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)

    local inputState = {keyboard={}, mouse={}}
    for _, key in pairs{'w', 'a', 's', 'd', 'lshift'} do
        inputState.keyboard[key] = love.keyboard.isScancodeDown(key) and not chat.active
    end
    inputState.mouse.lmb = love.mouse.isDown(1) and not uiMouseDown
    inputState.mouse.x = mx
    inputState.mouse.y = my

    local p = playerController.player
    p:setInputState(inputState)

    local dx = mx - gsx/2
    local dy = my - gsy/2
    local a = math.atan2(dx, dy) - math.pi/2
    local d = math.min(math.sqrt(dx^2 + dy^2), gsy/2)
    camera.x = lume.round(p.body:getX()) + lume.round(math.cos(a)*d/6)
    camera.y = lume.round(p.body:getY() - 14) + lume.round(-math.sin(a)*d/6)
end

function playerController.mousepressed(x, y, btn)
    if not uiMouseDown then
        playerController.player:mousepressed(x, y, btn)
    end
end
