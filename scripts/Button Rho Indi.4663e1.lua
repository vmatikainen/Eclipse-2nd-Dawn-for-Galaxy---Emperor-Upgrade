RhoIndi =
{
    ['Name'] = 'Rho Indi Syndicate',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 2,
    ['colonyShips'] = 2,
    ['Influence'] = 13,
    ['materials'] = 3,
    ['science'] = 3,
    ['money'] = 2,
    ['Box_GUID'] = '1bb918',
    ['Population'] = {{x= -1.33, z=1.22}, {x=-1.39, z=-1.43}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 0, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Rho Indi Syndicate',
        tooltip = 'Select Rho Indi Syndicate',
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

    params = {PlayerColor=color, Faction=RhoIndi}

    if Global.call('PlayerSetup', params) then
      self.removeButton(0)
      self.destruct()
    end
end