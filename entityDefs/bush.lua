
local base = require 'entityDefs._base'
local bush = {
    server = base.server:new(),
    client = base.client:new()
}

for _, sc in ipairs{'server', 'client'} do
    bush[sc].newDefaults = function()
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

    bush[sc].type = 'bush'
end



function bush.client:draw()
    local img = gfx.environment.bush
    vx, vy = lume.round(self.x), lume.round(self.y)
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



return bush
