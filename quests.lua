
quests = {}

questBlockSlots = {}
for k, v in ipairs{'cost', 'reward'} do
    for j=1, 2 do
        for i=1, 2 do
            table.insert(questBlockSlots, {
                x = 7 + (i-1)*18 + (k-1)*54,
                y = 22 + (j-1)*18,
                w = 15,
                h = 15,
                type = v
            })
        end
    end
end

quests.current = {cost={}, reward={}, heldItems={}}
function quests.refresh()
    quests.current = {cost={}, reward={}, heldItems={}}
    local choices = {
        shield=40, apple=40,
        sword0=10, sword1=10
    }
    for _=1, 2 do
        choice = lume.weightedchoice(choices)
        local itemData = {id=lume.uuid(), imageId=choice}
        if choice == 'sword0' then
            itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+10))
        elseif choice =='sword1' then
            itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+12))
        end
        client.newItem(itemData)
        table.insert(quests.current.cost, itemData.id)
    end
    local choices = {sword2=40, sword3=40, sword4=20}
    choice = lume.weightedchoice(choices)
    local itemData = {id=lume.uuid(), imageId=choice}
    if choice =='sword2' then
        itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+14))
    elseif choice =='sword3' then
        itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+16))
    elseif choice =='sword4' then
        itemData.atk = math.max(5, math.floor(love.math.randomNormal()*2+18))
    end
    client.newItem(itemData)
    table.insert(quests.current.reward, itemData.id)
end
