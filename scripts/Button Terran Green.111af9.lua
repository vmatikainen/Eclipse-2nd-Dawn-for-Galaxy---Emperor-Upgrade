TerranUnion =
{
    ['Name'] = 'Terran Union',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = 'd3186b',
    ['Population'] = {{x = 1.15, z = 1.93}, {x = 1.12, z = -1.28}, {x = -1.62, z = 1.35}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Union',
        tooltip = 'Select Terran Union',
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

    params = {PlayerColor = color, Faction=TerranUnion}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end