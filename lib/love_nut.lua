
local socket = require 'socket'

local nut = {
    logMessages = false,
    logErrors = true,
    _VERSION = 'LoveNUT 0.1.1-dev'
}

function nut.log(msg)
    if nut.logMessages then print(msg) end
end

function nut.logError(err)
    if nut.logErrors then print(err) end
end

-- local ip
function nut.getIP()
    local s = socket.udp()
    s:setpeername('8.8.8.8', 80)
    local ip, port = s:getsockname()
    return ip
end


local client = {}

function client:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    local defaults = {updateRate=1/20}
    defaults.rpcs = {}
    defaults.updates = {}
    for k, v in pairs(defaults) do
        if not o[k] then o[k] = v end
    end
    o.updateTimer = 0
    o.connected = false
    nut.log('created client')
    return o
end

function client:connect(ip, port)
    self.udp = socket.udp()
    self.udp:settimeout(0)
    self.tcp = socket.tcp()
    self.tcp:settimeout(0)
    self.tcp:setoption('reuseaddr', true)
    self.tcp:setoption('tcp-nodelay', true)
    nut.log('connecting to ' .. ip .. ':' .. tostring(port))
    port = tonumber(port)
    self.udp:setpeername(ip, port)
    self.tcp:settimeout(5)
    local success, msg = self.tcp:connect(ip, port)
    if success then
        self.connected = true
        nut.log('connected')
    else
        nut.logError('client connect err: ' .. tostring(msg))
    end
    self.tcp:settimeout(0)
end

function client:addRPCs(t)
    for name, rpc in pairs(t) do
        self.rpcs[name] = rpc
    end
end

function client:addUpdate(f)
    table.insert(self.updates, f)
end

function client:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer > self.updateRate then
        self.updateTimer = self.updateTimer - self.updateRate
        if self.connected then
            repeat
                local data, msg = self.udp:receive()
                if data then
                    nut.log('client received udp: ' .. data)
                    -- todo: handle
                elseif msg ~= 'timeout' then
                    nut.logError('client udp recv err: ' .. tostring(msg))
                end
            until not data
            repeat
                local data, msg = self.tcp:receive()
                if data then
                    nut.log('client received tcp: ' .. data)
                    local rpcName, rpcData = data:match('^(%S*) (.*)$')
                    self:callRPC(rpcName, rpcData)
                elseif msg ~= 'timeout' then
                    nut.logError('client tcp recv err: ' .. tostring(msg))
                end
            until not data
            for _, v in pairs(self.updates) do
                v(self)
            end
        end
    end
end

function client:sendRPC(name, data)
    if not data or data == '' then data = '$' end
    local dg = name .. ' ' .. data
    dg = dg:gsub('\r', ''):gsub('\n', '')
    dg = dg .. '\r\n'
    nut.log('client tcp send: ' .. dg)
    return self.tcp:send(dg)
end

function client:callRPC(name, data)
    local rpc = self.rpcs[name]
    if rpc then
        rpc(self, data)
    else
        nut.logError('client rpc "' .. tostring(name) .. '" not found')
    end
end

function client:close()
    self:sendRPC('disconnect')
    socket.sleep(0.1) -- todo: not good solution
    self.udp:close()
    self.tcp:close()
    client.connected = false
end

setmetatable(client, {__call = function(_, ...) return client:new(...) end})


local server = {}

function server:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    local defaults = {port=nil, updateRate=1/20, connectionLimit=nil}
    defaults.rpcs = {
        connect = function(self, data, clientId)
            nut.log(clientId .. ' connected')
        end,
        disconnect = function(self, data, clientId)
            self.clients[clientId] = nil
            nut.log(clientId .. ' disconnected')
        end
    }
    defaults.updates = {}
    for k, v in pairs(defaults) do
        if not o[k] then o[k] = v end
    end
    o.updateTimer = 0
    nut.log('created server')
    return o
