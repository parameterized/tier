
client = {}

client.interpolate = true

function client.connect(ip, port)
    port = tonumber(port)
    client.nutClient = nut.client()
    client.nutClient:addRPCs{
        returnPlayer = function(self, data)
            local ok, data = pcall(json.decode, data)
            if ok then
                client.startGame(data)
            else
                print('error decoding client rpc returnPlayer')
            end
        end,
        chatMsg = function(self, data)
            chat.addMsg(data)
        end,
        serverClosed = function(self, data)
            -- todo: show message in game
            print('server closed')
            gameState = 'menu'
            menu.state = 'main'
            client.close()
            love.mouse.setVisible(true)
            love.mouse.setGrabbed(false)
        end,
        add = function(self, data)
            local ok, data = pcall(json.decode, data)
            if ok then
                for _, v in pairs(data.players) do
                    v.body = love.physics.newBody(physics.client.world, v.x, v.y, 'dynamic')
                    v.shape = love.physics.newRectangleShape(50, 50)
                    v.fixture = love.physics.newFixture(v.body, v.shape, 1)
                    if v.id == player.id then
                        v.fixture:setUserData{type='serverPlayer'}
                    else
                        v.fixture:setUserData{type='otherPlayer'}
                    end
                    v.fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
                    v.body:setFixedRotation(true)
                    client.currentState.players[v.id] = v
                end
                for _, v in pairs(data.projectiles) do
                    v.startedMoving = false
                    client.currentState.projectiles[v.id] = v
                end
                for _, v in pairs(data.entities) do
                    local ent = entities.client.defs[v.type]:new(v):spawn()
                    client.currentState.entities[ent.id] = ent
                end
                for _, v in pairs(data.lootBags) do
                    client.currentState.lootBags[v.id] = v
                end
            else
                print('error decoding client rpc add')
            end
        end,
        remove = function(self, data)
            local ok, data = pcall(json.decode, data)
            if ok then
                for _, id in pairs(data.players) do
                    if id ~= player.id then
                        local p = client.currentState.players[id]
                        if p then
                            p.fixture:destroy()
                            p.body:destroy()
                        end
                        client.currentState.players[id] = nil
                    else
                        print('server tried to remove local player')
                    end
                end
                for _, id in pairs(data.projectiles) do
                    client.currentState.projectiles[id] = nil
                end
                for _, id in pairs(data.entities) do
                    local ent = client.currentState.entities[id]
                    if ent then ent:destroy() end
                    client.currentState.entities[id] = nil
                end
                for _, id in pairs(data.lootBags) do
                    client.currentState.lootBags[id] = nil
                end
            else
                print('error decoding client rpc remove')
            end
        end,
        stateUpdate = function(self, data)
            local ok, data = pcall(json.decode, data)
            if ok then
                client.serverTime = data.time
                -- todo: delete old states (or make replay feature)
                -- todo: multiple states in update -
                -- - 20fps update -> 60fps replay, (3 states per update)
                table.insert(client.states, data)
                --[[
                if #client.states == 2 then
                    client.stateTime = client.states[1].time
                end
                ]]
            else
                print('error decoding client rpc stateUpdate')
            end
        end
    }
    client.nutClient:addUpdate(function(self)
        if gameState == 'playing' then
            self:sendRPC('setPlayer', json.encode(player.serialize()))
        end
    end)
    client.nutClient:connect(ip, port)
    client.connected = true
    client.nutClient:sendRPC('requestPlayer', menu.nameInput.value)

    client.serverTime = 0
    client.states = {}
    client.stateIdx = 1
    client.stateTime = 0
    -- cleanup previous connection
    if client.currentState then
        entities.client.reset()
        player.destroy()
        for _, v in pairs(client.currentState.players) do
            v.fixture:destroy()
            v.body:destroy()
        end
        collectgarbage()
    end
    client.currentState = client.newState()

    menu.writeDefaults()

    physics.client.load()
    player.load()
