
local base = require 'entityDefs._base'
local bigRock = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    bigRock[sc].newDefaults = function()
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

    bigRock[sc].spawn = function(self)
        self.body = love.physics.newBody(self.realm.physics.world, self.x, self.y, 'static')
        self.polys = {
            {0.075, 0.05, 0.875, 0.05, 0.975, 0.15, 0.025, 0.15}
        }
        -- transform - todo: load from file already transformed
        local img = gfx.environment.bigRock
        for _, v in pairs(self.polys) do
            for i2, v2 in pairs(v) do
                if (i2-1) % 2 == 0 then -- x
                    v[i2] = v2*img:getWidth() - img:getWidth()/2
                else
                    v[i2] = v2*img:getWidth()*-1
                end
            end
        end
        self.shapes = {}
        self.fixtures = {}
        for _, v in pairs(self.polys) do
            local shape = love.physics.newPolygonShape(unpack(v))
            table.insert(self.shapes, shape)
            local fixture = love.physics.newFixture(self.body, shape, 1)
            table.insert(self.fixtures, fixture)
            fixture:setUserData(self)
            fixture:setCategory(4)
        end
        return self.base.spawn(self)
    end

    bigRock[sc].destroy = function(self)
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

    bigRock[sc].type = 'bigRock'
end



function bigRock.client:draw()
    local img = gfx.environment.bigRock
    local vx, vy = self.body:getPosition()
    vx, vy = lume.round(vx), lume.round(vy)
    local p = playerController.player
    local px, py = lume.round(p.x), lume.round(p.y)
    local pdx = px - vx
    local pdy = py - vy
    local a = 1
    if math.abs(px - vx) < lume.round(img:getWidth()/2) and pdy > -img:getHeight() and pdy < 0 then
        a = 0.5
    end
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.push()
    love.graphics.translate(vx, vy)
    love.graphics.draw(img, 0, 0, 0, 1, 1, lume.round(img:getWidth()/2), img:getHeight())
    love.graphics.pop()
end



return bigRock
