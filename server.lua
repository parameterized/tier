
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
            for _, v in pairs(server.currentState.players) do
                table.insert(add.players, v)
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
            stateUpdate.players[v.id] = v
        end
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
    -- todo: cleanup previous game
    server.currentState = server.newState()
end

function server.newState()
    return {players={}, bullets={}, entities={}}
end

function server.addPlayer(name, clientId)
    local p = {
        id = uuid(), name = name,
        x = (math.random()*2-1)*128, y = (math.random()*2-1)*128,
    }
    server.currentState.players[clientId] = p
    server.playerNames[name] = true
    server.uuid2clientId[p.id] = clientId
    table.insert(server.added.players, p)
    server.nutServer:sendRPC('returnPlayer', json.encode(p), clientId)
    if not server.singleplayer then
        server.nutServer:sendRPC('chatMsg', p.name .. ' connected')
    end
end

function server.removePlayer(clientId)
    local p = server.currentState.players[clientId]
    table.insert(server.removed.players, p.id)
    server.uuid2clientId[p.id] = nil
    server.playerNames[p.name] = nil
    server.currentState.players[clientId] = nil
end

function server.update(dt)
    server.nutServer:update(dt)
end

function server.close()
    server.nutServer:sendRPC('serverClosed')
    server.nutServer:close()
    server.running = false
end
