
local base = require 'entityDefs._base'
local questBlock = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    questBlock[sc].newDefaults = function()
        local t = {
            id = lume.uuid(),
            x = 0, y = 0
        }
        if sc == 'server' then
            t.base = base.server
            t.realm = serverRealm
        elseif sc == 'client' then
            t.base = base.client
            t.realm = clientRealm
        end
        return t
    end

    questBlock[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'static')
        self.shapes = {}
        self.fixtures = {}
        local shape = love.physics.newRectangleShape(15/2, 15/2, 15, 15)
        table.insert(self.shapes, shape)
        local fixture = love.physics.newFixture(self.body, shape, 1)
        table.insert(self.fixtures, fixture)
        fixture:setUserData(self)
        fixture:setCategory(4)
        return self.base.spawn(self)
    end

    questBlock[sc].destroy = function(self)
        if self.fixtures then
            for _, v in pairs(self.fixtures) do
                if not v:isDestroyed() then v:destroy() end
            end
        end
        if self.body and not self.body:isDestroyed() then
            self.body:destroy()
        end
        self.base.destroy(self)
    end

    questBlock[sc].type = 'questBlock'
end



function questBlock.client:draw()
    local _shader = love.graphics.getShader()
    local img = gfx.environment.questBlock
    local vx, vy = self.body:getPosition()
    vx, vy = lume.round(vx), lume.round(vy)
    local p = playerController.player
    local px, py = lume.round(p.x), lume.round(p.y)
    local pdx = px - (vx + 8)
    local pdy = py - (vy + 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders.outline)
    shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
    if math.abs(pdx) < playerController.interactRange
    and math.abs(pdy) < playerController.interactRange then
        shaders.outline:send('outlineColor', {0.8, 0.8, 0.8, 1})
    else
        shaders.outline:send('outlineColor', {0, 0, 0, 1})
    end
    love.graphics.push()
    love.graphics.translate(vx, vy)
    love.graphics.draw(img, 0, 0, 0, 1, 1,
        2, img:getHeight() - 17)
    love.graphics.pop()
    love.graphics.setShader(_shader)
end



return questBlock
