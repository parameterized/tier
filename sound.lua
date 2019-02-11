
sound = {}

function sound.play(name)
    sfx[name]:clone():play()
end
