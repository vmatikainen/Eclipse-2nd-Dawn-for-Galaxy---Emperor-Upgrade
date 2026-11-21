Exiles =
{
    ['Name'] = 'The Exiles',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 4,
    ['science'] = 2,
    ['money'] = 3,
    ['Box_GUID'] = '5c2542',
    ['Population'] = {{x= -1.6, z=1.47}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 0, 
    ['PlacedMon'] = 0
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select The Exiles',
        tooltip = 'Select The Exiles',
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

    params = {PlayerColor=color, Faction=Exiles}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end