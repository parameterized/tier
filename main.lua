
--PROF_CAPTURE = true
prof = require 'lib.jprof'
--prof.connect()
manual_gc = require 'lib.manual_gc'
lume = require 'lib.lume'
nut = require 'lib.love_nut'
json = require 'lib.json'
bitser = require 'lib.bitser'
Camera = require 'lib.camera'

require 'tempCommon'
require 'utils'
require 'loadassets'
require 'sound'
require 'server'
require 'client'
require 'cursor'
require 'text'
require 'menu'
require 'hud'
require 'chat'
require 'physics'
require 'scene'
require 'world'
require 'entities'
require 'projectiles'
require 'slimeBalls'
require 'playerController'
require 'items'
require 'lootBag'
require 'portals'
require 'damageText'
require 'realm'
require 'quests'

function love.load()
    camera = Camera{ssx=gsx, ssy=gsy}
    gameState = 'menu'
    time = 0
    gameTime = 0
    -- don't shoot if pressing ui
    uiMouseDown = false
    drawDebug = false
    menu.load()
    hud.load()
    serverRealm = realm.server:new()
    clientRealm = realm.client:new()
    love.mouse.setVisible(false)
end

gameScale = math.min(ssx/gsx, ssy/gsy)
function love.resize(w, h)
	ssx = w
	ssy = h
	gameScale = math.min(ssx/gsx, ssy/gsy)
end

function love.update(dt)
    prof.push('frame')
    prof.push('update')
    time = time + dt
    love.window.setTitle('Tier (' .. love.timer.getFPS() .. ' FPS)')
    cursor.cursor = cursor.main
    prof.push('update server')
    if server.running then
        server.update(dt)
    end
    prof.pop('update server')
    prof.push('update client')
    if client.connected then
        client.update(dt)
    end
    prof.pop('update client')
    prof.push('update menu')
    menu.update(dt)
    prof.pop('update menu')
    prof.push('update gc')
    manual_gc(1e-3, 64)
    prof.pop('update gc')
    prof.pop('update')

    shaders.mapRender:send('drawDebug', drawDebug)
end

function love.mousepressed(x, y, btn, isTouch, presses)
    menu.mousepressed(x, y, btn, isTouch, presses)
    if gameState == 'playing' then
        hud.mousepressed(x, y, btn, isTouch, presses)
        playerController.mousepressed(x, y, btn, isTouch, presses)
        items.client.mousepressed(x, y, btn, isTouch, presses)
    end
end

function love.mousereleased(x, y, btn, isTouch, presses)
    menu.mousereleased(x, y, btn, isTouch, presses)
    if gameState == 'playing' then
        hud.mousereleased(x, y, btn, isTouch, presses)
        playerController.mousereleased(x, y, btn, isTouch, presses)
        items.client.mousereleased(x, y, btn, isTouch, presses)
    end

    if not love.mouse.isDown(1) and not love.mouse.isDown(2) then
        uiMouseDown = false
        local heldItem = playerController.heldItem
        heldItem.itemId = nil
        heldItem.bagId = nil
        heldItem.slotId = nil
    end
end

function love.textinput(t)
    if chat.active then
        chat.textinput(t)
    else
        menu.textinput(t)
    end
end

function love.keypressed(k, scancode, isrepeat)
    local chatActive = chat.active
    local chatPanelOpen = hud.chatPanel.open
    if chatActive or chatPanelOpen then
        chat.keypressed(k, scancode, isrepeat)
    end
    if not chatActive then
        if gameState == 'playing' and k == 'return' and not isrepeat then
            chat.active = true
            hud.chatPanel.open = true
        end
    end
    -- if chat open, esc pressed, chat.active=false & chatActive=true
    if not (chatActive or chat.active) then
        if gameState == 'menu' then
            menu.keypressed(k, scancode, isrepeat)
        elseif gameState == 'playing' then
            hud.keypressed(k, scancode, isrepeat)
            playerController.keypressed(k, scancode, isrepeat)
            portals.client.keypressed(k, scancode, isrepeat)
            if false then
                if k == 'q' then
                    local p = playerController.player
                    for _, costItemId in ipairs(quests.current.cost) do
                        local costItem = items.client.getItem(costItemId)
                        if costItem then
                            -- duplicates costItem
                            for invSlotId, _ in ipairs(hud.inventorySlots) do
                                local slotType = slot2type[invSlotId]
                                if p.inventory.items[invSlotId] == nil
                                and (slotType == nil or slotType == costItem.type) then
                                    client.setInventorySlot{
                                        slotId = invSlotId,
                                        itemId = costItemId
                                    }
                                    p.inventory.items[invSlotId] = costItemId
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if not isrepeat then
            if k == 'escape' and not chatPanelOpen then
                gameState = 'menu'
                menu.state = 'main'
                if server.running then
                    server.close()
                end
                if client.connected then
                    client.close()
                end
                love.mouse.setGrabbed(false)
            elseif k == 'f1' then
                drawDebug = not drawDebug
            end
        end
    end
end

function love.draw()
    prof.push('draw')
    prof.push('draw setup')
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    love.graphics.setBlendMode('alpha')
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.clear()
    love.graphics.setCanvas(canvases.game)
    love.graphics.clear(0.15, 0.15, 0.15)
    prof.pop('draw setup')
    if gameState == 'playing' then
        prof.push('draw playing')
        camera:set()

        prof.push('draw scene')
        scene.reset()
        -- world and loot bags
        clientRealm:draw()

        entities.client.draw()
        projectiles.client.draw()
        slimeBalls.draw()
        portals.client.draw()

        scene.draw()
        damageText.draw()
        prof.pop('draw scene')

        prof.push('draw debug')
        if drawDebug then
            if server.running then
                serverRealm.physics:draw()
            end
            if client.connected then
                clientRealm.physics:draw()
            end
        end
        prof.pop('draw debug')

        camera:reset()

        prof.push('draw hud/chat')
        hud.draw()
        chat.draw()
        prof.pop('draw hud/chat')

        if love.keyboard.isScancodeDown('g') then
            clientRealm.world:drawMap('full')
        end

        prof.pop('draw playing')
    end

    prof.push('draw menu/cursor')
    menu.draw()
    cursor.draw()
    prof.pop('draw menu/cursor')

    prof.push('draw canvas')
    -- draw game on game2x
    setGameCanvas2x()
    love.graphics.setCanvas()
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvases.game2x, ssx/2-gameScale*gsx/2, ssy/2-gameScale*gsy/2, 0, gameScale/2, gameScale/2)
    prof.pop('draw canvas')
    prof.pop('draw')
    prof.pop('frame')
end

function love.quit()
    if server.running then
        server.close()
    end
    if client.connected then
        client.close()
    end
    menu.writeDefaults()
    --prof.write('prof.mpack')
end
