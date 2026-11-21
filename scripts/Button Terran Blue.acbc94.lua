TerranFederation =
{
    ['Name'] = 'Terran Federation',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = '2f3c28',
    ['Population'] = {{x = 1.29, z = -.17}, {x = -.97, z = -1.61}, {x = -.69, z = 1.71}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Federation',
        tooltip = 'Select Terran Federation',
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

    params = {PlayerColor = color, Faction=TerranFederation}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end