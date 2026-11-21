Hydran =
{
    ['Name'] = 'Hydran Progress',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 2,
    ['science'] = 6,
    ['money'] = 2,
    ['Box_GUID'] = 'd5e797',
    ['Population'] =  {{x = 1.96, z = .09}, {x = .17, z = -1.67}},
    ['PlacedMat'] = 0, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Hydran Progress',
        tooltip = 'Select Hydran Progress',
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

    params = {PlayerColor=color, Faction=Hydran}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end