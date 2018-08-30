
require 'utils'
require 'loadassets'
Camera = require 'camera'
camera = Camera{ssx=gsx, ssy=gsy}
nut = require 'love_nut'
json = require 'json'
require 'server'
require 'client'
require 'menu'
require 'physics'
require 'world'
require 'player'
require 'enemies'
require 'hud'
require 'chat'

function love.load()
    gameState = 'menu'
    time = 0
    gameTime = 0
    drawDebug = false
    menu.load()
    physics.load()
    player.load()
    enemies.load()
end

gameScale = math.min(ssx/gsx, ssy/gsy)
function love.resize(w, h)
	ssx = w
	ssy = h
	gameScale = math.min(ssx/gsx, ssy/gsy)
end

function screen2game(x, y)
	x = x - (ssx-gameScale*gsx)/2
	x = x / gameScale
	y = y - (ssy-gameScale*gsy)/2
	y = y / gameScale
	return math.floor(x), math.floor(y)
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
    if gameState == 'playing' and not (server.running and server.paused) then
        gameTime = gameTime + dt
        physics.update(dt)
        world.update(dt)
        player.update(dt)
        enemies.update(dt)
    end
    menu.update(dt)
end

function love.mousepressed(x, y, btn, isTouch)
    if gameState == 'playing' then
        player.mousepressed(x, y, btn)
    end
    menu.mousepressed(x, y, btn)
end

function love.mousereleased(x, y, btn, isTouch)
    menu.mousereleased(x, y, btn)
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
    if chatActive then
        chat.keypressed(k, scancode, isrepeat)
    else
        if gameState == 'playing' and k == 'return' and not isrepeat then
            chat.active = true
        end
    end
    if not chatActive then
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
    local mx, my = screen2game(love.mouse.getPosition())
    love.graphics.setCanvas(canvases.game)
    love.graphics.clear(0.15, 0.15, 0.15)
    if gameState == 'playing' then
        camera:set()

        world.draw()
        enemies.draw()
        player.draw()

        camera:reset()

        hud.draw()
        chat.draw()

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(gfx.cursors.main, mx, my, 0, 1, 1, 0, 0) -- hotspot 0, 0
    end

    menu.draw()

    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvases.game, ssx/2-gameScale*gsx/2, ssy/2-gameScale*gsy/2, 0, gameScale, gameScale)
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