end

function server:start()
    if self.port == nil then
        local tcp = socket.bind('0.0.0.0', 0)
        _, self.port = tcp:getsockname()
        tcp:close()
    end
    self.udp = socket.udp()
    self.udp:settimeout(0)
    self.udp:setsockname('0.0.0.0', self.port)
    self.tcp = socket.tcp()
    self.tcp:settimeout(0)
    self.tcp:setoption('reuseaddr', true)
    self.tcp:setoption('tcp-nodelay', true)
    self.tcp:bind('0.0.0.0', self.port)
    self.tcp:listen(5)
    self.clients = {}
    nut.log('started server')
end

function server:addRPCs(t)
    for name, rpc in pairs(t) do
        self.rpcs[name] = rpc
    end
end

function server:addUpdate(f)
    table.insert(self.updates, f)
end

function server:accept()
    local sock, msg = self.tcp:accept()
    if sock then
        sock:settimeout(0)
        sock:setoption('reuseaddr', true)
        sock:setoption('tcp-nodelay', true)
        local ip, port = sock:getpeername()
        local clientId = ip .. ':' .. tostring(port)
        if self.clients[clientId] then
            nut.logError(clientid .. ' already connected')
            return nil
        else
            self.clients[clientId] = {tcp=sock}
        end
        local rpc = self.rpcs.connect
        if rpc then
            rpc(self, '$', clientId)
        end
    elseif msg ~= 'timeout' then
        nut.logError('server tcp accept err: ' .. tostring(msg))
    end
    return sock, msg
end

function server:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer > self.updateRate then
        self.updateTimer = self.updateTimer - self.updateRate
        repeat
            local sock
            if self.connectionLimit then
                local ctr = 0
                for _, _ in pairs(self.clients) do ctr = ctr + 1 end
                if ctr < self.connectionLimit then
                    sock = self:accept()
                end
            else
                sock = self:accept()
            end
        until not sock
        repeat
            local data, msg_or_ip, port_or_nil = self.udp:receivefrom()
            if data then
                local ip, port = msg_or_ip, port_or_nil
                nut.log('server received udp: ' .. data)
                local clientid = ip .. ':' .. tostring(port)
            elseif msg_or_ip ~= 'timeout' then
                nut.logError('server udp recv err: ' .. tostring(msg_or_ip))
            end
        until not data
        for clientId, v in pairs(self.clients) do
            repeat
                local data, msg = v.tcp:receive()
                if data then
                    nut.log('server received tcp: ' .. data)
                    local rpcName, rpcData = data:match('^(%S*) (.*)$')
                    self:callRPC(rpcName, rpcData, clientId)
                elseif msg ~= 'timeout' then
                    nut.logError('server tcp recv err: ' .. tostring(msg_or_ip))
                end
            until not data
        end
        for _, v in pairs(self.updates) do
            v(self)
        end
    end
end

function server:sendRPC(name, data, clientId)
    if not data or data == '' then data = '$' end
    local dg = name .. ' ' .. data
    dg = dg:gsub('\r', ''):gsub('\n', '')
    dg = dg .. '\r\n'
    if clientId then
        if self.clients[clientId] then
            --local ip, port = clientId:match("^(.-):(%d+)$")
            self.clients[clientId].tcp:send(dg)
        else
            nut.logError(clientId .. ' not in client list')
        end
    else
        for clientId, v in pairs(self.clients) do
            v.tcp:send(dg)
        end
    end
end

function server:callRPC(name, data, clientId)
    local rpc = self.rpcs[name]
    if rpc then
        rpc(self, data, clientId)
    else
        nut.logError('server rpc "' .. tostring(name) .. '" not found')
    end
end

function server:close()
    self.udp:close()
    self.tcp:close()
end

setmetatable(server, {__call = function(_, ...) return server:new(...) end})


nut.client = client
nut.server = server

return nut
