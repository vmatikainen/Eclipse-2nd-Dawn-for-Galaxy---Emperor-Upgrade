Lyra =
{
    ['Name'] = 'Enlightened of Lyra',
    ['startingShip'] = 'interceptor',
    ['numStartingShips'] = 1,
    ['colonyShips'] = 3,
    ['Influence'] = 13,
    ['materials'] = 3,
    ['science'] = 4,
    ['money'] = 2,
    ['Box_GUID'] = '3aaa39',
    ['Population'] = {{x= 0.35, z=1.47}, {x= -1.7, z=1.6}, {x= -0.6, z=-1.6}},
    ['PlacedMat'] = 1, 
    ['PlacedSci'] = 1, 
    ['PlacedMon'] = 1
}


function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Select Enlightened of Lyra',
        tooltip = 'Select Enlightened of Lyra',
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

    params = {PlayerColor=color, Faction=Lyra}

    if Global.call('PlayerSetup', params) then
        FactionSpecificSetup(color)
        self.removeButton(0)
        self.destruct()
    end
end


function FactionSpecificSetup(color)
    -- printToAll("Faction-specific setup Enlightened of Lyra - Setup Shrines")

end