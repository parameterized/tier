
menu = {}

menu.state = 'main'
menu.btns = {}
menu.inputs = {}
menu.infos = {}
menu.activeInput = nil
menu.buttonDown = false
menu.logoAnimTimer = 0

function menu.addBtn(t)
    t.state = t.state or 'main'
    t.text = t.text or 'Button'
    t.font = t.font or fonts.c17
    t.type = t.type or 'default'
    t.action = t.action or function() end
    t.x = t.x or 240
    t.y = t.y or 135
    if t.type == 'cycle' then
        t.bw, t.bh = 0, 0
        t.items = t.items or {'<item>'}
        for _, v in pairs(t.items) do
            t.bw = math.max(math.floor(t.font:getWidth(v) + 8), t.bw)
            t.bh = math.max(math.floor(t.font:getHeight() + 4), t.bh)
        end
    else
        t.bw = math.floor(t.font:getWidth(t.text) + 8)
        t.bh = math.floor(t.font:getHeight() + 4)
    end
    t.bx = math.floor(t.x - t.bw/2)
    t.by = math.floor(t.y - t.bh/2)
    if not menu.btns[t.state] then menu.btns[t.state] = {} end
    table.insert(menu.btns[t.state], t)
    return t
end

function menu.addInput(t)
    t.state = t.state or 'main'
    t.text = t.text or 'Input'
    t.font = t.font or fonts.c17
    t.value = t.value or ''
    t.x = t.x or 240
    t.y = t.y or 135
    t.w = math.floor(t.w or 80)
    t.bw = t.w
    t.bh = math.floor(t.font:getHeight() + 4)
    t.bx = math.floor(t.x - t.bw/2)
    t.by = math.floor(t.y - t.bh/2)
    if not menu.inputs[t.state] then menu.inputs[t.state] = {} end
    table.insert(menu.inputs[t.state], t)
    return t
end

function menu.addInfo(t)
    t.state = t.state or 'main'
    t.text = t.text or 'Info'
    t.font = t.font or fonts.c17
    t.x = t.x or 240
    t.y = t.y or 135
    if not menu.infos[t.state] then menu.infos[t.state] = {} end
    table.insert(menu.infos[t.state], t)
    return t
end

