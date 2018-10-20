
server = {}

function server.start(port, singleplayer)
    if type(port) == 'string' then port = tonumber(port) end
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
            for k, t in pairs(server.currentState) do
                if k ~= 'players' then
                    for _, v in pairs(t) do
                        if not server.added[k][v.id] then
                            add[k][v.id] = v
                        end
                    end
                end
            end
            self:sendRPC('add', bitser.dumps(add), clientId)
            server.addPlayer(buildName(data, postfix), clientId)
        end,
        chatMsg = function(self, data, clientId)
            local pname = server.currentState.players[clientId].name
            self:sendRPC('chatMsg', string.format('%s: %s', pname, data))
        end,
        setPlayer = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                if not server.currentState.players[clientId] then
                    print('attempt to setPlayer on non-existent player')
                    return
                end
                server.currentState.players[clientId]:setState(data)
            else
                print('error decoding server rpc setPlayer')
            end
        end,
        spawnProjectile = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                local playerId = server.currentState.players[clientId].id
                data.playerId = playerId
                projectiles.server.spawn(data)
            else
                print('error decoding server rpc spawnBullet')
            end
        end,
        getItem = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                local res = {id=data.id, item=items.server.getItem(data.id)}
                server.nutServer:sendRPC('returnItem', bitser.dumps(res))
            else
                print('error decoding server rpc getItem')
            end
        end,
        moveItem = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                -- todo: validation
                local p = server.currentState.players[clientId]
                local bagFrom = server.currentState.lootBags[data.from.bagId]
                if data.from.bagId == 'inventory' then
                    bagFrom = p.inventory
                end
                local bagTo = server.currentState.lootBags[data.to.bagId]
                if data.to.bagId == 'inventory' then
                    bagTo = p.inventory
                end
                if bagFrom and bagTo then
                    if bagFrom.items[data.from.slotId] then
                        local temp = bagTo.items[data.to.slotId]
                        bagTo.items[data.to.slotId] = bagFrom.items[data.from.slotId]
                        bagFrom.items[data.from.slotId] = temp
                        -- remove bag if empty
                        if bagFrom.id ~= 'inventory' then
                            local empty = true
                            for _, v in pairs(bagFrom.items) do
                                if v ~= nil then
                                    empty = false
                                    break
                                end
                            end
                            if empty then
                                lootBags.server.destroy(bagFrom.id)
                            end
                        end
                        -- inventory sent in player update
                        if data.from.bagId ~= 'inventory' then
                            server.nutServer:sendRPC('bagUpdate', bitser.dumps(bagFrom))
                        end
                        if data.to.bagId ~= 'inventory' then
                            server.nutServer:sendRPC('bagUpdate', bitser.dumps(bagTo))
                        end
                    end
                end
            else
                print('error decoding server rpc moveItem')
            end
        end,
        dropItem = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                local p = server.currentState.players[clientId]
                local item = p.inventory.items[data.slotId]
                if item then
                    local itemDropped = false
                    local bags = {}
                    for _, bag in pairs(lootBags.server.container) do
                        table.insert(bags, bag)
                    end
                    local sortedBags = isort(bags, function(a, b)
                        local da = (a.x - p.x)^2 + (a.y - p.y)^2
                        local db = (b.x - p.x)^2 + (b.y - p.y)^2
                        return da < db
                    end)
                    for _, bag in ipairs(sortedBags) do
                        local dist = math.sqrt((bag.x - p.x)^2 + (bag.y - p.y)^2)
                        if dist < lootBags.client.openRange then
                            for bagSlotId, _ in ipairs(lootBags.client.slots) do
                                if bag.items[bagSlotId] == nil then
                                    bag.items[bagSlotId] = item
                                    server.nutServer:sendRPC('bagUpdate', bitser.dumps(bag))
                                    itemDropped = true
                                    break
                                end
                            end
                        end
                        if itemDropped then break end
                    end
                    if not itemDropped then
                        lootBags.server.spawn{
                            x = p.x, y = p.y,
                            items = {item},
                            life = 30
                        }
                        itemDropped = true
                    end
                    p.inventory.items[data.slotId] = nil
                    -- inventory sent in player update
                end
            else
                print('error decoding server rpc dropItem')
            end
        end,
        getWorldChunk = function(self, data, clientId)
            local ok, data = pcall(bitser.loads, data)
            if ok then
                local chunk = world.server.getChunk(data.x, data.y)
                local res = {x=data.x, y=data.y, chunk=chunk}
                server.nutServer:sendRPC('setWorldChunk', bitser.dumps(res), clientId)
            else
                print('error decoding server rpc getWorldChunk')
            end
        end
    }
    server.nutServer:addUpdate(function(self)
        local addStr = bitser.dumps(server.added)
        if addStr ~= bitser.dumps(server.newState()) then
            self:sendRPC('add', addStr)
        end
        server.added = server.newState()
        local removeStr = bitser.dumps(server.removed)
        if removeStr ~= bitser.dumps(server.newState()) then
            self:sendRPC('remove', removeStr)
        end
        server.removed = server.newState()
        local stateUpdate = server.newState()
        stateUpdate.time = gameTime
        for _, v in pairs(server.currentState.players) do
            -- don't send clientIds - index by uuid
            -- todo: don't send xp/stats/inventory in update
            --stateUpdate.players[v.id] = v -- sent in entities now
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
        self:sendRPC('stateUpdate', bitser.dumps(stateUpdate))
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
        projectiles.server.reset()
        entities.server.reset()
        world.server.reset()
        items.server.reset()
        lootBags.server.reset()
    end
    server.currentState = server.newState()

    physics.server.load()
    --entities.server.load()
end

function server.newState()
    return {players={}, entities={}, projectiles={}, lootBags={}}
end

function server.addPlayer(name, clientId)
    local a = math.random()*2*math.pi
    local d = math.random()*128
    local p = entities.server.defs.player:new{
        name = name,
        x = math.cos(a)*d,
        y = -math.sin(a)*d,
    }:spawn()
    server.currentState.players[clientId] = p
    server.playerNames[name] = true
    server.uuid2clientId[p.id] = clientId
    server.added.players[p.id] = p:serialize()
    server.nutServer:sendRPC('returnPlayer', bitser.dumps(p:serialize()), clientId)
    if not server.singleplayer then
        server.nutServer:sendRPC('chatMsg', p.name .. ' connected')
    end
end

function server.removePlayer(clientId)
    local p = server.currentState.players[clientId]
    server.uuid2clientId[p.id] = nil
    server.playerNames[p.name] = nil
    p:destroy()
    server.currentState.players[clientId] = nil
end

function server.addXP(playerId, xp)
    local clientId = server.uuid2clientId[playerId]
    if clientId then
        local p = server.currentState.players[clientId]
        if p then
            local _l = entities.server.defs.player.xp2level(p.xp)
            p.xp = p.xp + xp
            local l = entities.server.defs.player.xp2level(p.xp)
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
