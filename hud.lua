
hud = {}

hud.panels = {}
hud.buttons = {}
hud.buttonDown = false

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
                self.timer = clamp(self.timer - 3*dt, 0, 1)
            else
                self.timer = clamp(self.timer + 3*dt, 0, 1)
            end
            local t = ease.inOutCubic(self.timer)
            self.x = lerp(self.openPos.x, self.closedPos.x, t)
            self.y = lerp(self.openPos.y, self.closedPos.y, t)
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
    hud.addButton{
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
            self.y = lerp(132, 235, t)
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
                local r, g, b = love.graphics.getColor()
                love.graphics.setColor(r*0.8, g*0.8, b*0.8)
            end
            love.graphics.draw(self.img, math.floor(self.x), math.floor(self.y))
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

    hud.invPanel = hud.addPanel{
        img=gfx.hud.panels.inventory, openPos={x=378, y=144}, closedPos={x=470, y=144}
    }
    hud.addButton{
        img=gfx.ui.buttons.right, x=373, y=178, panel=hud.invPanel,
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

function hud.mousepressed(mx, my, btn)
    mx, my = screen2game(mx, my)
    local chatFieldPressed = false
    for _, v in pairs(hud.buttons) do
        if mx > v.x and mx < v.x + v.img:getWidth() and my > v.y and my < v.y + v.img:getHeight() then
            if v.action then v.action(v) end
            hud.buttonDown = true
            if v.id == 'chatField' then chatFieldPressed = true end
        end
    end
    if chat.active and not chatFieldPressed then
        chat.active = false
    end
end

function hud.mousereleased(mx, my, btn)
    mx, my = screen2game(mx, my)
    hud.buttonDown = false
end

function hud.draw()
    local mx, my = screen2game(love.mouse.getPosition())

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(gfx.hud.frame, 0, 0)
    love.graphics.draw(gfx.hud.lifemana, 11, 18)

    love.graphics.setColor(48/255, 102/255, 57/255)
    local x = hud.mapPanel.x + 7
    local y = hud.mapPanel.y + 8
    love.graphics.rectangle('fill', x, y, 60, 62)

    love.graphics.setColor(1, 1, 1)
    for _, v in pairs(hud.panels) do
        love.graphics.draw(v.img, math.floor(v.x), math.floor(v.y))
    end
    for _, v in pairs(hud.buttons) do
        if v.draw then
            v.draw(v, mx, my)
        else
            love.graphics.setColor(1, 1, 1)
            if mx > v.x and mx < v.x + v.img:getWidth() and my > v.y and my < v.y + v.img:getHeight() then
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.draw(v.img, math.floor(v.x), math.floor(v.y))
        end
    end

    local l = player.xp2level(player.xp)
    x, y = hud.statsPanel.x, hud.statsPanel.y
    love.graphics.setColor(221/255, 217/255, 0)
    local t = l - math.floor(l)
    love.graphics.rectangle('fill', 191, math.floor(y + 20), t*99, 3)

    love.graphics.setColor(1, 1, 1)
    local font = fonts.c17
    love.graphics.setFont(font)
    local level = tostring(math.floor(l))
    love.graphics.print(level, math.floor(240 - font:getWidth(level)/2), math.floor(y))

    font = fonts.stats
    love.graphics.setFont(font)
    local stats_x, stats_y = 202, 227
    local stats_dx, stats_dy = 20, 11
    for j, row in pairs{'base', 'arm', 'total'} do
        local c = ({
            {255/255, 175/255, 48/255},
            {255/255, 84/255, 252/255},
            {48/255, 255/255, 241/255}
        })[j]
        love.graphics.setColor(c)
        for i, col in pairs{'vit', 'atk', 'spd', 'wis', 'def', 'reg'} do
            local sx = stats_x + stats_dx*(i-1)
            local sy = stats_y + stats_dy*(j-1)
            sx = x + (sx - hud.statsPanel.openPos.x)
            sy = y + (sy - hud.statsPanel.openPos.y)
            local txt = tostring(player.stats[col][row])
            love.graphics.print(txt, math.floor(sx - font:getWidth(txt)/2), math.floor(sy - font:getHeight()/2))
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.c17)
    text.print(player.name, 44, 5)
end
