
client = {}

client.interpolate = true

function client.connect(ip, port)
    port = tonumber(port)
    client.nutClient = nut.client()
    client.nutClient:addRPCs{
        chatMsg = function(self, data)
            chat.addMsg(data)
        end,
        serverClosed = function(self, data)
            -- todo: show message in game
            print('server closed')
            gameState = 'menu'
            menu.state = 'main'
            client.close()
            love.mouse.setGrabbed(false)
        end
    }
    local bitserRPCs = {
        returnPlayer = function(self, data)
            client.startGame(data)
        end,
        add = function(self, data)
            for _, v in pairs(data.projectiles) do
                v.startedMoving = false
                client.currentState.projectiles[v.id] = v
            end
            for _, v in pairs(data.entities) do
                entities.client.defs[v.type]:new(v):spawn()
            end
            for _, v in pairs(data.lootBags) do
                lootBag.client:new(v):spawn()
            end
            for _, v in pairs(data.portals) do
                client.currentState.portals[v.id] = v
            end
        end,
        remove = function(self, data)
            for _, id in pairs(data.projectiles) do
                client.currentState.projectiles[id] = nil
            end
            for _, id in pairs(data.entities) do
                local ent = client.currentState.entities[id]
                if ent then ent:destroy() end
            end
            for _, id in pairs(data.lootBags) do
                local bag = clientRealm.lootBags[id]
                if bag then bag:destroy() end
            end
            for _, id in pairs(data.portals) do
                client.currentState.portals[id] = nil
            end
        end,
        stateUpdate = function(self, data)
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
        end,
        returnItem = function(self, data)
            items.client.container[data.id] = data.item
            items.client.requested[data.id] = nil
        end,
        bagUpdate = function(self, data)
            local bag = clientRealm.lootBags[data.id]
            if bag then
                for k, v in pairs(data) do
                    bag[k] = v
                end
            end
        end,
        setWorldChunk = function(self, data)
            clientRealm.world:setChunk(data.x, data.y, data.chunk)
        end,
        teleportPlayer = function(self, data)
            playerController.player.body:setPosition(data.x, data.y)
        end,
        healPlayer = function(self, data)
            local p = playerController.player
            p.hp = math.min(p.hp + data.hp, p.hpMax)
        end
    }
    for k, v in pairs(bitserRPCs) do
        bitserRPCs[k] = function(self, data)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                v(self, data)
            else
                print('error decoding client rpc ' .. k)
            end
        end
    end
    client.nutClient:addRPCs(bitserRPCs)
    client.nutClient:addUpdate(function(self)
        if gameState == 'playing' then
            self:sendRPC('setPlayer', bitser.dumps(playerController.player:serialize()))
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
        clientRealm:destroy()
        slimeBalls.reset()
        items.client.reset()
        collectgarbage()
    end
    client.currentState = client.newState()

    menu.writeDefaults()

    clientRealm:load()
    playerController.load()
end

function client.newState()
    return {entities={}, projectiles={}, lootBags={}, portals={}}
end

function client.startGame(data)
    playerController.serverId = data.id
    local p = playerController.player
    p.name = data.name
    p:setState(data)
    gameState = 'playing'
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
        client.stateTime = lume.clamp(client.stateTime + dt, cs_3.time, cs_0.time)
        if client.stateTime > cs_1.time then
            --print('lerp down')
            client.stateTime = lume.lerp(client.stateTime, cs_1.time, lume.clamp(dt, 0, 1))
        elseif client.stateTime < cs_2.time then
            --print('lerp up')
            client.stateTime = lume.lerp(client.stateTime, cs_2.time, lume.clamp(dt, 0, 1))
        end
        --debugger.logVal('interpolation delay', client.serverTime - client.stateTime)
        while client.states[client.stateIdx+1] and client.states[client.stateIdx+2]
        and client.states[client.stateIdx+1].time < client.stateTime do
            client.stateIdx = client.stateIdx + 1
            client.states[client.stateIdx-1] = false
        end
        local t = (client.stateTime - client.states[client.stateIdx].time)
            / (client.states[client.stateIdx+1].time - client.states[client.stateIdx].time)
        --t = lume.clamp(t, 0, 1) -- t>1 = prediction
        if not client.interpolate then
            t = 1
        end
        local csi = client.states[client.stateIdx]
        local csi_1 = client.states[client.stateIdx+1]
        for k, v in pairs(csi.projectiles) do
            local v2 = csi_1.projectiles[k]
            if v2 then
                local obj = client.currentState.projectiles[k]
                if obj then
                    obj.x = lume.lerp(v.x, v2.x, t)
                    obj.y = lume.lerp(v.y, v2.y, t)
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

                    if k == playerController.serverId then
                        local p = playerController.player
                        p.xp = obj.xp
                        p.stats = obj.stats
                        p.inventory = obj.inventory
                    end
                end
            end
        end
    end

    if not (server.running and server.paused) then
        gameTime = gameTime + dt
        hud.update(dt)
        clientRealm:update(dt)
        playerController.update(dt)
        entities.client.update(dt)
        slimeBalls.update(dt)
    end
end

function client.sendMessage(msg)
    if client.connected then
        client.nutClient:sendRPC('chatMsg', msg)
    end
end

for _, v in ipairs{'spawnProjectile', 'moveItem', 'dropItem', 'useItem', 'usePortal'} do
    client[v] = function(data)
        client.nutClient:sendRPC(v, bitser.dumps(data))
    end
end

function client.close()
    client.nutClient:close()
    client.connected = false
end
