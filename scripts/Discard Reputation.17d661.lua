local RepZone_GUID = '773f39'
local RepZone = nil

function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Discard Reputation',
        tooltip = 'Discard Reputation',
        function_owner = self,
        position = {0, -0.1, 0},
        rotation = {0, 0, 0},
        width = 3600,
        height = 850,
        font_size = 400
    })
    RepZone = getObjectFromGUID(RepZone_GUID)
end


function onClick(d, color, alt_click)
    if alt_click == false then
        discards = Player[color].getHandObjects()
        zone = RepZone.getObjects()
        for _,obj in pairs(zone) do
            if obj.getName() == "Reputation" then table.insert(discards, obj) end
        end
        for x,obj in pairs(discards) do
            Wait.time(function() Global.call('discardRep', obj) end, 0.2*x, 1)
        end
    end
end