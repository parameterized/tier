
world = {
    server = {
        chunks = {},
    },
    client = {
        chunks = {},
        chunkImages = {}, -- 1 pix/tile (minimap)
        chunkIdImages = {}
    }
}

world.chunkSize = 8
world.tileColors = {
    {98/255, 195/255, 116/255},
    {251/255, 228/255, 125/255},
    {98/255, 98/255, 98/255},
    {41/255, 137/255, 214/255}
}

world.server.chunkCanvas = love.graphics.newCanvas(world.chunkSize, world.chunkSize)
-- max tiles visible (ceil(x)+1) + sides for blending (+2)
local w, h = math.ceil(gsx/15) + 1 + 2, math.ceil(gsy/15) + 1 + 2
world.client.tileIdCanvas = love.graphics.newCanvas(w, h)
shaders.mapRender:send('tileIdRes', {w, h})

function world.server.getChunk(x, y)
    if world.server.chunks[x] and world.server.chunks[x][y] then
        return world.server.chunks[x][y]
    else
        if world.server.chunks[x] == nil then world.server.chunks[x] = {} end

        local _canvas = love.graphics.getCanvas()
        local _shader = love.graphics.getShader()

        love.graphics.setCanvas(world.server.chunkCanvas)
        love.graphics.clear()
        love.graphics.setShader(shaders.mapGen)
        shaders.mapGen:send('camPos', {x*world.chunkSize, y*world.chunkSize})

        love.graphics.push()
        love.graphics.origin()
        love.graphics.rectangle('fill', 0, 0, world.chunkSize, world.chunkSize)
        love.graphics.pop()

        love.graphics.setCanvas(_canvas)
        love.graphics.setShader(_shader)

        local imageData = world.server.chunkCanvas:newImageData()
        world.server.chunks[x][y] = {}
        local chunk = world.server.chunks[x][y]
        for i=1, world.chunkSize do
            if chunk[i] == nil then chunk[i] = {} end
            for j=1, world.chunkSize do
                local v = imageData:getPixel(i-1, j-1)
                v = lume.round(v*255)
                chunk[i][j] = v
            end
        end
        return chunk
    end
end

function world.server.reset()
    world.server.chunks = {}
end



function world.client.setChunk(x, y, chunk)
    if world.client.chunks[x] == nil then world.client.chunks[x] = {} end
    world.client.chunks[x][y] = chunk
    local imageData = love.image.newImageData(world.chunkSize, world.chunkSize)
    local idImageData = love.image.newImageData(world.chunkSize, world.chunkSize)
    for i=1, world.chunkSize do
        for j=1, world.chunkSize do
            local v = chunk[i][j]
            imageData:setPixel((i-1), (j-1), unpack(world.tileColors[v]))
            idImageData:setPixel((i-1), (j-1), v/255, 0, 0)
        end
    end
    if world.client.chunkImages[x] == nil then world.client.chunkImages[x] = {} end
    world.client.chunkImages[x][y] = love.graphics.newImage(imageData)
    if world.client.chunkIdImages[x] == nil then world.client.chunkIdImages[x] = {} end
    world.client.chunkIdImages[x][y] = love.graphics.newImage(idImageData)
end

function world.client.reset()
    world.client.chunks = {}
end

function world.client.update(dt)
    -- get visible chunks (+ pad) if nil
    local cx1 = math.floor((camera.x - camera.ssx/2)/15/world.chunkSize) - 1
    local cx2 = math.floor((camera.x + camera.ssx/2)/15/world.chunkSize) + 1
    local cy1 = math.floor((camera.y - camera.ssy/2)/15/world.chunkSize) - 1
    local cy2 = math.floor((camera.y + camera.ssy/2)/15/world.chunkSize) + 1
    for cx=cx1, cx2 do
        for cy=cy1, cy2 do
            if not world.client.chunks[cx] or not world.client.chunks[cx][cy] then
                client.nutClient:sendRPC('getWorldChunk', bitser.dumps{x=cx, y=cy})
            end
        end
    end
end

