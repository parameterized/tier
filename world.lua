
world = {}

function world.draw()
    if gameState == 'playing' then
        local tileSize = 15
        local bx, by, bw, bh = camera:getAABB()
        local bi, bj = math.floor(bx/tileSize), math.floor(by/tileSize)
        for i=-1, math.floor(bw/tileSize)+1 do
            for j=-1, math.floor(bh/tileSize)+1 do
                local x = (bi + i)*tileSize
                local y = (bj + j)*tileSize
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
