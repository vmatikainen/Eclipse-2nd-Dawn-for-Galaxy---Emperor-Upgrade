MagellanWarden =
{
    ['Name'] = 'Wardens of Magellan',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 3,
    ['science'] = 2,
    ['money'] = 2,
    ['Box_GUID'] = 'aaf987',
    ['Population'] = {{x=0.37, z=1.41}, {x=-1.05, z=1.62}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 0
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Wardens of Magellan',
        tooltip = 'Select Wardens of Magellan',
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

    params = {PlayerColor=color, Faction=MagellanWarden}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end