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
        return true
    end
    return false
end