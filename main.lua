
require 'utils'
require 'loadassets'
Camera = require 'camera'
camera = Camera{ssx=gsx, ssy=gsy}
require 'menu'
require 'physics'
require 'world'
require 'player'

function love.load()
    gameState = 'menu'
    physics.load()
    player.load()
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
    love.window.setTitle('Tier (' .. love.timer.getFPS() .. ' FPS)')
    if gameState == 'playing' then
        physics.update(dt)
        world.update(dt)
        player.update(dt)
    end
end

function love.mousepressed(x, y, btn, isTouch)
    menu.mousepressed(x, y, btn)
end

function love.keypressed(k, scancode, isrepeat)
    if k == 'escape' then
        gameState = 'menu'
    elseif k == 'space' then
        --world.shader = not world.shader
    end
end

function love.draw()
    love.graphics.setCanvas(canvases.game)
    love.graphics.clear(0.1, 0.1, 0.1)
    if gameState == 'playing' then
        camera:set()

        world.draw()
        player.draw()

        camera:reset()
    end

    menu.draw()

    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvases.game, ssx/2-gameScale*gsx/2, ssy/2-gameScale*gsy/2, 0, gameScale, gameScale)
end
