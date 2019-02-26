
-- todo: better sword check
isSword = {}
for _, v in ipairs{'sword0', 'sword1', 'sword2', 'sword3', 'sword4'} do
    isSword[v] = true
end
sword2color = {
    sword0 = {192/255, 192/255, 192/255},
    sword1 = {114/255, 114/255, 114/255},
    sword2 = {166/255, 97/255, 56/255},
    sword3 = {238/255, 50/255, 255/255},
    sword4 = {255/255, 255/255, 50/255}
}
slot2type = {'helmet', 'sword', 'chest', 'shield', 'accessory', 'pants', 'accessory'}
tile2id = {}
for i, v in ipairs{'water', 'sand', 'grass', 'rock', 'path', 'floor', 'wall', 'platform', 'platform2'} do
    tile2id[v] = i
end

-- todo: enemy inheritance
function serverEnemyDamage(self, d, clientId)
    self.hp = self.hp - d
    if self.hp <= 0 and not self.destroyed then
        sound.play('scream')
        server.addXP(clientId, math.random(3, 5))
        local bagItems = {}
        local choices = {
            none=20, apple=10, helmet=16, chest=16, pants=16, shield=5,
            sword0=4, sword1=4, sword2=3, sword3=3, sword4=3
        }
        for _=1, 3 do
            choice = lume.weightedchoice(choices)
            if choice ~= 'none' then
                local itemData = {imageId=choice}
                if choice == 'sword0' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+10))
                elseif choice =='sword1' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+12))
                elseif choice =='sword2' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+14))
                elseif choice =='sword3' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+16))
                elseif choice =='sword4' then
                    itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+18))
                end
                local itemId = items.server.newItem(itemData)
                table.insert(bagItems, itemId)
            end
        end
        local numItems = #bagItems
        if numItems ~= 0 then
            local type = lume.randomchoice{'lootBag', 'lootBag1', 'lootBagFuse'}
            lootBag.server:new{
                realm = serverRealm,
                x = self.x, y = self.y,
                items = bagItems,
                type = type,
                life = 30
            }:spawn()
        end
        --if math.random() < 0.5 then portals.server.spawn{x=self.x, y=self.y, life=10} end
        self:destroy()
    else
        sound.play('spider')
    end
end

-- window to game canvas
function window2game(x, y)
	x = x - (ssx-gameScale*gsx)/2
	x = x / gameScale
	y = y - (ssy-gameScale*gsy)/2
	y = y / gameScale
	return x, y
end

function setGameCanvas2x()
    local _shader = love.graphics.getShader()
    local _color = {love.graphics.getColor()}
    love.graphics.setShader()
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.draw(canvases.game, 0, 0, 0, 2, 2)
    love.graphics.pop()
    love.graphics.setCanvas(canvases.game)
    love.graphics.setBlendMode('alpha')
    love.graphics.clear()
    love.graphics.setCanvas(canvases.game2x)
    love.graphics.setShader(_shader)
    love.graphics.setColor(_color)
end
