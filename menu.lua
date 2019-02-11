
menu = {}

function menu.addButton(t)
    local defaults = {
        state = 'main',
        text = 'Button',
        font = fonts.c17,
        type = 'default',
        x = 480/2,
        y = 270/2
        -- active, action nil
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    if t.type == 'cycle' then
        t.bw, t.bh = 0, 0
        t.items = t.items or {'<item>'}
        for _, v in pairs(t.items) do
            t.bw = math.max(lume.round(t.font:getWidth(v) + 8), t.bw)
            t.bh = math.max(lume.round(t.font:getHeight() + 4), t.bh)
        end
    else
        t.bw = lume.round(t.font:getWidth(t.text) + 8)
        t.bh = lume.round(t.font:getHeight() + 4)
    end
    t.bx = lume.round(t.x - t.bw/2)
    t.by = lume.round(t.y - t.bh/2)
    if not menu.buttons[t.state] then menu.buttons[t.state] = {} end
    table.insert(menu.buttons[t.state], t)
    return t
end

function menu.addSlider(t)
    local defaults = {
        state = 'main',
        text = 'Slider',
        font = fonts.c17,
        value = 0.5,
        x = 480/2,
        y = 270/2,
        w = 80
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    t.w = lume.round(t.w)
    t.bw = t.w
    t.bh = lume.round(t.font:getHeight() + 4)
    t.bx = lume.round(t.x - t.bw/2)
    t.by = lume.round(t.y - t.bh/2)
    if not menu.sliders[t.state] then menu.sliders[t.state] = {} end
    table.insert(menu.sliders[t.state], t)
    return t
end

function menu.addInput(t)
    local defaults = {
        state = 'main',
        text = 'Input',
        font = fonts.c17,
        value = '',
        x = 480/2,
        y = 270/2,
        w = 80
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    t.w = lume.round(t.w)
    t.bw = t.w
    t.bh = lume.round(t.font:getHeight() + 4)
    t.bx = lume.round(t.x - t.bw/2)
    t.by = lume.round(t.y - t.bh/2)
    if not menu.inputs[t.state] then menu.inputs[t.state] = {} end
    table.insert(menu.inputs[t.state], t)
    return t
end

function menu.addInfo(t)
    local defaults = {
        state = 'main',
        text = 'Info',
        font = fonts.c17,
        x = 480/2,
        y = 270/2
    }
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    if not menu.infos[t.state] then menu.infos[t.state] = {} end
    table.insert(menu.infos[t.state], t)
    return t
end

menu.factoryDefaults = {
    name = 'Player',
    ip = '127.0.0.1',
    port = '1357',
    resolution = 1,
    fullscreen = 1,
    vsync = false,
    cursorLock = false,
    masterVolume = 0.4
}

-- mutable defaults
function menu.readDefaults()
    local path = love.filesystem.getRealDirectory('menuDefaults.json') .. '/menuDefaults.json'
    local file = io.open(path, 'rb')
    local content = file:read('*a')
    file:close()
    menu.defaults = json.decode(content)
    for k, v in pairs(menu.factoryDefaults) do
        if menu.defaults[k] == nil then
            menu.defaults[k] = v
        end
    end
end

function menu.writeDefaults()
    local content = json.encode{
        name = menu.nameInput.value,
        ip = menu.ipInput.value,
        port = menu.portInput.value,
        resolution = menu.resolutionBtn.active,
        fullscreen = menu.fullscreenBtn.active,
        vsync = menu.vsyncBtn.active,
        cursorLock = menu.cursorLockBtn.active,
        masterVolume = menu.masterVolumeSlider.value
    }
    love.filesystem.write('menuDefaults.json', content)
end

function menu.applyOptions()
    local w, h, flags = love.window.getMode()
    local vsyncOn = flags.vsync ~= 0
    flags.vsync = menu.vsyncBtn.active and 1 or 0

    local fullscreen, fstype = love.window.getFullscreen()
    local newResolution = menu.resolutionBtn.items[menu.resolutionBtn.active]
    if not (fullscreen and fstype == 'desktop')
    and newResolution ~= string.format('%sx%s', w, h) then
        w, h = newResolution:match('(%d+)x(%d+)')
        local wd, hd = love.window.getDesktopDimensions()
        flags.x = wd/2 - w/2
        flags.y = hd/2 - h/2
        love.window.setMode(w, h, flags)
        love.resize(w, h)
    elseif vsyncOn ~= menu.defaults.vsync then
        love.window.setMode(w, h, flags)
    end

    local currentWindowType = love.window.getFullscreen()
    local newWindowType = menu.fullscreenBtn.items[menu.fullscreenBtn.active]
    if newWindowType == 'Windowed'
    and currentWindowType ~= 'Windowed' then
        love.window.setFullscreen(false)
        w, h = love.graphics.getDimensions()
        love.resize(w, h)
    elseif newWindowType == 'Borderless Fullscreen Windowed'
    and currentWindowType ~= 'Borderless Fullscreen Windowed' then
        love.window.setFullscreen(true, 'desktop')
        w, h = love.graphics.getDimensions()
        love.resize(w, h)
    elseif newWindowType == 'Fullscreen'
    and currentWindowType ~= 'Fullscreen' then
        love.window.setFullscreen(true, 'exclusive')
        w, h = love.graphics.getDimensions()
        love.resize(w, h)
    end

    love.audio.setVolume(menu.masterVolumeSlider.value)
end

function menu.load()
    menu.state = 'main'
    menu.buttons = {}
    menu.sliders = {}
    menu.inputs = {}
    menu.infos = {}
    menu.activeInput = nil
    menu.logoAnimTimer = 0

    if not pcall(menu.readDefaults) then
        -- write default if not exist or malformed
        local content = json.encode(menu.factoryDefaults)
        love.filesystem.write('menuDefaults.json', content)
        menu.readDefaults()
    end

    -- main menu
    local exitY = 220
    local h = 40
    menu.addButton{text='Play', y=exitY - h*2.5, action = function()
        sound.play('select')
        menu.state = 'play'
    end}
    menu.addButton{text='Options', y=exitY - h*1.5, action=function()
        sound.play('select')
        menu.state = 'options_video'
    end}
    menu.addButton{text='Exit', y=exitY, action = function()
        love.event.quit()
    end}

    -- play menu
    menu.nameInput = menu.addInput{state='play', text='Player Name', value=menu.defaults.name, x=gsx/2 - 70, y=exitY - h*2}
    menu.addButton{state='play', text='Singleplayer', x=gsx/2 - 70, y=exitY - h*1, action=function()
        sound.play('select')
        chat.log = {}
        server.start(nil, true)
        client.connect('127.0.0.1', server.nutServer.port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.ipInput = menu.addInput{state='play', text='IP', value=menu.defaults.ip, x=gsx/2 + 70, y=exitY - h*3}
    menu.portInput = menu.addInput{state='play', text='Port', value=menu.defaults.port, x=gsx/2 + 70, y=exitY - h*2}
    menu.addButton{state='play', text='Host', x=gsx/2 + 70 - 25, y=exitY - h*1, action=function()
        sound.play('select')
        chat.log = {}
        -- todo: notify if not open or other err
        -- remove whitespace
        local port = menu.portInput.value:gsub("%s+", "")
        server.start(port)
        client.connect('127.0.0.1', port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.addButton{state='play', text='Join', x=gsx/2 + 70 + 25, y=exitY - h*1, action=function()
        sound.play('select')
        chat.log = {}
        local ip = menu.ipInput.value:gsub("%s+", "")
        local port = menu.portInput.value:gsub("%s+", "")
        client.connect(ip, port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.addButton{state='play', text='Back', y=exitY, action=function()
        sound.play('select2')
        menu.state = 'main'
    end}

    -- connecting screen
    menu.connectInfo = menu.addInfo{state='connect', text='[connection info]', y=gsy/2}
    menu.addButton{state='connect', text='Cancel', y=exitY, action=function()
        sound.play('select2')
        menu.state = 'play'
        if server.running then
            server.close()
        end
        if client.connected then
            client.close()
        end
    end}

    -- options menu - video
    menu.addButton{state='options_video', text='Video', x=40, y=20, action=function()
        sound.play('select')
        menu.state = 'options_video'
    end}
    menu.addButton{state='options_video', text='Audio', x=100, y=20, action=function()
        sound.play('select')
        menu.state = 'options_audio'
    end}
    menu.resolutionBtn = menu.addButton{state='options_video', text='Resolution', y=exitY - h*4,
    type='cycle', items={'960x540', '1440x810', '1920x1080'},
    active=menu.defaults.resolution, action=function(v)
        sound.play('select')
        local fullscreen, fstype = love.window.getFullscreen()
        if not fullscreen then
            local w, h, flags = love.window.getMode()
            w, h = v:match('(%d+)x(%d+)')
            local wd, hd = love.window.getDesktopDimensions()
            flags.x = wd/2 - w/2
            flags.y = hd/2 - h/2
            love.window.setMode(w, h, flags)
            love.resize(w, h)
        end
    end, draw=function(v, mx, my)
        if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
            cursor.cursor = cursor.hand
            love.graphics.setColor(0.3, 0.3, 0.3)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        local fullscreen, fstype = love.window.getFullscreen()
        if fullscreen then
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(v.font)
        text.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.by - v.font:getHeight()))
        love.graphics.setColor(1, 1, 1)
        local txt = v.items[v.active]
        if fullscreen then
            local w, h = love.graphics.getDimensions()
            txt = w .. 'x' .. h
        end
        text.print(txt, lume.round(v.x - v.font:getWidth(txt)/2), lume.round(v.y - v.font:getHeight()/2))
    end}
    menu.fullscreenBtn = menu.addButton{state='options_video', text='Fullscreen', y=exitY - h*3,
    type='cycle', items={'Windowed', 'Borderless Fullscreen Windowed', 'Fullscreen'},
    active=menu.defaults.fullscreen, action=function(v)
        sound.play('select')
        if v == 'Windowed' then
            local w, h, flags = love.window.getMode()
            local rb = menu.resolutionBtn
            w, h = rb.items[rb.active]:match('(%d+)x(%d+)')
            flags.fullscreen = false
            flags.fullscreentype = 'desktop'
            love.window.setMode(w, h, flags)
            love.resize(w, h)
            local dw, dh = love.window.getDesktopDimensions(flags.display)
            love.window.setPosition(lume.round(dw/2 - w/2), lume.round(dh/2 - h/2))
        elseif v == 'Borderless Fullscreen Windowed' then
            local w, h, flags = love.window.getMode()
            w, h = love.window.getDesktopDimensions(flags.display)
            flags.fullscreen = true
            flags.fullscreentype = 'desktop'
            love.window.setMode(w, h, flags)
            love.resize(w, h)
        elseif v == 'Fullscreen' then
            local w, h, flags = love.window.getMode()
            w, h = love.window.getDesktopDimensions(flags.display)
            flags.fullscreen = true
            flags.fullscreentype = 'exclusive'
            love.window.setMode(w, h, flags)
            love.resize(w, h)
        end
    end}
    menu.vsyncBtn = menu.addButton{state='options_video', text='Vsync', y=exitY - h*2.2, type='toggle',
    active=menu.defaults.vsync, action=function(v)
        sound.play('select')
        local w, h, flags = love.window.getMode()
        flags.vsync = v and 1 or 0
        love.window.setMode(w, h, flags)
    end}
    menu.cursorLockBtn = menu.addButton{state='options_video', text='Cursor Lock', y=exitY - h*1.4, type='toggle',
    active=menu.defaults.cursorLock, action=function(v)
        sound.play('select')
    end}
    menu.addButton{state='options_video', text='Back', y=exitY, action=function()
        sound.play('select2')
        menu.state = 'main'
    end}
    menu.addButton{state='options_video', text='Load Defaults', x=400, y=exitY, action=function()
        sound.play('select')
        local content = json.encode(menu.factoryDefaults)
        love.filesystem.write('menuDefaults.json', content)
        menu.load()
        menu.state = 'options_video'
    end}

    -- options menu - audio
    menu.addButton{state='options_audio', text='Video', x=40, y=20, action=function()
        sound.play('select')
        menu.state = 'options_video'
    end}
    menu.addButton{state='options_audio', text='Audio', x=100, y=20, action=function()
        sound.play('select')
        menu.state = 'options_audio'
    end}
    menu.masterVolumeSlider = menu.addSlider{state='options_audio', text='Master Volume',
    w=120, value=menu.defaults.masterVolume, action=function(v)
        sound.play('select')
        love.audio.setVolume(v)
    end}
    menu.addButton{state='options_audio', text='Back', y=exitY, action=function()
        sound.play('select2')
        menu.state = 'main'
    end}
    menu.addButton{state='options_audio', text='Load Defaults', x=400, y=exitY, action=function()
        sound.play('select')
        local content = json.encode(menu.factoryDefaults)
        love.filesystem.write('menuDefaults.json', content)
        menu.load()
        menu.state = 'options_audio'
    end}

    menu.applyOptions()
end

function menu.update(dt)
    menu.logoAnimTimer = menu.logoAnimTimer + dt

    local mx, my = window2game(love.mouse.getPosition())
    mx, my = lume.round(mx), lume.round(my)
    if love.mouse.isDown(1) then
        for _, v in pairs(menu.sliders[menu.state] or {}) do
            if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                v.value = (mx - v.bx)/v.bw
                if v.action then v.action(v.value) end
                uiMouseDown = true
                return
            end
        end
    end
end

function menu.mousepressed(mx, my, btn)
    mx, my = window2game(mx, my)
    mx, my = lume.round(mx), lume.round(my)
    if gameState == 'menu' then
        menu.activeInput = nil
        for _, v in pairs(menu.buttons[menu.state] or {}) do
            if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                if v.type == 'toggle' then
                    v.active = not v.active
                    if v.action then v.action(v.active) end
                elseif v.type == 'cycle' then
                    v.active = ((v.active - 1 + (btn == 2 and -1 or 1)) % #v.items) + 1
                    if v.action then v.action(v.items[v.active]) end
                else
                    if v.action then v.action() end
                end
                uiMouseDown = true
                return
            end
        end
        for _, v in pairs(menu.inputs[menu.state] or {}) do
            if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                menu.activeInput = v
                return
            end
        end
    end
end

function menu.mousereleased(mx, my, btn)

end

function menu.textinput(t)
    if gameState == 'menu' then
        if menu.activeInput then
            menu.activeInput.value = menu.activeInput.value .. t
        end
    end
end

function menu.keypressed(k, scancode, isrepeat)
    if menu.state == 'play' then
        if k == 'escape' and not isrepeat then
            menu.state = 'main'
            menu.activeInput = nil
        end
    elseif menu.state == 'connect' then
        if k == 'escape' and not isrepeat then
            menu.state = 'play'
            menu.activeInput = nil
        end
    elseif menu.state == 'options_video' or menu.state == 'options_audio' then
        if k == 'escape' and not isrepeat then
            menu.state = 'main'
            menu.activeInput = nil
        end
    end
    if menu.activeInput then
        if k == 'return' and not isrepeat then
            menu.activeInput = nil
        elseif k == 'backspace' then
            menu.activeInput.value = menu.activeInput.value:sub(0, math.max(menu.activeInput.value:len()-1, 0))
        elseif k == 'v' and (love.keyboard.isScancodeDown('lctrl') or love.keyboard.isScancodeDown('rctrl')) then
            local paste = love.system.getClipboardText()
            for v in paste:gmatch('.') do
                -- todo: filter for input type (numerical ports etc)
                menu.activeInput.value = menu.activeInput.value .. v
            end
        end
    end
end

function menu.draw()
    if gameState == 'menu' then
        local mx, my = window2game(love.mouse.getPosition())
        mx, my = lume.round(mx), lume.round(my)
        if menu.state == 'main' then
            love.graphics.setColor(1, 1, 1)
            local logoFrameIdx = math.floor(menu.logoAnimTimer*12) % #anims.logo.quads + 1
            local quad = anims.logo.quads[logoFrameIdx]
            love.graphics.draw(gfx.logoAnim, quad, lume.round(gsx/2 - gfx.logo:getWidth()/2), 12)
        end
        for _, v in pairs(menu.buttons[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                    cursor.cursor = cursor.hand
                    love.graphics.setColor(0.3, 0.3, 0.3)
                else
                    if v.type == 'toggle' and v.active then
                        love.graphics.setColor(0.25, 0.25, 0.25)
                    else
                        love.graphics.setColor(0.4, 0.4, 0.4)
                    end
                end
                love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
                local txt = v.text
                love.graphics.setFont(v.font)
                if v.type == 'cycle' then
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    text.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.by - v.font:getHeight()))
                    txt = v.items[v.active]
                end
                love.graphics.setColor(1, 1, 1)
                text.print(txt, lume.round(v.x - v.font:getWidth(txt)/2), lume.round(v.y - v.font:getHeight()/2))
            end
        end
        for _, v in pairs(menu.sliders[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                    love.graphics.setColor(0.3, 0.3, 0.3)
                    love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
                    love.graphics.setColor(0.4, 0.4, 0.4)
                    love.graphics.rectangle('fill', v.bx, v.by, v.bw*v.value, v.bh)
                else
                    love.graphics.setColor(0.4, 0.4, 0.4)
                    love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.rectangle('fill', v.bx, v.by, v.bw*v.value, v.bh)
                end
                local txt = v.text
                love.graphics.setFont(v.font)
                love.graphics.setColor(0.8, 0.8, 0.8)
                text.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.by - v.font:getHeight()))
            end
        end
        for _, v in pairs(menu.inputs[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                    cursor.cursor = cursor.hand
                    if (menu.activeInput == v or menu.activeInput == nil) or menu.activeInput == v then
                        love.graphics.setColor(0.3, 0.3, 0.3)
                    end
                else
                    love.graphics.setColor(0.6, 0.6, 0.6)
                end
                love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.setFont(v.font)
                text.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.by - v.font:getHeight()))
                local txt = v.value
                if menu.activeInput == v then txt = txt .. (time % 1 < 0.5 and '' or '|') end
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(v.font)
                text.print(txt, lume.round(v.x - v.font:getWidth(txt)/2), lume.round(v.y - v.font:getHeight()/2))
            end
        end
        for _, v in pairs(menu.infos[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(v.font)
                text.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.y - v.font:getHeight()/2))
            end
        end
    end
end
