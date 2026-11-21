TerranAlliance =
{
    ['Name'] = 'Terran Alliance',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = '93239c',
    ['Population'] = {{x = 1.1, z = 1.8}, {x = -.45, z = -1.5}, {x = -1.59, z = 1.35}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Alliance',
        tooltip = 'Select Terran Alliance',
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

    params = {PlayerColor = color, Faction=TerranAlliance}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end