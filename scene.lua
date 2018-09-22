
scene = {
    layers = {}
}

-- todo: persistent scene: much faster sorting

function scene.reset()
    scene.layers = {}
end

-- t = {draw=_, y=_, layer=_}
function scene.add(t)
    if t.layer == nil then t.layer = 1 end
    if scene.layers[t.layer] == nil then scene.layers[t.layer] = {} end
    table.insert(scene.layers[t.layer], t)
end

function scene.draw()
    local layers = {}
    for k, v in pairs(scene.layers) do
        table.insert(layers, {k=k, v=v})
    end
    layers = isort(layers, 'k')
    for _, layer in ipairs(layers) do
        local sorted = isort(layer.v, 'y')
        for _, v in pairs(sorted) do
            v.draw()
        end
    end
end
