
damageText = {
    container = {}
}

function damageText.reset()
    damageText.container = {}
end

-- t = {v=_, x=_, y=_}
function damageText.add(t)
    if t.v == nil then t.v = 0 end
    if t.x == nil then t.x = 0 end
    if t.y == nil then t.y = 0 end
    t.v = tostring(t.v)
    t.timer = 1
    table.insert(damageText.container, t)
end

function damageText.update(dt)
    for k, v in pairs(damageText.container) do
        v.timer = v.timer - dt*0.5
        if v.timer < 0 then
            damageText.container[k] = nil
        end
    end
end

function damageText.draw()
    local font = fonts.stats
    love.graphics.setFont(font)
    for _, v in pairs(damageText.container) do
        local t = ease.outCubic(1 - v.timer)
        local y = v.y - t*8
        love.graphics.setColor(1, 0, 0, 1 - t)
        love.graphics.print(v.v, lume.round(v.x - font:getWidth(v.v)/2), lume.round(y - font:getHeight()/2))
    end
end
