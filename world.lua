
world = {}

world.chunks = {}
world.tileSize = 15
world.chunkSize = 8

function world.update(dt)

end

world.shader = true
function world.draw()
    if world.shader then
        camera:reset()
        love.graphics.setShader(shaders.mapGen)
        shaders.mapGen:send('camPos', {camera.x, camera.y})
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle('fill', 0, 0, gsx, gsy)
        love.graphics.setShader()
        camera:set()
    else
        local bx, by, bw, bh = camera:getAABB()
        local bi, bj = math.floor(bx/world.tileSize), math.floor(by/world.tileSize)
        for i=-1, math.floor(bw/world.tileSize)+1 do
            for j=-1, math.floor(bh/world.tileSize)+1 do
                local x = (bi + i)*world.tileSize
                local y = (bj + j)*world.tileSize
                local tileChoices = {'grass', 'sand', 'water'}
                local r1 = love.math.noise((bi + i)/32, (bj + j)/32)
                local choice
                for ci, cv in pairs(tileChoices) do
                    if r1 < ci/#tileChoices then
                        choice = cv
                        break
                    end
                end
                local r2 = love.math.noise(1000 + (bi + i)/64, 1000 + (bj + j)/64)
                if r1 < 0.2 and r2 < 0.5 then
                    choice = 'rock'
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(gfx.tiles.tileSheet1, tileSheets.ts1.quads[choice], x, y)
            end
        end
    end
end
