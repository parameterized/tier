
text = {}

function text.print(txt, x, y)
    local _shader = love.graphics.getShader()
    love.graphics.setShader(shaders.fontAlias)
    love.graphics.print(txt, math.floor(x), math.floor(y))
    love.graphics.setShader(_shader)
end

function text.printSmall(txt, x, y)
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()
    setGameCanvas2x()
    love.graphics.setShader(shaders.fontAlias)

    love.graphics.push()
    -- set camera with 2x screen size
    if camera.isSet then
        love.graphics.origin()
        love.graphics.translate(camera.ssx, camera.ssy)
        love.graphics.scale(camera.scale)
        love.graphics.rotate(camera.rotation)
        love.graphics.translate(-camera.x*2, -camera.y*2)
    end

    love.graphics.print(txt, math.floor(x*2), math.floor(y*2))

    love.graphics.pop()
    love.graphics.setCanvas(_canvas)
    love.graphics.setShader(_shader)
end
