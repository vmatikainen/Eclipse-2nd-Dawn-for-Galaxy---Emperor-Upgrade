function onCollisionEnter()
    self.shuffle()
end


function filterObjectEnter(obj)
    if string.find(obj.getName(), "Tech %-") != nil then
        return true
    end
    return false
end