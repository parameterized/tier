
world = {}

function world.draw()
    if gameState == 'playing' then
        local tileSize = 15
        local bx, by, bw, bh = camera:getAABB()
        local bi, bj = math.floor(bx/tileSize), math.floor(by/tileSize)
        local tileChoices = {'grass', 'sand', 'rock', 'water'}
        for i=-1, math.floor(bw/tileSize)+1 do
            for j=-1, math.floor(bh/tileSize)+1 do
                local x = (bi + i)*tileSize
                local y = (bj + j)*tileSize
                local h1 = hash2(bi + i, bj + j)
                local choice
                for ci, cv in pairs(tileChoices) do
                    if h1 < ci/#tileChoices then
                        choice = cv
                        break
                    end
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(gfx.tiles.tileSheet1, tileSheets.ts1.quads[choice], x, y)
            end
        end
    end
end
