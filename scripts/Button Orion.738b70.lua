Orion =
{
    ['Name'] = 'Orion Hegemony',
    ['startingShip'] = 'cruiser',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = 'c823c6',
    ['Population'] = {{x = 1.8, z = -.09}, {x = -1.45, z = 1.51}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 0
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Orion Hegemony',
        tooltip = 'Select Orion Hegemony',
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

    params = {PlayerColor=color, Faction=Orion}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end