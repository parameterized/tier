
world = {
    server = {},
    client = {}
}

local chunkSize = 8

-- max tiles visible (ceil(x)+1) + sides for blending (+2)
local tileIdW, tileIdH = math.ceil(gsx/15) + 1 + 2, math.ceil(gsy/15) + 1 + 2
shaders.mapRender:send('tileIdRes', {tileIdW, tileIdH})

for _, sc in ipairs{'server', 'client'} do
    world[sc].newDefaults = function()
        local t = {
            chunks = {},
            chunkSize = chunkSize
        }
        if sc == 'server' then
            t.chunkCanvas = love.graphics.newCanvas(chunkSize, chunkSize)
        elseif sc == 'client' then
            t.chunkImages = {}
            t.chunkIdImages = {}
            t.tileColors = {
                --[[
                {41, 137, 214}, -- water
                {251, 228, 125}, -- sand
                {98, 195, 116}, -- grass
                {98, 98, 98}, -- rock
                ]]
                {10, 10, 149}, -- water
                {170, 135, 69}, -- sand1
                {190, 186, 141}, -- sand2
                {149, 153, 64}, -- grass1
                {51, 62, 33}, -- grass2
                {77, 93, 55}, -- grass3
                {64, 139, 71}, -- grass4
                {89, 131, 51}, -- grass5
                {247, 247, 247}, -- snow
                {192, 207, 211}, -- ice
                {205, 140, 79}, -- path
                {183, 163, 43}, -- floor
                {104, 88, 0}, -- wall
                {73, 73, 73}, -- platform
                {73, 73, 73} -- platform2
            }
            for _, color in ipairs(t.tileColors) do
                for i=1, 3 do
                    color[i] = color[i]/255
                end
            end
            t.tileIdCanvas = love.graphics.newCanvas(tileIdW, tileIdH)
        end
        return t
    end

    world[sc].new = function(self, o)
        o = o or {}
        for k, v in pairs(self.newDefaults()) do
            if o[k] == nil then o[k] = v end
        end
        setmetatable(o, self)
        self.__index = self
        return o
    end
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
    return self:getChunk(cx, cy)[tx][ty]
end

function world.server:destroy()
    self.chunks = {}
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
    -- have to wait for server to send
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

function world.client:drawMap(mapSize)
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()
    -- todo: 2x

    if mapSize == nil then mapSize = 'full' end

    local x, y = 0, 0
    local w, h = gsx, gsy
    love.graphics.setCanvas{canvases.game, stencil=true}
    if mapSize == 'mini' then
        x = hud.mapPanel.x + 7
        y = hud.mapPanel.y + 8
        w, h = 60, 62
    end
    local p = playerController.player
    local px = math.floor(lume.round(p.body:getX())/15)
    local py = math.floor(lume.round(p.body:getY())/15)

    -- bg
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle('fill', x, y, w, h)

    -- tiles
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', x, y, w, h)
    end, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)
    love.graphics.setColor(1, 1, 1)
    local cs = self.chunkSize
    for cx=math.floor((px - w/2)/cs), math.floor((px + w/2)/cs) do
        for cy=math.floor((py - h/2)/cs), math.floor((py + h/2)/cs) do
            local img = safeIndex(self.chunkImages, cx, cy)
            if img then
                local dx = cx*cs - px
                local dy = cy*cs - py
                love.graphics.draw(img, x + math.floor(w/2) + dx, y + math.floor(h/2) + dy)
            end
        end
    end
    love.graphics.setStencilTest()

    -- entities/players
    love.graphics.setCanvas(canvases.tempGame)
    love.graphics.clear()
    for _, v in pairs(client.currentState.entities) do
        if not v.destroyed and v.id ~= playerController.serverId and v.id ~= playerController.player.id
        and (v.type == 'player' or v.enemy) then
            if v.type == 'player' then
                love.graphics.setColor(255/255, 216/255, 0/255)
            else
                love.graphics.setColor(1, 0, 0)
            end
            local ex = math.floor(lume.round(v.x)/15)
            local ey = math.floor(lume.round(v.y)/15)
            local dx = ex - px
            local dy = ey - py
            if math.abs(dx) <= math.floor(w/2) and math.abs(dy) <= math.floor(h/2) then
                love.graphics.rectangle('fill', x + math.floor(w/2) + dx, y + math.floor(h/2) + dy, 1, 1)
            end
        end
    end

    -- local player
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle('fill', x + math.floor(w/2), y + math.floor(h/2), 1, 1)

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
