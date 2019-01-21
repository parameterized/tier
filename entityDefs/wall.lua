
local base = require 'entityDefs._base'
local wall = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    wall[sc].newDefaults = function()
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

    wall[sc].spawn = function(self)
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

    wall[sc].destroy = function(self)
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

    wall[sc].type = 'wall'
end



function wall.client:draw()
    local _shader = love.graphics.getShader()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders.outline)
    local img = gfx.environment.wall
    shaders.outline:send('stepSize', {1/img:getWidth(), 1/img:getHeight()})
    shaders.outline:send('outlineColor', {0, 0, 0, 1})
    love.graphics.push()
    local vx, vy = self.body:getPosition()
    love.graphics.translate(lume.round(vx), lume.round(vy))
    love.graphics.draw(img, 0, 0, 0, 1, 1,
        2, img:getHeight() - 17)
    love.graphics.pop()
    love.graphics.setShader(_shader)
end



return wall
