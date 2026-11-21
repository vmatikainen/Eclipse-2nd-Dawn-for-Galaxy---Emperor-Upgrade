TerranRepublic =
{
    ['Name'] = 'Terran Republic',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 3,
    ['money'] = 3,
    ['Box_GUID'] = '59490e',
    ['Population'] =  {{x = 1.29, z = 1.47}, {x = .09, z = -1.56}, {x = -1.1, z = 1.98}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Terran Republic',
        tooltip = 'Select Terran Republic',
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

    params = {PlayerColor = color, Faction=TerranRepublic}

    if Global.call('PlayerSetup', params) then
        self.removeButton(0)
        self.destruct()
    end
end