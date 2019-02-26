
hud = {}

hud.panels = {}
hud.buttons = {}

hud.inventorySlots = {}
table.insert(hud.inventorySlots, {type = 'head',      x = 34, y = 10, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'weapon',    x = 12, y = 32, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'chest',     x = 34, y = 32, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'secondary', x = 56, y = 32, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'accessory', x = 12, y = 53, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'legs',      x = 34, y = 53, w = 15, h = 15})
table.insert(hud.inventorySlots, {type = 'accessory', x = 56, y = 53, w = 15, h = 15})
for j=1, 2 do
    for i=1, 4 do
        table.insert(hud.inventorySlots, {
            x = 7 + (i-1)*18,
            y = 79 + (j-1)*18,
            w = 15,
            h = 15
        })
    end
end

function hud.addPanel(t)
    local defaults = {
        openPos = {x=0, y=0},
        closedPos = {x=0, y=0},
        img = gfx.hud.panels.chat,
        open = true,
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    if t.timer == nil then t.timer = t.open and 0 or 1 end
    if t.open then
        t.x = t.openPos.x
        t.y = t.openPos.y
    else
        t.x = t.closedPos.x
        t.y = t.closedPos.y
    end
    if not t.update then
        t.update = function(self, dt)
            if self.open then
                self.timer = lume.clamp(self.timer - 3*dt, 0, 1)
            else
                self.timer = lume.clamp(self.timer + 3*dt, 0, 1)
            end
            local t = ease.inOutCubic(self.timer)
            self.x = lume.lerp(self.openPos.x, self.closedPos.x, t)
            self.y = lume.lerp(self.openPos.y, self.closedPos.y, t)
        end
    end
    table.insert(hud.panels, t)
    return t
end

function hud.addButton(t)
    local defaults = {
        x = 0, y = 0,
        img = gfx.ui.buttons.down
        -- panel, action, draw nil
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    if t.panel then
        t.panelOffset = {
            x = t.x - t.panel.x,
            y = t.y - t.panel.y
        }
        if not t.update then
            t.update = function(self, dt)
                self.x = self.panel.x + self.panelOffset.x
                self.y = self.panel.y + self.panelOffset.y
            end
        end
    end
    table.insert(hud.buttons, t)
    return t
end

function hud.load()
    hud.mapPanel = hud.addPanel{
        img = gfx.hud.panels.map, openPos={x=392, y=13}, closedPos={x=473, y=13}
    }
    hud.mapButton = hud.addButton{
        img=gfx.ui.buttons.right, x=388, y=28, panel=hud.mapPanel,
        action = function(self)
            self.panel.open = not self.panel.open
            self.img = self.panel.open and gfx.ui.buttons.right or gfx.ui.buttons.left
        end
    }

    hud.chatPanel = hud.addPanel{
        img=gfx.hud.panels.chat, openPos={x=6, y=136}, closedPos={x=6, y=270}
    }
    hud.addButton{
        img=gfx.hud.buttons.chat, x=16, y=235,
        update = function(self, dt)
            local t = ease.inOutCubic(hud.chatPanel.timer)
            self.y = lume.lerp(132, 235, t)
        end,
        action = function(self)
            hud.chatPanel.open = not hud.chatPanel.open
            if not hud.chatPanel.open then
                chat.active = false
            end
        end,
        draw = function(self, mx, my)
            love.graphics.setColor(1, 1, 1)
            local t = gameTime - chat.lastMsgTime
            if t < 1 then
                local c = (math.cos(t*2*math.pi)+3)/4
                love.graphics.setColor(c, c, 1)
            end
            if mx > self.x and mx < self.x + self.img:getWidth() and my > self.y and my < self.y + self.img:getHeight() then
                cursor.cursor = cursor.hand
                local r, g, b = love.graphics.getColor()
                love.graphics.setColor(r*0.8, g*0.8, b*0.8)
            end
            love.graphics.draw(self.img, lume.round(self.x), lume.round(self.y))
        end
    }
    hud.addButton{
        img=gfx.hud.buttons.chatField, x=11, y=253, panel=hud.chatPanel, id='chatField',
        action = function(self)
            chat.active = true
        end
    }
    hud.chatPanel.open = false -- attaching chatField while open
    hud.chatPanel.timer = 1

    hud.statsPanel = hud.addPanel{
        img=gfx.hud.panels.stats, openPos={x=160, y=170}, closedPos={x=160, y=241}, open=false
    }
    hud.addButton{
        img=gfx.hud.buttons.stats, x=175, y=236, panel=hud.statsPanel,
        action = function(self)
            self.panel.open = not self.panel.open
        end
    }
    hud.addButton{
        img=gfx.hud.buttons.backpack, x=287, y=236, panel=hud.statsPanel
    }

    hud.inventoryPanel = hud.addPanel{
        img=gfx.hud.panels.inventory, openPos={x=378, y=144}, closedPos={x=473, y=144}
    }
    hud.inventoryButton = hud.addButton{
        img=gfx.ui.buttons.right, x=374, y=178, panel=hud.inventoryPanel,
        action = function(self)
            self.panel.open = not self.panel.open
            self.img = self.panel.open and gfx.ui.buttons.right or gfx.ui.buttons.left
        end
    }
end

function hud.update(dt)
    for _, v in pairs(hud.panels) do
        if v.update then v.update(v, dt) end
    end
    for _, v in pairs(hud.buttons) do
        if v.update then v.update(v, dt) end
    end
end

function hud.mousepressed(x, y, btn, isTouch, presses)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)

    -- deactivate chat if click outside field
    local chatFieldPressed = false
    for _, v in pairs(hud.buttons) do
        if mx > v.x and mx < v.x + v.img:getWidth() and my > v.y and my < v.y + v.img:getHeight() then
            if v.action then v.action(v) end
            uiMouseDown = true
            if v.id == 'chatField' then chatFieldPressed = true end
        end
    end
    if chat.active and not chatFieldPressed then
        chat.active = false
    end
end

function hud.mousereleased(x, y, btn, isTouch, presses)
    local mx, my = window2game(x, y)
    mx, my = lume.round(mx), lume.round(my)
end

function hud.keypressed(k, scancode, isrepeat)
    if scancode == 'tab' then
        hud.inventoryPanel.open = not hud.inventoryPanel.open
        hud.inventoryButton.img = hud.inventoryPanel.open and gfx.ui.buttons.right or gfx.ui.buttons.left
    end
    if k == 'm' then
        hud.mapPanel.open = not hud.mapPanel.open
        hud.mapButton.img = hud.mapPanel.open and gfx.ui.buttons.right or gfx.ui.buttons.left
    elseif k == 'l' then
        hud.statsPanel.open = not hud.statsPanel.open
    end
end

function hud.draw()
    local _canvas = love.graphics.getCanvas()
    local _shader = love.graphics.getShader()

    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)

    local p = playerController.player

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(gfx.hud.frame, 0, 0)

    -- hp/mana
    love.graphics.setShader(shaders.lifemana)
    shaders.lifemana:send('hp', p.hp/p.hpMax)
    shaders.lifemana:send('mana', 1)
    love.graphics.rectangle('fill', 11, 18, 131, 25)
    love.graphics.setShader(_shader)

    clientRealm.world:drawMap('mini')

    -- panels/buttons
    love.graphics.setColor(1, 1, 1)
    for _, v in pairs(hud.panels) do
        love.graphics.draw(v.img, lume.round(v.x), lume.round(v.y))
    end
    for _, v in pairs(hud.buttons) do
        if v.draw then
            v.draw(v, mx, my)
        else
            love.graphics.setColor(1, 1, 1)
            if mx > v.x and mx < v.x + v.img:getWidth() and my > v.y and my < v.y + v.img:getHeight() then
                cursor.cursor = cursor.hand
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.draw(v.img, lume.round(v.x), lume.round(v.y))
        end
    end

    -- level bar
    local l = p.xp2level(p.xp)
    local x, y = hud.statsPanel.x, hud.statsPanel.y
    love.graphics.setColor(221/255, 217/255, 0)
    local t = l - math.floor(l)
    love.graphics.rectangle('fill', 191, lume.round(y + 20), t*99, 3)

    love.graphics.setColor(1, 1, 1)
    local font = fonts.c17
    love.graphics.setFont(font)
    local level = tostring(math.floor(l))
    text.print(level, lume.round(240 - font:getWidth(level)/2), lume.round(y))

    -- stats
    local font = fonts.stats
    love.graphics.setFont(font)
    local stats_x, stats_y = 202, 227
    local stats_dx, stats_dy = 20, 11
    for j, row in ipairs{'base', 'arm', 'total'} do
        local c = ({
            {255/255, 175/255, 48/255},
            {255/255, 84/255, 252/255},
            {48/255, 255/255, 241/255}
        })[j]
        love.graphics.setColor(c)
        for i, col in ipairs{'vit', 'atk', 'spd', 'wis', 'def', 'reg'} do
            local sx = stats_x + stats_dx*(i-1)
            local sy = stats_y + stats_dy*(j-1)
            sx = x + (sx - hud.statsPanel.openPos.x)
            sy = y + (sy - hud.statsPanel.openPos.y)
            local txt = tostring(p.stats[col][row])
            text.print(txt, lume.round(sx - font:getWidth(txt)/2), lume.round(sy - font:getHeight()/2))
        end
    end

    love.graphics.setCanvas(canvases.tempGame)
    love.graphics.clear()
    local hpHovered = mx > 39 and mx < 141 and my > 23 and my < 31
    local txt = string.format('%i / %i', p.hp, p.hpMax)
    love.graphics.setColor(0, 0, 0)
    text.print(txt, lume.round(90 - font:getWidth(txt)/2 - 1), lume.round(27 - font:getHeight()/2 + 1))
    love.graphics.setColor(1, 1, 1)
    text.print(txt, lume.round(90 - font:getWidth(txt)/2), lume.round(27 - font:getHeight()/2))
    love.graphics.setCanvas(_canvas)
    if hpHovered then
        love.graphics.setColor(1, 1, 1, 0.8)
    else
        love.graphics.setColor(1, 1, 1, 0.4)
    end
    love.graphics.draw(canvases.tempGame, 0, 0)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.c17)
    text.print(p.name, 44, 5)

    -- inventory items
    love.graphics.push()
    local panel = hud.inventoryPanel
    love.graphics.translate(panel.x, panel.y)
    local pmx = mx - lume.round(panel.x)
    local pmy = my - lume.round(panel.y)
    for slotId, slot in ipairs(hud.inventorySlots) do
        local item = items.client.getItem(p.inventory.items[slotId])
        if pmx >= slot.x and pmx <= slot.x + slot.w
        and pmy >= slot.y and pmy <= slot.y + slot.h and panel.open then
            if item then
                cursor.cursor = cursor.hand
                playerController.hoveredItem = item
            end
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.rectangle('fill', slot.x, slot.y, slot.w, slot.h)
        end
        local heldItem = playerController.heldItem
        if not (heldItem.bagId == 'inventory' and heldItem.slotId == slotId) then
            if item then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(gfx.items[item.imageId], slot.x, slot.y)
            end
        end
    end
    love.graphics.pop()

    -- item info
    local item = playerController.hoveredItem
    if item then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader(shaders.panel)
        local w = 104
        local h = 91
        local x = lume.clamp(mx - w, 0, gsx - w)
        local y = lume.clamp(my - h, 0, gsy - h)
        shaders.panel:send('box', {x, y, w, h})
        love.graphics.rectangle('fill', x, y, w, h)
        love.graphics.setShader(_shader)
        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.draw(gfx.ui.itemInfo, 0, 0)
        font = fonts.stats
        love.graphics.setFont(font)
        local playerWeapon = items.client.getItem(p.inventory.items[2])
        if isSword[item.imageId] and item.atk then
            if playerWeapon and playerWeapon.atk then
                if item.atk < playerWeapon.atk then
                    love.graphics.setColor(1, 0, 0)
                elseif item.atk > playerWeapon.atk then
                    love.graphics.setColor(0, 1, 0)
                end
            end
            text.print(item.atk, 35, 34)
        else
            text.print('100', 35, 34)
        end
        love.graphics.pop()
    end

    -- held item
    local heldItem = playerController.heldItem
    if heldItem.itemId then
        local item = items.client.getItem(heldItem.itemId)
        if item then
            cursor.cursor = cursor.hand
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(gfx.items[item.imageId], mx + heldItem.offset.x, my + heldItem.offset.y)
        end
    end
end
