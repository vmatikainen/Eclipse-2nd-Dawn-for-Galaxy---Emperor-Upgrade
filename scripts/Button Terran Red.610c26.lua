TerranDirectorate =
{
    ['Name'] = 'Terran Directorate',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = 'c0cd5b',
    ['Population'] = {{x = .39, z = 1.43}, {x = -.64, z = -1.6}, {x = -1.03, z = 1.62}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Directorate',
        tooltip = 'Select Terran Directorate',
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

    params = {PlayerColor = color, Faction=TerranDirectorate}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end