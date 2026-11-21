Descendants =
{
    ['Name'] = 'Descendants of Draco',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 3,
    ['science'] = 4,
    ['money'] = 2,
    ['Box_GUID'] = '98e4a0',
    ['Population'] =  {{x = .76, z = 1.5}, {x = -.13, z = -1.69}},
    ['PlacedMat'] = 0, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Descendants of Draco',
        tooltip = 'Select Descendants of Draco',
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

    params = {PlayerColor = color, Faction=Descendants}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end