function menu.load()
    local menuFactoryDefaults = {
        name = 'Player',
        ip = '127.0.0.1',
        port = '1357',
        resolution = 2,
        fullscreen = 1,
        vsync = true,
        cursorLock = true
    }

    local menuDefaults
    function menu.readDefaults()
        local path = love.filesystem.getRealDirectory('menuDefaults.json') .. '/menuDefaults.json'
        local file = io.open(path, 'rb')
        local content = file:read('*a')
        file:close()
        menuDefaults = json.decode(content)
        for k, v in pairs(menuFactoryDefaults) do
            if menuDefaults[k] == nil then
                menuDefaults[k] = v
            end
        end
    end
    if not pcall(menu.readDefaults) then
        -- write default if not exist or malformed
        local content = json.encode(menuFactoryDefaults)
        love.filesystem.write('menuDefaults.json', content)
        menu.readDefaults()
    end

    function menu.writeDefaults()
        local content = json.encode{
            name = menu.nameInput.value,
            ip = menu.ipInput.value,
            port = menu.portInput.value,
            resolution = menu.resolutionBtn.active,
            fullscreen = menu.fullscreenBtn.active,
            vsync = menu.vsyncBtn.active,
            cursorLock = menu.cursorLockBtn.active
        }
        love.filesystem.write('menuDefaults.json', content)
    end

    local exitY = 220
    local h = 40
    menu.addBtn{text='Play', y=exitY - h*2.5, action = function()
        menu.state = 'play'
    end}
    menu.addBtn{text='Options', y=exitY - h*1.5, action=function()
        menu.state = 'options'
    end}
    menu.addBtn{text='Exit', y=exitY, action = function()
        love.event.quit()
    end}

    menu.nameInput = menu.addInput{state='play', text='Player Name', value=menuDefaults.name, x=gsx/2 - 70, y=exitY - h*2}
    menu.addBtn{state='play', text='Singleplayer', x=gsx/2 - 70, y=exitY - h*1, action=function()
        chat.log = {}
        -- todo: choose open port
        -- remove whitespace
        local port = menu.portInput.value:gsub("%s+", "")
        server.start(port, true)
        client.connect('127.0.0.1', port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.ipInput = menu.addInput{state='play', text='IP', value=menuDefaults.ip, x=gsx/2 + 70, y=exitY - h*3}
    menu.portInput = menu.addInput{state='play', text='Port', value=menuDefaults.port, x=gsx/2 + 70, y=exitY - h*2}
    menu.addBtn{state='play', text='Host', x=gsx/2 + 70 - 25, y=exitY - h*1, action=function()
        chat.log = {}
        -- todo: notify if not open or other err
        local port = menu.portInput.value:gsub("%s+", "")
        server.start(port)
        client.connect('127.0.0.1', port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.addBtn{state='play', text='Join', x=gsx/2 + 70 + 25, y=exitY - h*1, action=function()
        chat.log = {}
        local ip = menu.ipInput.value:gsub("%s+", "")
        local port = menu.portInput.value:gsub("%s+", "")
        client.connect(ip, port)
        menu.state = 'connect'
        menu.connectInfo.text = 'Starting Game'
    end}
    menu.addBtn{state='play', text='Back', y=exitY, action=function()
        menu.state = 'main'
    end}

    menu.connectInfo = menu.addInfo{state='connect', text='[connection info]', y=gsy/2}
    menu.addBtn{state='connect', text='Cancel', y=exitY, action=function()
        menu.state = 'play'
        if server.running then
            server.close()
        end
        if client.connected then
            client.close()
        end
    end}

    menu.resolutionBtn = menu.addBtn{state='options', text='Resolution', y=exitY - h*4,
    type='cycle', items={'960x540', '1440x810', '1920x1080'},
    active=menuDefaults.resolution, action=function(v)
        local fullscreen, fstype = love.window.getFullscreen()
        if not (fullscreen and fstype == 'desktop') then
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
            love.graphics.setColor(0.3, 0.3, 0.3)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        local fullscreen, fstype = love.window.getFullscreen()
        if fullscreen and fstype == 'desktop' then
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(v.font)
        text.print(v.text, math.floor(v.x - v.font:getWidth(v.text)/2), math.floor(v.by - v.font:getHeight()))
        love.graphics.setColor(1, 1, 1)
        local txt = v.items[v.active]
        if fullscreen and fstype == 'desktop' then
            local w, h = love.graphics.getDimensions()
            txt = w .. 'x' .. h
        end
        text.print(txt, math.floor(v.x - v.font:getWidth(txt)/2), math.floor(v.y - v.font:getHeight()/2))
    end}
    menu.fullscreenBtn = menu.addBtn{state='options', text='Fullscreen', y=exitY - h*3,
    type='cycle', items={'Windowed', 'Borderless Fullscreen Windowed', 'Fullscreen'},
    active=menuDefaults.fullscreen, action=function(v)
        if v == 'Windowed' then
            love.window.setFullscreen(false)
            local w, h = love.graphics.getDimensions()
            love.resize(w, h)
        elseif v == 'Borderless Fullscreen Windowed' then
            love.window.setFullscreen(true, 'desktop')
            local w, h = love.graphics.getDimensions()
            love.resize(w, h)
        elseif v == 'Fullscreen' then
            love.window.setFullscreen(true, 'exclusive')
            local w, h = love.graphics.getDimensions()
            love.resize(w, h)
        end
    end}
    menu.vsyncBtn = menu.addBtn{state='options', text='Vsync', y=exitY - h*2.2, type='toggle',
    active=menuDefaults.vsync, action=function(v)
        local w, h, flags = love.window.getMode()
        flags.vsync = v
        love.window.setMode(w, h, flags)
    end}
    menu.cursorLockBtn = menu.addBtn{state='options', text='Cursor Lock', y=exitY - h*1.4, type='toggle', active=menuDefaults.cursorLock}
    menu.addBtn{state='options', text='Back', y=exitY, action=function()
        menu.state = 'main'
    end}

    -- apply options (block-local vars)
    repeat
        local w, h, flags = love.window.getMode()
        local vsyncOn = flags.vsync
        flags.vsync = menuDefaults.vsync

        local fullscreen, fstype = love.window.getFullscreen()
        local newResolution = menu.resolutionBtn.items[menuDefaults.resolution]
        if not (fullscreen and fstype == 'desktop')
        and newResolution ~= string.format('%sx%s', w, h) then
            w, h = newResolution:match('(%d+)x(%d+)')
            local wd, hd = love.window.getDesktopDimensions()
            flags.x = wd/2 - w/2
            flags.y = hd/2 - h/2
            love.window.setMode(w, h, flags)
            love.resize(w, h)
        elseif vsyncOn ~= menuDefaults.vsync then
            love.window.setMode(w, h, flags)
        end

        local currentWindowType = love.window.getFullscreen()
        local newWindowType = menu.fullscreenBtn.items[menuDefaults.fullscreen]
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
    until true
end

function menu.update(dt)
    menu.logoAnimTimer = menu.logoAnimTimer + dt
end

function menu.mousepressed(mx, my, btn)
    mx, my = screen2game(mx, my)
    if gameState == 'menu' then
        menu.activeInput = nil
        for _, v in pairs(menu.btns[menu.state] or {}) do
            if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
                if v.type == 'toggle' then
                    v.active = not v.active
                    v.action(v.active)
                elseif v.type == 'cycle' then
                    v.active = ((v.active - 1 + (btn == 2 and -1 or 1)) % #v.items) + 1
                    v.action(v.items[v.active])
                else
                    v.action()
                end
                menu.buttonDown = true
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
    menu.buttonDown = false
end

function menu.textinput(t)
    if gameState == 'menu' then
        if menu.activeInput then
            menu.activeInput.value = menu.activeInput.value .. t
        end
    end
end

function menu.keypressed(k, scancode, isrepeat)
    if gameState == 'menu' then
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
        elseif menu.state == 'options' then
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
end

function menu.draw()
    if gameState == 'menu' then
        local mx, my = screen2game(love.mouse.getPosition())

        if menu.state == 'main' then
            love.graphics.setColor(1, 1, 1)
            local logoFrameIdx = math.floor(menu.logoAnimTimer*12) % #anims.logo.quads + 1
            local quad = anims.logo.quads[logoFrameIdx]
            love.graphics.draw(gfx.logoAnim, quad, math.floor(gsx/2 - gfx.logo:getWidth()/2), 12)
        end
        for _, v in pairs(menu.btns[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh then
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
                    text.print(v.text, math.floor(v.x - v.font:getWidth(v.text)/2), math.floor(v.by - v.font:getHeight()))
                    txt = v.items[v.active]
                end
                love.graphics.setColor(1, 1, 1)
                text.print(txt, math.floor(v.x - v.font:getWidth(txt)/2), math.floor(v.y - v.font:getHeight()/2))
            end
        end
        for _, v in pairs(menu.inputs[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                if mx > v.bx and mx < v.bx + v.bw and my > v.by and my < v.by + v.bh
                and (menu.activeInput == v or menu.activeInput == nil) or menu.activeInput == v then
                    love.graphics.setColor(0.3, 0.3, 0.3)
                else
                    love.graphics.setColor(0.6, 0.6, 0.6)
                end
                love.graphics.rectangle('fill', v.bx, v.by, v.bw, v.bh)
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.setFont(v.font)
                text.print(v.text, math.floor(v.x - v.font:getWidth(v.text)/2), math.floor(v.by - v.font:getHeight()))
                txt = v.value
                if menu.activeInput == v then txt = txt .. (time % 1 < 0.5 and '' or '|') end
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(v.font)
                text.print(txt, math.floor(v.x - v.font:getWidth(txt)/2), math.floor(v.y - v.font:getHeight()/2))
            end
        end
        for _, v in pairs(menu.infos[menu.state] or {}) do
            if v.draw then
                v.draw(v, mx, my)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(v.font)
                text.print(v.text, math.floor(v.x - v.font:getWidth(v.text)/2), math.floor(v.y - v.font:getHeight()/2))
            end
        end
    end
end
