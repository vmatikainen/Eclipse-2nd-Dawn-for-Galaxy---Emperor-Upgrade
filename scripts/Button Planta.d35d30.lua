Planta =
{
    ['Name'] = 'Planta',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 4,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 2,
    ['Box_GUID'] = 'c651ae',
    ['Population'] = {{x = .76, z = 1.47}, {x = -.95, z = 1.7}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 0
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Planta',
        tooltip = 'Select Planta',
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

    params = {PlayerColor=color, Faction=Planta}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end