function onload ()
    self.createButton({
        click_function = 'onClick',
        label = 'Next Round',
        tooltip = 'Next Round',
        function_owner = self,
        position = {0, -0.05, 0},
        rotation = {0, 0, 0},
        width = 3600,
        height = 850,
        font_size = 400
    })
end


-- Prevent accidental double-clicks on button --
local lockout = false


function onClick(obj, color, alt_click)
  local params = {PlayerColor=color}

  if lockout == false and alt_click == false then
    lockout = true
    Global.call('nextRound', params)
    Wait.time(function() lockout = false end, 5)
  end
end