
cursor = {}

cursor.main = {
    img = gfx.cursors.main,
    ox = 0, oy = 0
}
cursor.hand = {
    img = gfx.cursors.hand,
    ox = 2, oy = 0
}

cursor.cursor = cursor.main

function cursor.draw()
    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(cursor.cursor.img, mx, my, 0, 1, 1, cursor.cursor.ox, cursor.cursor.oy)
end