end

function client.newState()
    return {players={}, projectiles={}, entities={}, lootBags={}}
end

function client.startGame(p)
    player.id = p.id
    player.name = p.name
    player.body:setPosition(p.x, p.y)
    gameState = 'playing'
    love.mouse.setVisible(false)
    if menu.cursorLockBtn.active then love.mouse.setGrabbed(true) end
end

function client.update(dt)
    client.nutClient:update(dt)
    if not (server.running and server.paused) then
        client.serverTime = client.serverTime + dt
    end
    -- interpolate states
    local cs_0 = client.states[#client.states]
    local cs_1 = client.states[#client.states-1]
    local cs_2 = client.states[#client.states-2]
    local cs_3 = client.states[#client.states-3]
    if cs_0 and cs_1 and cs_2 and cs_3 then
        -- todo: better interpolation with less delay -
        -- - no vsync on server seems to lessen jitter - threading probably will too
        --[[
        if client.stateTime >= cs_0.time then
            print('clamp down ' .. math.abs(client.stateTime - cs_0.time))
        elseif client.stateTime <= cs_3.time then
            print('clamp up ' .. math.abs(client.stateTime - cs_3.time))
        end
        ]]
        client.stateTime = clamp(client.stateTime + dt, cs_3.time, cs_0.time)
        if client.stateTime > cs_1.time then
            --print('lerp down')
            client.stateTime = lerp(client.stateTime, cs_1.time, clamp(dt, 0, 1))
        elseif client.stateTime < cs_2.time then
            --print('lerp up')
            client.stateTime = lerp(client.stateTime, cs_2.time, clamp(dt, 0, 1))
        end
        --debugger.logVal('interpolation delay', client.serverTime - client.stateTime)
        while client.states[client.stateIdx+1] and client.states[client.stateIdx+2]
        and client.states[client.stateIdx+1].time < client.stateTime do
            client.stateIdx = client.stateIdx + 1
        end
        local t = (client.stateTime - client.states[client.stateIdx].time)
            / (client.states[client.stateIdx+1].time - client.states[client.stateIdx].time)
        --t = clamp(t, 0, 1) -- t>1 = prediction
        if not client.interpolate then
            t = 1
        end
        local csi = client.states[client.stateIdx]
        local csi_1 = client.states[client.stateIdx+1]
        for k, v in pairs(csi.players) do
            local v2 = csi_1.players[k]
            if v2 then
                local obj = client.currentState.players[k]
                if obj then
                    obj.x = lerp(v.x, v2.x, t)
                    obj.y = lerp(v.y, v2.y, t)

                    obj.body:setPosition(obj.x, obj.y)
                end
            end
        end
        for k, v in pairs(csi.projectiles) do
            local v2 = csi_1.projectiles[k]
            if v2 then
                local obj = client.currentState.projectiles[k]
                if obj then
                    obj.x = lerp(v.x, v2.x, t)
                    obj.y = lerp(v.y, v2.y, t)
                    obj.startedMoving = true
                end
            end
        end
        for k, v in pairs(csi.entities) do
            local v2 = csi_1.entities[k]
            if v2 then
                local obj = client.currentState.entities[k]
                if obj then
                    if not entities.client.defs[obj.type].static then
                        obj:lerpState(v, v2, t)
                    end
                end
            end
        end
    end

    if not (server.running and server.paused) then
        gameTime = gameTime + dt
        hud.update(dt)
        physics.client.update(dt)
        world.update(dt)
        player.update(dt)
        entities.client.update(dt)
    end
end

function client.sendMessage(msg)
    if client.connected then
        client.nutClient:sendRPC('chatMsg', msg)
    end
end

function client.spawnProjectile(data)
    if client.connected then
        client.nutClient:sendRPC('spawnProjectile', json.encode(data))
    end
end

function client.close()
    client.nutClient:close()
    client.connected = false
end
