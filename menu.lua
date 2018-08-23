
menu = {}

menu.state = 'main'
menu.btns = {}

function menu.addBtn(t)
    t.state = t.state or 'main'
    t.text = t.text or 'Button'
    t.font = t.font or fonts.f12
    t.action = t.action or function() end
    t.x = t.x or gsx/2
    t.y = t.y or gsy/2
    t.bw = math.floor(t.font:getWidth(t.text)) + 8
    t.bh = math.floor(t.font:getHeight()) + 4
    t.bx = math.floor(t.x - t.bw/2)
    t.by = math.floor(t.y - t.bh/2)
    if not menu.btns[t.state] then menu.btns[t.state] = {} end
    table.insert(menu.btns[t.state], t)
end

menu.addBtn{text='Play', y=math.floor(gsy/2), action = function()
    gameState = 'playing'
end}

function menu.mousepressed(mx, my, btn)
    mx, my = screen2game(mx, my)
    if gameState == 'menu' then
        for _, v in pairs(menu.btns[menu.state] or {}) do
            if mx > v.bx and my < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                v.action()
                return
            end
        end
    end
end

function menu.draw()
    if gameState == 'menu' then
        local mx, my = screen2game(love.mouse.getPosition())
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(gfx.logo, math.floor(gsx/2 - gfx.logo:getWidth()/2), 12)
        for _, v in pairs(menu.btns[menu.state] or {}) do
            if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                love.graphics.setColor(0.3, 0.3, 0.3)
            else
                love.graphics.setColor(0.4, 0.4, 0.4)
            end
            love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.setFont(v.font)
            love.graphics.setShader(shaders.fontAlias)
            love.graphics.print(v.text, math.floor(v.x - v.font:getWidth(v.text)/2), math.floor(v.y - v.font:getHeight()/2))
            love.graphics.setShader()
        end
    end
end
