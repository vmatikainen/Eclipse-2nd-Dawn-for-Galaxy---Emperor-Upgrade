function onCollisionEnter()
    self.shuffle()
end


function onObjectEnterContainer(container)
    if container == self then self.shuffle() end
end

function onSearchEnd()
    self.shuffle()
end


function filterObjectEnter(obj)
    if obj.getName() == "Reputation" then
        obj.setHiddenFrom()
        -- returned tiles go back face down, so they come out of the bag face down
        local rotation = obj.getRotation()
        obj.setRotation({0, rotation.y, 180})
        return true
    end
    return false
end