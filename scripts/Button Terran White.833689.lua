TerranConglomerate =
{
    ['Name'] = 'Terran Conglomerate',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = '925680',
    ['Population'] = {{x = 1.11, z = 1.95}, {x = -.78, z = -1.4}, {x = -1.49, z = 1.48}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Conglomerate',
        tooltip = 'Select Terran Conglomerate',
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

    params = {PlayerColor = color, Faction=TerranConglomerate}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end