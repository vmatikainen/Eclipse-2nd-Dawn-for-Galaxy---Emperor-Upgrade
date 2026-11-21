PyxisUnity =
{
    ['Name'] = 'Pyxis Unity',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 2,
    ['Influence'] = 14,
    ['materials'] = 3,
    ['science'] = 2,
    ['money'] = 2,
    ['Box_GUID'] = 'd253ad',
    ['Population'] =  {{x= 1.33, z=0.97}}
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Pyxis Unity',
        tooltip = 'Select Pyxis Unity',
        function_owner = self,
        position = {0, -0.05, 0},
        rotation = {0, 0, 0},
        width = 800,
        height = 800,
        font_size = 40
    })
end


function onClick(obj, color, alt_click)
    if alt_click == true then return true end

    params = {PlayerColor=color, Faction=PyxisUnity}

    if Global.call('PlayerSetup', params) then
      --FactionSpecificSetup(color)
      self.removeButton(0)
      self.destruct()
    end
end


function FactionSpecificSetup(color)
    printToAll("Faction-specific setup PyxisUnity")

    local Box = getObjectFromGUID(PyxisUnity.Box_GUID)
    local PlayerPosition = Player[color].getHandTransform(int).position
    PlayerPosition.y = 0.15
end