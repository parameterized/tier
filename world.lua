
world = {
    server = {},
    client = {}
}

local chunkSize = 8

local defaults = {server={}, client={}}
for _, sc in pairs{'server', 'client'} do
    defaults[sc].chunks = function() return {} end
    defaults[sc].chunkSize = function() return chunkSize end
end
defaults.server.chunkCanvas = function()
    return love.graphics.newCanvas(chunkSize, chunkSize)
end
defaults.client.chunkImages = function() return {} end
defaults.client.chunkIdImages = function() return {} end
defaults.client.tileColors = function()
    return {
        {98/255, 195/255, 116/255},
        {251/255, 228/255, 125/255},
        {98/255, 98/255, 98/255},
        {41/255, 137/255, 214/255},
        {73/255, 73/255, 73/255}
    }
end
-- max tiles visible (ceil(x)+1) + sides for blending (+2)
local w, h = math.ceil(gsx/15) + 1 + 2, math.ceil(gsy/15) + 1 + 2
defaults.client.tileIdCanvas = function()
    return love.graphics.newCanvas(w, h)
end
shaders.mapRender:send('tileIdRes', {w, h})



function world.server:new(o)
    o = o or {}
    for k, v in pairs(defaults.server) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function world.server:getChunk(x, y)
    if self.chunks[x] and self.chunks[x][y] then
        return self.chunks[x][y]
    else
        if self.chunks[x] == nil then self.chunks[x] = {} end

        local _canvas = love.graphics.getCanvas()
        local _shader = love.graphics.getShader()

        love.graphics.setCanvas(self.chunkCanvas)
        love.graphics.clear()
        love.graphics.setShader(shaders.mapGen)
        shaders.mapGen:send('camPos', {x*self.chunkSize, y*self.chunkSize})

        love.graphics.push()
        love.graphics.origin()
        love.graphics.rectangle('fill', 0, 0, self.chunkSize, self.chunkSize)
        love.graphics.pop()

        love.graphics.setCanvas(_canvas)
        love.graphics.setShader(_shader)

        local imageData = self.chunkCanvas:newImageData()
        self.chunks[x][y] = {}
        local chunk = self.chunks[x][y]
        for i=1, self.chunkSize do
            if chunk[i] == nil then chunk[i] = {} end
            for j=1, self.chunkSize do
                local v = imageData:getPixel(i-1, j-1)
                v = lume.round(v*255)
                chunk[i][j] = v
            end
        end
        return chunk
    end
end

function world.server:getTile(x, y)
    local tx = math.floor(x/15)
    local ty = math.floor(y/15)
    local cx = math.floor(tx/self.chunkSize)
    local cy = math.floor(ty/self.chunkSize)
    tx = tx - cx*self.chunkSize + 1
    ty = ty - cy*self.chunkSize + 1
    if self.chunks[cx] and self.chunks[cx][cy] then
        return self.chunks[cx][cy][tx][ty]
    end
end

function world.server:destroy()
    self.chunks = {}
end



function world.client:new(o)
    o = o or {}
    for k, v in pairs(defaults.client) do
        if o[k] == nil then o[k] = v() end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function world.client:setChunk(x, y, chunk)
    if self.chunks[x] == nil then self.chunks[x] = {} end
    self.chunks[x][y] = chunk
    local imageData = love.image.newImageData(self.chunkSize, self.chunkSize)
    local idImageData = love.image.newImageData(self.chunkSize, self.chunkSize)
    for i=1, self.chunkSize do
        for j=1, self.chunkSize do
            local v = chunk[i][j]
            imageData:setPixel((i-1), (j-1), unpack(self.tileColors[v] or {0,0,0}))
            idImageData:setPixel((i-1), (j-1), v/255, 0, 0)
        end
    end
    if self.chunkImages[x] == nil then self.chunkImages[x] = {} end
    self.chunkImages[x][y] = love.graphics.newImage(imageData)
    if self.chunkIdImages[x] == nil then self.chunkIdImages[x] = {} end
    self.chunkIdImages[x][y] = love.graphics.newImage(idImageData)
end

function world.client:getTile(x, y)
    local tx = math.floor(x/15)
    local ty = math.floor(y/15)
    local cx = math.floor(tx/self.chunkSize)
    local cy = math.floor(ty/self.chunkSize)
    tx = tx - cx*self.chunkSize + 1
    ty = ty - cy*self.chunkSize + 1
    if self.chunks[cx] and self.chunks[cx][cy] then
        return self.chunks[cx][cy][tx][ty]
    end
end

function world.client:destroy()
    self.chunks = {}
end

function world.client:update(dt)
    -- get visible chunks (+ pad) if nil
    local p = playerController.player
    local cx1 = math.floor((p.x - 465)/15/self.chunkSize) - 1
    local cx2 = math.floor((p.x + 465)/15/self.chunkSize) + 1
    local cy1 = math.floor((p.y - 465)/15/self.chunkSize) - 1
    local cy2 = math.floor((p.y + 465)/15/self.chunkSize) + 1
    for cx=cx1, cx2 do
        for cy=cy1, cy2 do
            if not self.chunks[cx] or not self.chunks[cx][cy] then
                client.nutClient:sendRPC('getWorldChunk', bitser.dumps{x=cx, y=cy})
            end
        end
    end
end

function world.client:draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    -- set id canvas
    love.graphics.setCanvas(self.tileIdCanvas)
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
    local cx1 = math.floor(tx1/self.chunkSize)
    local cx2 = math.floor(tx2/self.chunkSize)
    local cy1 = math.floor(ty1/self.chunkSize)
    local cy2 = math.floor(ty2/self.chunkSize)
    local idImgs = self.chunkIdImages
    for cx=cx1, cx2 do
        for cy=cy1, cy2 do
            if idImgs[cx] and idImgs[cx][cy] then
                love.graphics.draw(idImgs[cx][cy], cx*self.chunkSize - tx1, cy*self.chunkSize - ty1)
            end
        end
    end
    love.graphics.pop()
    love.graphics.setCanvas(_canvas)

    -- draw world
    love.graphics.setShader(shaders.mapRender)
    shaders.mapRender:send('tileIds', self.tileIdCanvas)
    shaders.mapRender:send('camPos', {
        camera.x - camera.ssx/2,
        camera.y - camera.ssy/2
    })
    shaders.mapRender:send('tilemapPos', {
        math.floor((camera.x - camera.ssx/2)/15) - 2,
        math.floor((camera.y - camera.ssy/2)/15) - 2,
    })
    shaders.mapRender:send('time', time)
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.rectangle('fill', 0, 0, gsx, gsy)
    love.graphics.pop()
    love.graphics.setShader(_shader)

    -- test shader validity
    if false then
        love.graphics.setColor(1, 1, 1, 0.4)
        for cx, chunkCol in pairs(self.chunkImages) do -- chunks[x]
            for cy, img in pairs(chunkCol) do
                love.graphics.draw(img, cx*self.chunkSize*15, cy*self.chunkSize*15, 0, 15, 15)
            end
        end
    end
end

function world.client:drawMinimap()
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
    for cx, chunkCol in pairs(self.chunkImages) do
        for cy, img in pairs(chunkCol) do
            local dx = cx*self.chunkSize - px
            local dy = cy*self.chunkSize - py
            if dx + self.chunkSize >= -30 and dx <= 30
            and dy + self.chunkSize >= -31 and dy < 31 then
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
