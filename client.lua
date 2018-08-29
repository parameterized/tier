
client = {}

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
        end
    }
    client.nutClient:connect(ip, port)
    client.connected = true
    client.nutClient:sendRPC('requestPlayer', menu.nameInput.value)

    client.serverTime = 0
    client.states = {}
    client.stateIdx = 1
    client.stateTime = 0
    -- cleanup previous connection
    if client.currentState then
        player.destroy()
        for _, v in pairs(client.currentState.players) do
            v.fixture:destroy()
            v.body:destroy()
        end
        collectgarbage()
    end
    client.currentState = client.newState()

    menu.writeDefaults()

    player.load()
end

function client.newState()
    return {players={}, bullets={}, entities={}}
end

function client.startGame(p)
    player.id = p.id
    player.name = p.name
    player.body:setPosition(p.x, p.y)
    gameState = 'playing'
end

function client.sendMessage(msg)
    if client.connected then
        client.nutClient:sendRPC('chatMsg', msg)
    end
end

function client.update(dt)
    client.nutClient:update(dt)
end

function client.close()
    client.nutClient:close()
    client.connected = false
end
