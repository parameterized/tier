
chat = {
    log = {},
    active = false,
    val = '',
    lastMsgTime = -1
}

function chat.addMsg(v)
    table.insert(chat.log, v)
    chat.lastMsgTime = gameTime
end

function chat.submit()
    if chat.val ~= '' then
        client.sendMessage(chat.val)
        chat.lastMsgTime = gameTime
    end
    chat.val = ''
    chat.active = false
end

function chat.textinput(t)
    chat.val = chat.val .. t
end

function chat.keypressed(k, scancode, isrepeat)
    if chat.active then
        if k == 'escape' then
            chat.val = ''
            chat.active = false
        elseif k == 'return' and not isrepeat then
            chat.submit()
        elseif k == 'backspace' then
            chat.val = chat.val:sub(0, math.max(chat.val:len()-1, 0))
        elseif k == 'v' and (love.keyboard.isScancodeDown('lctrl') or love.keyboard.isScancodeDown('rctrl')) then
            local paste = love.system.getClipboardText()
            chat.val = chat.val .. paste
        end
    elseif hud.chatPanel.open then
        if k == 'escape' then
            hud.chatPanel.open = false
        end
    end
end

function chat.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.c17)
    local startIdx = math.max(#chat.log - 10 + 1, 1)
    local numMsgs = #chat.log - startIdx + 1
    local cpy = hud.chatPanel.y
    for i=1, numMsgs do
        local v = chat.log[startIdx + (i-1)]
        local y = cpy + 118 - (numMsgs - (i-1) + 1)*10 + 8
        text.printSmall(v, 14, y)
    end
    local txt = chat.val
    if chat.active then
        txt = txt .. (time % 1 < 0.5 and '' or '|')
    end
    text.printSmall(txt, 14, cpy + 118)
end
