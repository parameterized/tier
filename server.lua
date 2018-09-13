
server = {}

function server.start(port, singleplayer)
    port = tonumber(port)
    server.singleplayer = singleplayer
    server.paused = false
    local connectionLimit = server.singleplayer and 1 or nil
    server.nutServer = nut.server{port=port, connectionLimit=connectionLimit}
    server.nutServer:addRPCs{
        disconnect = function(self, data, clientId)
            local pname = server.currentState.players[clientId].name
            if not server.singleplayer then
                self:sendRPC('chatMsg', string.format('Server: %s disconnected', pname))
            end
            server.removePlayer(clientId)

            self.clients[clientId] = nil
            nut.log(clientId .. ' disconnected')
        end,
        requestPlayer = function(self, data, clientId)
            local postfix = 0
            local reservedNames = {}
            for _, v in pairs{'Server', 'server'} do reservedNames[v] = true end
            while server.playerNames[buildName(data, postfix)]
            or reservedNames[buildName(data, postfix)] do
                postfix = postfix + 1
            end
            -- send current state to new player
            local add = server.newState()
            for k, t in pairs(server.currentState) do -- 'players', 'projectiles'
                for _, v in pairs(t) do
                    if not server.added[k][v.id] then
                        add[k][v.id] = v
                    end
                end
            end
            self:sendRPC('add', json.encode(add), clientId)
            server.addPlayer(buildName(data, postfix), clientId)
        end,
        chatMsg = function(self, data, clientId)
            local pname = server.currentState.players[clientId].name
            self:sendRPC('chatMsg', string.format('%s: %s', pname, data))
        end,
        setPlayer = function(self, data, clientId)
            local ok, data = pcall(json.decode, data)
            if ok then
                if not server.currentState.players[clientId] then
                    print('attempt to setPlayer on non-existent player')
                    return
                end
                for _, v in pairs{'x', 'y'} do
                    server.currentState.players[clientId][v] = data[v]
                end
            else
                print('error decoding server rpc setPlayer')
            end
        end,
        spawnProjectile = function(self, data, clientId)
            local ok, data = pcall(json.decode, data)
            if ok then
                local playerId = server.currentState.players[clientId].id
                data.playerId = playerId
                projectiles.server.spawn(data)
            else
                print('error decoding server rpc spawnBullet')
            end
        end
    }
    server.nutServer:addUpdate(function(self)
        local addStr = json.encode(server.added)
        if addStr ~= json.encode(server.newState()) then
            self:sendRPC('add', addStr)
        end
        server.added = server.newState()
        local removeStr = json.encode(server.removed)
        if removeStr ~= json.encode(server.newState()) then
            self:sendRPC('remove', removeStr)
        end
        server.removed = server.newState()
        local stateUpdate = server.newState()
        stateUpdate.time = gameTime
        for _, v in pairs(server.currentState.players) do
            -- don't send clientIds - index by uuid
            -- todo: don't send xp/stats in update
            stateUpdate.players[v.id] = v
        end
        for _, v in pairs(server.currentState.projectiles) do
            stateUpdate.projectiles[v.id] = v
        end
        for _, v in pairs(server.currentState.entities) do
            -- don't update static entities
            if not entities.server.defs[v.type].static then
                stateUpdate.entities[v.id] = v
            end
        end
        -- no lootBags updates
        self:sendRPC('stateUpdate', json.encode(stateUpdate))
    end)
    server.nutServer:start()
    server.running = true
    if not server.singleplayer then
        chat.addMsg('server started')
    end

    server.playerNames = {}
    server.uuid2clientId = {}
    -- added[type][id] = obj
    -- removed[type] = {id1, id2, ...}
    server.added = server.newState()
    server.removed = server.newState()
    -- cleanup previous game
    if server.currentState then
        entities.server.reset()
        projectiles.server.reset()
    end
    server.currentState = server.newState()

    physics.server.load()
    entities.server.load()
end

function server.newState()
    return {players={}, projectiles={}, entities={}, lootBags={}}
end

function server.addPlayer(name, clientId)
    local p = {
        id = uuid(), name = name,
        x = (math.random()*2-1)*128, y = (math.random()*2-1)*128,
        xp = 0, stats = player.newStats()
    }
    server.currentState.players[clientId] = p
    server.playerNames[name] = true
    server.uuid2clientId[p.id] = clientId
    server.added.players[p.id] = p
    server.nutServer:sendRPC('returnPlayer', json.encode(p), clientId)
    if not server.singleplayer then
        server.nutServer:sendRPC('chatMsg', p.name .. ' connected')
    end
end

function server.removePlayer(clientId)
    local p = server.currentState.players[clientId]
    server.removed.players[p.id] = p.id
    server.uuid2clientId[p.id] = nil
    server.playerNames[p.name] = nil
    server.currentState.players[clientId] = nil
end

function server.addXP(playerId, xp)
    local clientId = server.uuid2clientId[playerId]
    if clientId then
        local p = server.currentState.players[clientId]
        if p then
            local _l = player.xp2level(p.xp)
            p.xp = p.xp + xp
            local l = player.xp2level(p.xp)
            if math.floor(_l) ~= math.floor(l) then -- level increased
                p.stats.vit.base = math.floor(l*10 + 100)
                p.stats.atk.base = math.floor(l*8 + 80)
                p.stats.spd.base = math.floor(l*5 + 50)
                p.stats.wis.base = math.floor(l*8 + 100)
                p.stats.def.base = math.floor(l*4 + 20)
                p.stats.reg.base = math.floor(l*6 + 50)
                for _, v in pairs(p.stats) do
                    v.total = v.base + v.arm
                end
            end
        else
            print('player not found in server.addXP()')
        end
    else
        print('clientId not found in server.addXP()')
    end
end

function server.update(dt)
    server.nutServer:update(dt)

    if not server.paused then
        physics.server.update(dt)
        projectiles.server.update(dt)
        entities.server.update(dt)
        lootBags.server.update(dt)
    end
end

function server.close()
    server.nutServer:sendRPC('serverClosed')
    server.nutServer:close()
    server.running = false
end
