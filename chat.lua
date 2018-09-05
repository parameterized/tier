
chat = {
    log = {},
    active = false,
    val = '',
    lastMsgTime = 0
}

function chat.addMsg(v)
    table.insert(chat.log, v)
    chat.lastMsgTime = gameTime
end

function chat.submit()
    if chat.val ~= '' then
        client.sendMessage(chat.val)
    end
    chat.val = ''
    chat.active = false
end

function chat.textinput(t)
    chat.val = chat.val .. t
end

function chat.keypressed(k, scancode, isrepeat)
    if k == 'return' and not isrepeat then
        chat.submit()
    elseif k == 'backspace' then
        chat.val = chat.val:sub(0, math.max(chat.val:len()-1, 0))
    elseif k == 'escape' then
        chat.val = ''
        chat.active = false
    elseif k == 'v' and (love.keyboard.isScancodeDown('lctrl') or love.keyboard.isScancodeDown('rctrl')) then
        local paste = love.system.getClipboardText()
        chat.val = chat.val .. paste
    end
end

function chat.draw()
    if gameTime - chat.lastMsgTime < 4 or chat.active then
        local a = 1
        if not chat.active and gameTime - chat.lastMsgTime > 3 then
            a = 4 - (gameTime - chat.lastMsgTime)
        end
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.setFont(fonts.c17)
        local startIdx = math.max(#chat.log - (chat.active and 12 or 6) + 1, 1)
        local numMsgs = #chat.log - startIdx + 1
        for i=1, numMsgs do
            local v = chat.log[startIdx + (i-1)]
            local y = gsy - (numMsgs - (i-1) + 1)*10 - 3
            text.printSmall(v, 3, y)
        end
    end
    if chat.active then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', 1, gsy - 12, 100, 11)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.c17)
        text.printSmall(chat.val, 3, gsy - 11)
    end
end
