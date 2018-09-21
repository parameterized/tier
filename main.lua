
lume = require 'lib.lume'
nut = require 'lib.love_nut'
json = require 'lib.json'
Camera = require 'lib.camera'

require 'utils'
require 'loadassets'
require 'text'
require 'server'
require 'client'
require 'menu'
require 'hud'
require 'physics'
require 'scene'
require 'world'
require 'player'
require 'projectiles'
require 'entities'
require 'lootBags'
require 'chat'

function love.load()
    camera = Camera{ssx=gsx, ssy=gsy}
    gameState = 'menu'
    time = 0
    gameTime = 0
    gcTimer = 10
    -- don't shoot if pressing ui
    uiMouseDown = false
    drawDebug = false
    menu.load()
    hud.load()
end

gameScale = math.min(ssx/gsx, ssy/gsy)
function love.resize(w, h)
	ssx = w
	ssy = h
	gameScale = math.min(ssx/gsx, ssy/gsy)
end

-- window to game canvas
function window2game(x, y)
	x = x - (ssx-gameScale*gsx)/2
	x = x / gameScale
	y = y - (ssy-gameScale*gsy)/2
	y = y / gameScale
	return x, y
end

function setGameCanvas2x()
    local _shader = love.graphics.getShader()
    local _color = {love.graphics.getColor()}
    love.graphics.setShader()
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.draw(canvases.game, 0, 0, 0, 2, 2)
    love.graphics.pop()
    love.graphics.setCanvas(canvases.game)
    love.graphics.setBlendMode('alpha')
    love.graphics.clear()
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.setShader(_shader)
    love.graphics.setColor(_color)
end

function love.update(dt)
    time = time + dt
    love.window.setTitle('Tier (' .. love.timer.getFPS() .. ' FPS)')
    if server.running then
        server.update(dt)
    end
    if client.connected then
        client.update(dt)
    end
    menu.update(dt)
    gcTimer = gcTimer - dt
    if gcTimer < 0 then
        collectgarbage()
        gcTimer = 10
    end
end

function love.mousepressed(x, y, btn, isTouch)
    if gameState == 'playing' then
        player.mousepressed(x, y, btn)
        hud.mousepressed(x, y, btn)
        lootBags.client.mousepressed(x, y, btn)
    end
    menu.mousepressed(x, y, btn)
end

function love.mousereleased(x, y, btn, isTouch)
    if gameState == 'playing' then
        player.mousereleased(x, y, btn)
        hud.mousereleased(x, y, btn)
        lootBags.client.mousereleased(x, y, btn)
    end
    menu.mousereleased(x, y, btn)
    uiMouseDown = false
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
    if not (chatActive or chat.active or chatPanelOpen) then
        menu.keypressed(k, scancode, isrepeat)
        if not isrepeat then
            if k == 'escape' then
                gameState = 'menu'
                menu.state = 'main'
                if server.running then
                    server.close()
                end
                if client.connected then
                    client.close()
                end
                love.mouse.setVisible(true)
                love.mouse.setGrabbed(false)
            elseif k == 'f1' then
                drawDebug = not drawDebug
            end
        end
    end
end

function love.draw()
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    love.graphics.setBlendMode('alpha')
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.clear()
    love.graphics.setCanvas(canvases.game)
    love.graphics.clear(0.15, 0.15, 0.15)
    if gameState == 'playing' then
        camera:set()

        world.draw()
        entities.client.draw()
        lootBags.client.draw()
        projectiles.client.draw()
        player.draw()

        scene.draw()
        scene.reset()

        if drawDebug then
            if server.running then
                local serverBodies = physics.server.world:getBodies()
                love.graphics.setColor(1, 0, 0, 0.5)
                for _, v in pairs(serverBodies) do
                    local x, y = v:getPosition()
                    love.graphics.circle('fill', x, y, 8)
                end
            end
            if client.connected then
                local clientBodies = physics.client.world:getBodies()
                love.graphics.setColor(0, 1, 0, 0.5)
                for _, v in pairs(clientBodies) do
                    local x, y = v:getPosition()
                    love.graphics.circle('fill', x, y, 6)
                end
            end
        end

        camera:reset()

        hud.draw()
        chat.draw()

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(gfx.cursors.main, mx, my, 0, 1, 1, 0, 0) -- hotspot 0, 0
    end

    menu.draw()

    -- draw game on game2x
    setGameCanvas2x()
    love.graphics.setCanvas()
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvases.game2x, ssx/2-gameScale*gsx/2, ssy/2-gameScale*gsy/2, 0, gameScale/2, gameScale/2)
end

function love.quit()
    if server.running then
        server.close()
    end
    if client.connected then
        client.close()
    end
    menu.writeDefaults()
end