function world.client.draw()
    print((camera.x - camera.ssx/2)/15)
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- set id canvas
    love.graphics.setCanvas(world.client.tileIdCanvas)
    love.graphics.clear()
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    -- visible tile (+ blend pad) chunks
    local tx1 = math.floor((camera.x - camera.ssx/2)/15) - 1
    local tx2 = math.floor((camera.x + camera.ssx/2)/15) + 1
    local ty1 = math.floor((camera.y - camera.ssy/2)/15) - 1
    local ty2 = math.floor((camera.y + camera.ssy/2)/15) + 1
    local cx1 = math.floor(tx1/world.chunkSize)
    local cx2 = math.floor(tx2/world.chunkSize)
    local cy1 = math.floor(ty1/world.chunkSize)
    local cy2 = math.floor(ty2/world.chunkSize)
    local idImgs = world.client.chunkIdImages
    for cx=cx1, cx2 do
        for cy=cy1, cy2 do
            if idImgs[cx] and idImgs[cx][cy] then
                love.graphics.draw(idImgs[cx][cy], cx*world.chunkSize - tx1, cy*world.chunkSize - ty1)
            end
        end
    end
    love.graphics.pop()
    love.graphics.setCanvas(_canvas)

    -- draw world
    love.graphics.setShader(shaders.mapRender)
    shaders.mapRender:send('tileIds', world.client.tileIdCanvas)
    shaders.mapRender:send('camPos', {
        camera.x - camera.ssx/2,
        camera.y - camera.ssy/2
    })
    shaders.mapRender:send('tilemapPos', {
        math.floor((camera.x - camera.ssx/2)/15) - 2,
        math.floor((camera.y - camera.ssy/2)/15) - 2,
    })
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.rectangle('fill', 0, 0, gsx, gsy)
    love.graphics.pop()
    love.graphics.setShader(_shader)

    -- test shader validity
    if false then
        love.graphics.setColor(1, 1, 1, 0.4)
        for cx, chunkCol in pairs(world.client.chunkImages) do -- chunks[x]
            for cy, img in pairs(chunkCol) do
                love.graphics.draw(img, cx*world.chunkSize*15, cy*world.chunkSize*15, 0, 15, 15)
            end
        end
    end
end

function world.client.drawMinimap()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()
    -- todo: 2x

    love.graphics.setCanvas{canvases.game, stencil=true}
    local x = hud.mapPanel.x + 7
    local y = hud.mapPanel.y + 8
    local p = playerController.player
    local px = math.floor(lume.round(p.body:getX())/15)
    local py = math.floor(lume.round(p.body:getY())/15)

    -- bg
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', x, y, 60, 62)

    -- tiles
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', x, y, 60, 62)
    end, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)
    love.graphics.setColor(1, 1, 1)
    for cx, chunkCol in pairs(world.client.chunkImages) do
        for cy, img in pairs(chunkCol) do
            local dx = cx*world.chunkSize - px
            local dy = cy*world.chunkSize - py
            if dx + world.chunkSize >= -30 and dx <= 30
            and dy + world.chunkSize >= -31 and dy < 31 then
                love.graphics.draw(img, x + 30 + dx, y + 31 + dy)
            end
        end
    end
    love.graphics.setStencilTest()

    -- entities/players
    love.graphics.setCanvas(canvases.tempGame)
    love.graphics.clear()
    for _, v in pairs(client.currentState.entities) do
        if not v.destroyed and v.id ~= playerController.serverId and v.id ~= playerController.player.id then
            if v.type == 'player' then
                love.graphics.setColor(255/255, 216/255, 0/255)
            else
                love.graphics.setColor(1, 0, 0)
            end
            local ex = math.floor(lume.round(v.x)/15)
            local ey = math.floor(lume.round(v.y)/15)
            local dx = ex - px
            local dy = ey - py
            if math.abs(dx) <= 30 and math.abs(dy) <= 31 then
                love.graphics.rectangle('fill', x + 30 + dx, y + 31 + dy, 1, 1)
            end
        end
    end

    -- local player
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle('fill', x + 30, y + 31, 1, 1)

    -- ent/player outline
    love.graphics.setCanvas(_canvas)
    love.graphics.setShader(shaders.outline)
    shaders.outline:send('stepSize', {
        1/canvases.tempGame:getWidth(),
        1/canvases.tempGame:getHeight()
    })
    shaders.outline:send('outlineColor', {0, 0, 0, 1})
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvases.tempGame, 0, 0)
    love.graphics.setShader(_shader)
end
