
items = {
    server = {
        container = {}
    },
    client = {
        container = {},
        requested = {}
    }
}

function items.server.newItem(data)
    local id = lume.uuid()
    items.server.container[id] = data
    return id
end

function items.server.reset()
    items.server.container = {}
end

function items.server.getItem(id)
    if id == nil then return nil end
    return items.server.container[id]
end



function items.client.reset()
    items.client.container = {}
    items.client.requested = {}
end

function items.client.getItem(id)
    if id == nil then return nil end
    local item = items.client.container[id]
    if item then
        return item
    else
        if not items.client.requested[id] then
            client.nutClient:sendRPC('getItem', bitser.dumps{id=id})
            items.client.requested[id] = true
        end
        return nil
    end
end
