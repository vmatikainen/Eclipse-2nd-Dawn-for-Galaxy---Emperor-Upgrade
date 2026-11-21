Eridani =
{
    ['Name'] = 'Eridani Empire',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 11,
    ['materials'] = 4,
    ['science'] = 2,
    ['money'] = 26,
    ['Box_GUID'] = '33cb0b',
    ['Population'] =  {{x = -.52, z = -1.5}, {x = -1.57, z = 1.37}},
    ['PlacedMat'] = 0, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Eridani Empire',
        tooltip = 'Select Eridani Empire',
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

    params = {PlayerColor=color, Faction=Eridani}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end