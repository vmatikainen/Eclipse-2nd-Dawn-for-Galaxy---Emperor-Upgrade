 --[[ Lua code. See documentation: http://api.tabletopsimulator.com/ --]]
local DebugMode = false
local Objects_Visible = false   -- hides objects that should not be visible for players

 -- GUIDS --
 local RoundMarker_GUID = '7ad23d'  
 local TurnDirection_GUID = 'c5f789'
 local TechBag_GUID = 'd67d39'
 local ReputationBag_GUID = '3c5d08'
 local DiscoveryBag_GUID = '3c0b57'
 local Sector1Bag_GUID = '2adc64'
 local Sector2Bag_GUID = '3ae266'
 local Sector3Bag_GUID = 'd5cb79'
 local ExtraS3Bag_GUID = '69b446'
 local InfluenceDisks_GUID = '3e551c'
 local MinorSpeciesBag_GUID = '0d6bda'
 local TableZone_GUID = '773f39'
 local Traitor_GUID = 'faba6c'
 local FirstPlayer_GUID = 'dd7a2e'

 local BoardBag_GUID = '5520cc'
 local InterceptorTemplate_GUID = '266ecb'
 local CruiserTemplate_GUID = 'bbf391'
 local DreadnoughtTemplate_GUID = 'bc9d7d'
 local StarbaseTemplate_GUID = '0cef48'
 local DeathmoonTemplate_GUID = '232df1'
 local ResourceTemplate_GUID = '66e25b'
 local ColonyShipTemplate_GUID = '552294'
 local ShrineTemplate_GUID = 'a1d6db'

 local RoundMarker = nil   
 local TurnDirection = nil
 local TechBag = nil
 local ReputationBag = nil
 local DiscoveryBag = nil
 local Sector1Bag = nil
 local Sector2Bag = nil
 local Sector3Bag = nil
 local MinorSpeciesBag = nil
 local TableZone = nil
 local rareTechIndex = 0

 PlayerSelection = {
     ["Blue"] = 'none',
     ["Yellow"] = 'none',
     ["Purple"] = 'none',
     ["Red"] = 'none',
     ["Green"] = 'none',
     ["Orange"] = 'none',
     ["White"] = 'none'
 }

 -- TODO --
 -- table of all players that passed in the current round
 PlayersThatPassed = {}

 local DisabledGUIDs = { -- side tables + wooden heads
                     '3ae8e5', 'ff8bf2', '35a027', '15133f', '08e4b3', '2aa05e',
                     'd7b789', '652e54', '465b0b', '5ef8d4', '1d4bd9', '56f9de',
                     'a31b35', '997cb8', -- science board, minor species
                     'ac4050' -- faction selection table
                      }

 local BehindTheScenes_GUIDs = { --objects the players shouldn't see and interact with
                      -- Faction bags (by collumn: Eridani, Terran Red, Planta, ...)
                     '33cb0b', 'c0cd5b', 'c651ae', 'd3186b',
                     '98e4a0', '59490e', 'd5e797', '2f3c28',
                     '9b4fa8', '925680', 'c823c6', '93239c',
                     'd253ad', '5c2542', '1bb918', 'aaf987',
                     '3aaa39', -- Enlightened of Lyra
                     '3e551c', -- Bag to spawn Influence Disk
                     InterceptorTemplate_GUID, CruiserTemplate_GUID,
                     DreadnoughtTemplate_GUID, StarbaseTemplate_GUID,
                     DeathmoonTemplate_GUID, ShrineTemplate_GUID,
                     BoardBag_GUID, ResourceTemplate_GUID, ColonyShipTemplate_GUID,
                    '67b1fb'}

 local ButtonGUIDs = { -- select a faction (by collumn: Eridani, Terran Red, ...)
                   '68eb20', '610c26', 'd35d30', '111af9',
                   '859e09', 'ca1635', '258abe', 'acbc94',
                   '6a3403', '833689', '738b70', '10e852',
                   'a064f5', 'c9e20e', '4663e1', '87e4f1',
                   'c37168' -- Lyra
                   }

 local passed = {White = true, Yellow = true, Red = true,
                 Green = true, Blue = true, Purple = true}


 -- The available seats on the table, including ones that don't have hands.
 available_colors = {"White", "Red", "Blue", "Purple", "Green", "Pink", "Orange", "Yellow", "Brown", "Black", "Teal", "Grey"}
 ui_visibility = {"White", "Red", "Blue", "Purple", "Green", "Pink", "Orange", "Yellow", "Brown", "Black", "Teal", "Grey"}


-- The game's settings.
settings = {
  setupCompleted = false,
  PlayerCount = 4,

  RiftWeapons = true,
  MinorSpecies = true,
  FirstEdition = true,
  GalacticEvents = false,

  AdvancedGCDS = false,
  AdvancedAncients = false,
  AdvancedGuardians = false,

  NoRoundLimit = false,
  TechAfterRaces = false,     -- draw the starting techs after race selection, not at Setup

  TurnOrder = "rotating",     -- "rotating" or "pass" (see TURN ORDER)
  StartingPlayer = "yellow",  -- "yellow", "random" or "draft" (draft: pass order only)

  RandomizeSeats = false,
  RandomRaces = false,
  SeatTiming = "after"   -- "draft", "race" or "after" (see RANDOMIZE SEAT ORDER)
}

-- print the settings as currently configured
function printSettings()
  printToAll("Settings:")
  printToAll(string.format(" - Player count: %s", tostring(settings.PlayerCount)))
  printToAll(string.format(" - Rift Cannon: %s", tostring(settings.RiftWeapons)))
  printToAll(string.format(" - Mionor Species: %s", tostring(settings.MinorSpecies)))
  printToAll(string.format(" - Galactic Events: %s", tostring(settings.GalacticEvents)))
  printToAll(string.format(" - Round Limit: %s", tostring(not settings.NoRoundLimit)))
  printToAll(string.format(" - Tech setup after faction selection: %s", tostring(settings.TechAfterRaces == true)))
  printToAll(string.format(" - Turn order: %s", ATO_passOrder() and "pass order" or "rotating"))
  printToAll(string.format(" - Starting player: %s", ATO_startMode()))
  printToAll(string.format(" - Random factions: %s", tostring(settings.RandomRaces == true)))
  printToAll(string.format(" - Randomize seat order: %s", settings.RandomizeSeats and tostring(SEAT_timing()) or "false"))
end


-- UI --

-- opens the setup panel for a given player.
function openSetupPanel(player, elementId)
  table.insert(ui_visibility, player.color)
  updateUI_Visibility()
end


-- Closes the setup panel for a given player.
function closeSetupPanel(player, elementId)
    -- remove player color
    for k,v in pairs(ui_visibility) do
      if v == player.color then
        ui_visibility[k]= nil
      end
    end
    updateUI_Visibility()
end

-- update the visibility attributes for all UI elements
function updateUI_Visibility()

    -- Hide setup UI after the setup stage
  if (settings.setupCompleted) then
    UI.setAttribute("SetupPanel", "active", "false")
    UI.setAttribute("Button_ShowSetup", "active", "false")
    return true
  end

  -- panel with setup options
  if #ui_visibility > 0 then
    UI.setAttribute("SetupPanel", "visibility", table.concat(ui_visibility, "|"))
    UI.setAttribute("SetupPanel", "active", "true")
  else
    UI.setAttribute("SetupPanel", "active", "false")
  end

  -- button to show the setup options
  local invertedTable = invertVisibilityTable(ui_visibility)
  if #invertedTable > 0 then
    local VisibilityString= table.concat(invertedTable, "|")
    UI.setAttribute("Button_ShowSetup", "visibility", VisibilityString)
    UI.setAttribute("Button_ShowSetup", "active", "true")
  else
    UI.setAttribute("Button_ShowSetup", "active", "false")
  end
end


-- Inverts a UI visibility table, so all players currently present in it are removed, while all players not present are added
function invertVisibilityTable(visibilityTable)
    local newVisibilityTable = {}

    -- Loop through the available seats.
    for key, value in ipairs(available_colors) do
        -- If a value is missing in the original table, add it to the new table
        if not table.contains(ui_visibility, value) then
            table.insert(newVisibilityTable, value)
        end
    end
    return newVisibilityTable
end


-- triggered by changes to the setup UI
function SetupUI_OnChange(player, checked, elementId)
  if (DebugMode) then print(elementId .. ' ' .. checked) end

  -- check for player count changes
  if ((string.sub(elementId,2,8)=="Players") and (checked=="True")) then
    settings.PlayerCount = tonumber(string.match(elementId, "%d"))
    if (DebugMode) then print("New player count: ", settings.PlayerCount) end
  else
    for key, value in pairs(settings) do
      -- Update the setting matching the element ID
      if elementId == key then settings[key] = not(checked=="False") end
    end
  end
  SEAT_updateSetupUI()

  updateGameStateBasedOnSettings()
end


-- update the global state of the setup UI based on game settings
function updateSetupUI()

  updateUI_Visibility()

  if (settings.RiftWeapons) then UI.setAttribute("RiftWeapons", "isOn", true)
  else UI.setAttribute("RiftWeapons", "isOn", false) end

  if (settings.FirstEdition) then UI.setAttribute("FirstEdition", "isOn", true)
  else UI.setAttribute("FirstEdition", "isOn", false) end

  if (settings.MinorSpecies) then UI.setAttribute("MinorSpecies", "isOn", true)
  else UI.setAttribute("MinorSpecies", "isOn", false) end

  if (settings.GalacticEvents) then UI.setAttribute("GalacticEvents", "isOn", true)
  else UI.setAttribute("GalacticEvents", "isOn", false) end


  if (settings.AdvancedGCDS) then UI.setAttribute("AdvancedGCDS", "isOn", true)
  else UI.setAttribute("AdvancedGCDS", "isOn", false) end

  if (settings.AdvancedAncients) then UI.setAttribute("AdvancedAncients", "isOn", true)
  else UI.setAttribute("AdvancedAncients", "isOn", false) end

  if (settings.AdvancedGuardians) then UI.setAttribute("AdvancedGuardians", "isOn", true)
  else UI.setAttribute("AdvancedGuardians", "isOn", false) end

  UI.setAttribute("RandomRaces", "isOn", settings.RandomRaces == true)


  if (settings.NoRoundLimit) then UI.setAttribute("NoRoundLimit", "isOn", true)
  else UI.setAttribute("NoRoundLimit", "isOn", false) end
  UI.setAttribute("TechAfterRaces", "isOn", settings.TechAfterRaces == true)

  for i = 2, 6 do UI.setAttribute(i .. 'Players', 'isOn', settings.PlayerCount == i) end
  SEAT_updateSetupUI()
end


-- Called when the game is saved, save global settings
function onSave()
  settings.ATOState = ATO
  settings.PlayerState = PlayerState
  settings.HexState = HexState_save()
  settings.CombatZone = CombatZone_save()
  local data = JSON.encode(settings)
  settings.ATOState = nil
  settings.PlayerState = nil
  settings.HexState = nil
  settings.CombatZone = nil
  return data
end


-- The onLoad event is called after the game save finishes loading. --
function onLoad(saveData)
    RoundMarker = getObjectFromGUID(RoundMarker_GUID)
    TurnDirection = getObjectFromGUID(TurnDirection_GUID)
    if TurnDirection ~= nil then
      TurnDirection.addContextMenuItem("Update direction", function() STO_applyDirection() end)
    end
    TechBag = getObjectFromGUID(TechBag_GUID)
    ReputationBag = getObjectFromGUID(ReputationBag_GUID)
    DiscoveryBag = getObjectFromGUID(DiscoveryBag_GUID)
    Sector1Bag = getObjectFromGUID(Sector1Bag_GUID)
    Sector2Bag = getObjectFromGUID(Sector2Bag_GUID)
    Sector3Bag = getObjectFromGUID(Sector3Bag_GUID)
    ExtraS3Bag = getObjectFromGUID(ExtraS3Bag_GUID)
    MinorSpeciesBag = getObjectFromGUID(MinorSpeciesBag_GUID)
    TableZone = getObjectFromGUID(TableZone_GUID)

    local saved = nil
    if saveData and saveData ~= "" then saved = JSON.decode(saveData) end

    local round = tonumber(RoundMarker.getDescription())
    if (round>0) then
      -- Load the save data, if present
      if saved then
        settings = saved
        ATO_migrateSettings()
        ATO_restore(settings.ATOState)
        settings.ATOState = nil
        printToAll("Save state initialized")
        printToAll(string.format("Round: %s", round))
        printSettings()
      end
    end

    -- factions can be selected before Setup too, so restore them whatever the round
    PlayerState_restore(saved and saved.PlayerState)
    settings.PlayerState = nil
    -- faction picks still waiting for the seats to be randomized
    SEAT_restore()
    -- saves made before the standard turn order used the built-in turns: switch them on
    if STO_active() then STO_enableTurns() end
    -- ship state isn't saved: rebuild it from the races and the tiles on the boards;
    -- hex state (arrival order) is saved, and checked against the ships once they're marked
    local savedHexes = saved and saved.HexState
    settings.HexState = nil
    -- a combat in the combat zone: its ships still count in their hex
    CombatZone_restore(saved and saved.CombatZone)
    settings.CombatZone = nil
    Wait.time(function()
      ShipState_restore()
      HexState_restore(savedHexes)
      TechTrack_reconcile()
      CombatSim_restore()
    end, 1)
    addContextMenuItem("Show my ships", function(player_color) ShipState_report(player_color) end)
    addContextMenuItem("Show NPC ships", function(player_color) ShipState_npcReport(player_color) end)
    addContextMenuItem("Show combats", function(player_color) HexState_report(player_color) end)

    updateGameStateBasedOnSettings()
    shuffleEverything()

    setVisibility(BehindTheScenes_GUIDs, DebugMode)
    setInteractivity(DebugMode)
    if (DebugMode) then
      addContextMenuItem("Toggle Visibility", toggleVisibility)
      addContextMenuItem("Toggle Interactivity", toggleInteractivity)
    end

    -- hide stuff under the table unless we are in debug mode
    for _,GUID in pairs(BehindTheScenes_GUIDs) do
      local object = getObjectFromGUID(GUID)
      local position
      if (object ~= nil) then
        position = object.getPosition()
        if (DebugMode) then object.setPosition({position.x, 2, position.z}) else
          object.setPosition({position.x, -2, position.z}) end
      end
    end

    -- the race selection mat is the combat zone once race selection is over
    if raceSelectionDone() then CombatZone_show() end

    ATO_updateUI()
    ATO_resume()
end


function updateGameStateBasedOnSettings()

  updateSetupUI()

  -- dice bag (2x), rules
  if (settings.RiftWeapons) then
    setVisibility({'1ec1c3', '79897f','634b9c'}, true)
  else
    setVisibility({'1ec1c3', '79897f','634b9c'}, false)
  end

  -- ambassador bag, rules and board
  if (settings.MinorSpecies) then
    setVisibility({MinorSpeciesBag_GUID, 'eb27df', '997cb8'}, true)
  else
    setVisibility({MinorSpeciesBag_GUID, 'eb27df', '997cb8'}, false)
  end

  if (settings.FirstEdition) then
    setVisibility({'a064f5', 'c9e20e', '87e4f1', 'c37168', '4663e1'}, true)
  else
    setVisibility({'a064f5', 'c9e20e', '87e4f1', 'c37168', '4663e1'}, false)
  end

  if (settings.GalacticEvents) then
    setVisibility({'9dcdd8'}, true)
  else
    setVisibility({'9dcdd8'}, false)
  end

  -- race buttons: only the player picking a race sees them (after the expansion
  -- buttons were shown or hidden above)
  RaceButtons_update()
end


-- perform the initial game setup for the first round
function gameSetup()
  local round = tonumber(RoundMarker.getDescription()) + 1
  local players = settings.PlayerCount

  broadcastToAll(string.format("--  Round #1 (Setup for %d players)  --", players))
  -- the starting player and the round 1 turn order, then race selection in turn
  -- (randomized seats before drafting, or, without a draft, before race selection)
  local seatTiming = SEAT_timing()
  if seatTiming == "draft" or (seatTiming == "race" and not ATO_usesDraft()) then
    SEAT_randomize(ATO_startSetup)
  else
    ATO_startSetup()
  end

  -- update round marker
  RoundMarker.setPositionSmooth({42.87, 1.32, 19.24}, false, false)
  RoundMarker.setRotationSmooth({0,180,0})
  RoundMarker.setDescription(round)

  settings.setupCompleted = true
  updateUI_Visibility()
  ATO_updateUI()

  if not(settings.RiftWeapons) then RemoveRiftExpansion() end
  if (settings.GalacticEvents) then AddGalacticEvents() end

  shuffleEverything()

  ExtraS3Bag.setName("Unused sector tiles")
  AdjustOuterSectors(players)

  -- Put a discovery tile on the Galactic Center
  local d = DiscoveryBag.takeObject({rotation = {180,-45,0}})
  d.setPositionSmooth(Vector(-0.05, 1.5, 0), false, true)

  local GCDSBag =  getObjectFromGUID('133a3f')
  GCDSBag.shuffle()
  local GCDS = nil
  if (settings.AdvancedGCDS) then
    GCDS= GCDSBag.takeObject({rotation = {180, 0, -180}})
  else
    GCDS= takeGUID('12c527', GCDSBag, {rotation = {180, 0, -180}})
  end
  if (GCDS~=nil) then GCDS.setPositionSmooth(Vector(0, 2, 0), false, false) end
  GCDSBag.destruct()

  local AncientsBag =  getObjectFromGUID('b61460')
  AncientsBag.shuffle()
  local Ancient = nil
  if (settings.AdvancedAncients) then
    Ancient = AncientsBag.takeObject({rotation = {180, 90, -180}})
  else
    Ancient= takeGUID('83db86', AncientsBag, {rotation = {180, 90, -180}})
  end
  if (Ancient~=nil) then
    Ancient.setPositionSmooth(Vector(34.4, 1.5, -11.82), false, false)
    triggerFunctionIfResting(Ancient, function () Ancient.setLock(true) end)
  end
  AncientsBag.destruct()

  local GuardiansBag =  getObjectFromGUID('0a5a7a')
  GuardiansBag.shuffle()
  local Guardian = nil
  if (settings.AdvancedGuardians) then
    Guardian= GuardiansBag.takeObject({rotation = {180, 90, -180}})
  else
    Guardian= takeGUID('2d2ca5', GuardiansBag, {rotation = {180, 90, -180}})
  end
  if (Guardian~=nil) then
    Guardian.setPositionSmooth(Vector(34.4, 1.5, -14.45), false, false)
    triggerFunctionIfResting(Guardian, function () Guardian.setLock(true) end)
  end
  GuardiansBag.destruct()

  if (settings.MinorSpecies) then SetupMinorAmbassadors() end

  refreshColonyShips()
  refreshPassCards()
  CleanUp()
  
  -- remove traitor card for 2 or 3 players
  if (players<4) then getObjectFromGUID(Traitor_GUID).destruct() end

  -- house rule "Tech setup after race selection": drawn by ATO_startPlay instead
  if not settings.TechAfterRaces then drawStartingTechs() end
end


-- draw the technology tiles available in round 1
function drawStartingTechs()
  rareTechIndex = 0
  newTechs = (settings.PlayerCount * 2) + 8
  Wait.time(drawTech, 0.4, newTechs)  -- repeat drawTech [newTech] times
end


-- move the first player tile in front of the given player
function placeFirstPlayerTile(player_color)
  local FirstPlayer_Tile = getObjectFromGUID(FirstPlayer_GUID)
  local Traitor_Tile = getObjectFromGUID(Traitor_GUID)
  if (FirstPlayer_Tile == nil or player_color == nil) then return end

  -- place first player tile if the selected player has a location at the table
  if (Player[player_color].getHandTransform(int)~=nil) then
    local PlayerPosition = Player[player_color].getHandTransform(int).position
    PlayerPosition.y = 0.15
    local InvPos = -1
    if PlayerPosition.z < 0 then InvPos = 1 end
 
    local Rotation = vector(0, (InvPos+1)*90, 0)
    local destination = PlayerPosition + Vector(0, 1, 28*InvPos)
    FirstPlayer_Tile.setPositionSmooth(destination, false, false)
    FirstPlayer_Tile.setRotationSmooth(Rotation, false, true)
  else -- fallback: move first player & traitor tile 
    if (settings.PlayerCount>3) then
      FirstPlayer_Tile.setPositionSmooth({41.28, 1.06, -23.10}, false, false)
      if (Traitor_Tile ~= nil) then Traitor_Tile.setPositionSmooth({35.7, 0.96, -23.10}, false, false) end
    end
  end

end


-- Add special sector tiles from the "Galactic events" expansion
function AddGalacticEvents()
  local sector

  -- Nebula
  sector = takeGUID('d5346d', ExtraS3Bag)
  if sector~=nil then Sector2Bag.putObject(sector) end
  Sector2Bag.shuffle()

  sector = takeGUID('40e357', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end

  -- Pulsar
  sector = takeGUID('f8c939', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end
  sector = takeGUID('b91807', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end

  -- SuperNova
  sector = takeGUID('1ad750', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end
  sector = takeGUID('a12f98', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end

  -- Randomly take one black Hole
  sector = SeekAndTake('Sector', ExtraS3Bag)
  if sector~=nil then Sector3Bag.putObject(sector) end

  Sector3Bag.shuffle()
end


-- Adjust the number of outer sectors available based on the number of players
function AdjustOuterSectors(numPlayers)
    local outerSectors = {0, 5, 8, 14, 16, 18}
    local trim = Sector3Bag.getQuantity() - outerSectors[numPlayers]
    if trim > 0 then
        Wait.time(function()
            local s = Sector3Bag.takeObject({rotation = {180,90,0}})
            ExtraS3Bag.putObject(s)
          end,
        0.2, trim)
    end
end


-- Setup the Minor Species expansion
function SetupMinorAmbassadors()
  -- Draw the minor species ambassador tiles
  local pos = Vector(42.1, 1.38, 24.47)
  local aNum = 1
  Wait.time(function()
        local tile = MinorSpeciesBag.takeObject({rotation = {0,-90,0}})
        tile.setPositionSmooth(pos, false, false)
        pos = pos + Vector(0, 0, -2.04)
        aNum = aNum + 1
        if aNum == 3 then pos.z = 24.47 end
        if aNum >= 3 then pos.x = 40.1 end
  end, 0.5, 4)
end


-- remove all game content from the "Rift Cannon" expansion
function RemoveRiftExpansion()
  -- destroy bags of rift dice
  getObjectFromGUID('1ec1c3').destruct()
  getObjectFromGUID('79897f').destruct()
  -- rules
  getObjectFromGUID('634b9c').destruct()

  -- remove the Rift Cannon rare technology
  Object = SeekAndTake('Rift Cannon', TechBag, {position = Vector(0,5,0)})
  if (Object~=false) then Object.destruct() end

  -- remove the Rift Conductor discovery tile
  Object = takeGUID('8990da', DiscoveryBag, {position = Vector(0,5,0)})
  if (Object~=false) then Object.destruct() end
end


-- Main scripting function for round cleanup --
function nextRound(parameters)
  local PlayerColor = parameters.PlayerColor

  if not (settings.setupCompleted) then
    broadcastToColor("Button will become active after the basic game setup has been performed", PlayerColor)
    return false
  end

  local round = tonumber(RoundMarker.getDescription()) + 1
  local newTechs = settings.PlayerCount + 3

  if (round>8) and not(settings.NoRoundLimit) then
    broadcastToAll("-- Game Over --")
    return
  end

  TechBag.shuffle()

  refreshColonyShips()
  refreshPassCards()
  CleanUp()

  rareTechIndex = 0
  Wait.time(drawTech, 0.4, newTechs)  -- repeat drawTech [newTech] times

  RoundMarker.setDescription(round)
  if (round<10) then
    RoundMarker.setPositionSmooth(Vector(42.91, 1.38, 20.83) + Vector(0, 0.4, -1.56*round))
    RoundMarker.setRotationSmooth({0,180,0})
  end
  broadcastToAll(string.format("-- Round #%d --", round))

  -- with the advanced turn order, the pass order decides the next round's turn order
  if (ATO_passOrder() and ATO_newRound(round)) then return end

  Turns.reverse_order = false
  if TurnDirection ~= nil and TurnDirection.is_face_down then
    Turns.reverse_order = true
    broadcastToAll("-- Reverse turn order --")
  end
  STO_newRound()
end


-- configure the visibility of objects usually hidden
function setVisibility(table, isVisible)
    Objects_Visible= isVisible
    local temp_Object
    for _,id in pairs(table) do
      temp_Object= getObjectFromGUID(id)
      if (temp_Object ~= nil) then
        if (Objects_Visible) then
          temp_Object.setInvisibleTo()
        else
          temp_Object.setInvisibleTo({"Blue", "White", "Red", "Yellow", "Green", "Purple", "Teal", "Pink", "Orange", "Brown", "Black"})
        end
      end
  end
end


function toggleVisibility()
  Objects_Visible = (not Objects_Visible)
  setVisibility(BehindTheScenes_GUIDs, Objects_Visible)
end


-- configure if objects are interactable (tables extensions, game board, influence bag, ...)
function setInteractivity(isInteractable)
  Objects_Interactable = isInteractable
  -- skip objects that no longer exist (picked faction buttons destroy themselves)
  for _, list in ipairs({DisabledGUIDs, BehindTheScenes_GUIDs, ButtonGUIDs}) do
    for _, GUID in pairs(list) do
      local object = getObjectFromGUID(GUID)
      if object ~= nil then object.interactable = isInteractable end
    end
  end
end


-- after all factions are selected: remove the selection buttons and the faction display
-- tiles (they are not used after faction selection). The selection mat (ac4050) stays:
-- it becomes the combat zone (scripts/include/CombatZone.ttslua).
local RaceSelection_GUIDs = {
  -- faction display tiles (by column: Eridani, Terran Red, Planta, ...)
  '4f1d06', '9157e7', 'dece33', 'ffd31a',
  'd776b2', '57de7f', 'a7d9af', '81e0b9',
  'ab763d', '00f32d', '3d6ec0', '5b204d',
  'ed7fae', '57f866', 'aa470f', 'a59af5', -- Rho Indi, Exiles, Magellan, Lyra
  'f3dc1f'  -- Pyxis Unity
}

-- (moving them under the table is not enough: that part of the table does not cover them)
function hideRaceSelection()
  for _, list in ipairs({ButtonGUIDs, RaceSelection_GUIDs}) do
    for _, GUID in ipairs(list) do
      local object = getObjectFromGUID(GUID)
      if object ~= nil then object.destruct() end
    end
  end
  CombatZone_show()
end

-- true once hideRaceSelection has removed the faction display tiles
function raceSelectionDone()
  for _, GUID in ipairs(RaceSelection_GUIDs) do
    if getObjectFromGUID(GUID) ~= nil then return false end
  end
  return true
end


function toggleInteractivity()
  setInteractivity(not getObjectFromGUID(BoardBag_GUID).interactable )
end


-- Shuffle all bags and stacks --
function shuffleEverything()
    TechBag.shuffle()
    ReputationBag.shuffle()
    DiscoveryBag.shuffle()
    Sector1Bag.shuffle()
    Sector2Bag.shuffle()
    Sector3Bag.shuffle()
    MinorSpeciesBag.shuffle()
end


-- search a container for all objects with names including "ObjectName", take a random one
function SeekAndTake(ObjectName, ContainerOrGUID, TakeParams)
  if TakeParams == nil then TakeParams = {} end
  TakeParams.guid = '000000'
  local container
  local results = {} -- table of GUIDs
  if type(ContainerOrGUID) == 'string' then
    container = getObjectFromGUID(ContainerOrGUID)
  else
    container = ContainerOrGUID
  end
  for k,v in pairs(container.getObjects()) do
    if string.find(string.lower(v.name==nil and '' or v.name), string.lower(ObjectName)) then
      table.insert(results, v.guid)
    end
  end
  if #results == 0 then return false end

  TakeParams.guid = results[math.random(#results)]
  return container.takeObject(TakeParams)
end


-- safely perform 'take' by first checking if the object exists in the container
function takeGUID(GUID, container, TakeParams)
  if TakeParams == nil then TakeParams = {} end
  if GUID ~= nil then
    TakeParams.guid = GUID
    for _, item in pairs(container.getObjects()) do
      if item.guid == GUID then return container.takeObject(TakeParams) end
    end
  end
  print("Warning: Object " .. TakeParams.guid .. " not found in container. It may have already been removed.", {1,0,0})
end


-- handle basic player setup
function PlayerSetup(parameters)
  PlayerColor = parameters.PlayerColor
  Faction = parameters.Faction

  -- factions are picked in race pick order, one player at a time
  -- (in hot seat the pick is made for the player whose turn it is, whoever clicked)
  -- randomized seats: no faction picks before the seats can be randomized, or while
  -- players are being moved
  if not SEAT_canPickRace(PlayerColor) then return false end
  if not RandomRaces_canPickRace(PlayerColor) then return false end

  local allowed, pickColor = ATO_canPickRace(PlayerColor)
  if not allowed then return false end
  PlayerColor = pickColor

  -- check if the player already selected a faction
  if PlayerSelection[PlayerColor] ~= 'none' then
    print('You already selected ', PlayerSelection[PlayerColor], '. You can only select one faction.')
    return false
  end

  PlayerSelection[PlayerColor] = Faction.Name
  -- hand the pick to the next player once this setup has run (even if part of it fails)
  local pickedColor = PlayerColor
  Wait.time(function() ATO_racePicked(pickedColor) end, 1)
  print(ATO_name(PlayerColor), ' selected ', Faction.Name)

  -- seats randomized after race selection: the faction is set up at the player's new
  -- seat once everyone has picked (ATO_startPlay)
  if SEAT_timing() == "after" and not settings.SeatsRandomized then
    SEAT_addPending(PlayerColor, Faction)
    return true
  end

  placeFaction(PlayerColor, Faction)
  return true
end


-- set up a faction's pieces at a player's seat
function placeFaction(color, faction)
  PlayerColor = color
  Faction = faction

  local Box = getObjectFromGUID(Faction.Box_GUID)
  local PlayerPosition = Player[PlayerColor].getHandTransform(int).position
  PlayerPosition.y = 0.15

  local SpawnPos=Box.getPosition() + Vector(0,5,0)
  local takeParams = {position = SpawnPos, rotation = vector(0,0,0)}

  local InvPos = -1
  if PlayerPosition.z < 0 then
    takeParams.rotation = vector(0,180,0)
    InvPos = 1
  end

  local destination

  -- place homeworld and add population cubes, influence, and the initial ship(s)
  Object = SeekAndTake('Homeworld', Box, takeParams)
  if (Object~=false) then
    placeHomeworld(Object, PlayerPosition, PlayerColor, Faction.Population, Faction.startingShip, Faction.numStartingShips)
  end

  -- take action card and position it
  Object = SeekAndTake('Actions', Box, takeParams)
  if (Object~=false) then
    ATO.actionCards[Object.getGUID()] = PlayerColor
    destination = PlayerPosition + Vector(-16.5*InvPos, 0, 19*InvPos)
    Object.setPositionSmooth(destination, false, true)
  end

  -- take faction overview and position it
  Object = SeekAndTake('Faction Sheet', Box, takeParams)
  if (Object~=false) then
    destination = PlayerPosition + Vector(-16*InvPos, 0, 7*InvPos)
    Object.setPositionSmooth(destination, false, true)
  end

  -- take player board, position it, add influence discs
  local boardGUID = nil
  Object = SeekAndTake('Player Board', Box, takeParams)
  if (Object~=false) then
    boardGUID = Object.getGUID()
    destination = PlayerPosition + Vector(0, 0, 19*InvPos)
    Object.setPositionSmooth(destination, false, true)
    -- place influenbce discs, once the board is in place
    local funcInfluenceSetup = function() setupPlayerInfluence(Object, PlayerColor, Faction.Influence-1) end
    triggerFunctionIfResting(Object, funcInfluenceSetup)
    triggerFunctionIfResting(Object, TechTrack_reconcile)
    local board = Object
    triggerFunctionIfResting(Object, function() CombatSim_addButton(board) end)

    if (Faction.Name =='Wardens of Magellan') then
      local funcMagellanSetup  = function() setupMagellan(Object, InvPos) end
      triggerFunctionIfResting(Object, funcMagellanSetup)
    end
  end

  -- Place control board, enable resource tracking
  local BoardPosition = PlayerPosition + Vector(0, 0, 7*InvPos)
  BoardPosition.y= 0.12
  -- check for a custom control boards otherwise use default
  local ControlBoard
  ControlBoard = SeekAndTake('Control Board', Box, takeParams)
  if (ControlBoard==false) then
    local BoardBag = getObjectFromGUID(BoardBag_GUID)
    ControlBoard= BoardBag.takeObject(takeParams)
  end
  ControlBoard.setPositionSmooth(BoardPosition, false, true)
  local funcSpawnTokens  = function() ControlBoard_SpawnTokens(PlayerColor, Faction, ControlBoard, InvPos, takeParams.rotation) end
  triggerFunctionIfResting(ControlBoard, funcSpawnTokens, 1)

  -- take ambassador tiles and position them
  PlaceAmbassadors(Box, takeParams, PlayerPosition)

  -- place colony ships
  PlaceColonyShips(Faction.colonyShips, takeParams, PlayerPosition)

  -- fleet setup
  local numInterceptors = 8
  local numCruisers = 4
  local numDreadnoughts = 2
  if (Faction.startingShip == 'interceptor') then numInterceptors=numInterceptors-Faction.numStartingShips end
  if (Faction.startingShip == 'cruiser') then numCruisers=numCruisers-Faction.numStartingShips end

  PlaceFleet(PlayerPosition, PlayerColor, numInterceptors, numCruisers)
  
  -- Place a separate 'Shrine Board' for the Enlightened of Lyra
  if (PlayerSelection[PlayerColor] == "Enlightened of Lyra") then
    -- take action card and position it
    local ShrineBoard = SeekAndTake('Shrine Board', Box, takeParams)
    if (ShrineBoard~=false) then
      destination = PlayerPosition + Vector(16.5*InvPos, 0, 7.5*InvPos)
      ShrineBoard.setPositionSmooth(destination, false, true)
      ShrineBoard.setLock(true)
    end

    -- place 3x3 shrines
    local ShrinePosition= PlayerPosition + Vector(13.83*InvPos, 1, 9.63*InvPos)
    for z=0,2 do
      for x=0,2 do
        PlaceShip('shrine', ShrinePosition  + Vector(x*2.2*InvPos, 0, z*(-2.4)*InvPos), Vector(0,0,0), PlayerColor)
      end
    end
  end

  PlayerState_record(PlayerColor, Faction.Name, boardGUID)
  ShipState_init(PlayerColor, Faction.Name)
  return true
end


function ControlBoard_SpawnTokens(PlayerColor, Faction, board, Inv, RotationVec)
  local BoardPosition = board.getPosition()
  local OffsetY = 0.1
  board.setLock(true)

  if (Faction.Name =='Pyxis Unity') then 
    spawnResourceMarker(3, BoardPosition, 8, OffsetY)
    placePopulationPyxis(BoardPosition, PlayerColor, 360-RotationVec.y, Inv)
    return true 
  end

  -- place population cubes (Materials, Science, Money)
  placePopulationWheel(Faction.PlacedMat, 11, BoardPosition, 0.0,     7*Inv, PlayerColor, 360-RotationVec.y)
  placePopulationWheel(Faction.PlacedSci, 11, BoardPosition, 4.9*Inv, 7*Inv, PlayerColor, 360-RotationVec.y)
  placePopulationWheel(Faction.PlacedMon, 11, BoardPosition, 9.8*Inv, 7*Inv, PlayerColor, 360-RotationVec.y)
  
  -- place resource markers
  local materials=0
  local science=0
  local money=0
  
  if Faction.materials~=nil then materials=Faction.materials end
  if Faction.science~=nil then science=Faction.science end
  if Faction.money~=nil then money=Faction.money end
  
  spawnResourceMarker(2, BoardPosition, money, OffsetY)
  if materials == money then OffsetY=0.8 end
  spawnResourceMarker(0, BoardPosition, materials, OffsetY)
  if science == materials  or science==money then OffsetY = 0.8 end
  if science == materials and science==money then OffsetY = 1.3 end
  spawnResourceMarker(1, BoardPosition, science, OffsetY)
end


-- Magellan: Draw a random discovery tile and place it on the player board
function setupMagellan(PlayerBoard, InvPos)
  local BoardPosition = PlayerBoard.getPosition()
  --local TileRotation = Vector(180, InvPos*(-45), 0)
  local TileRotation = Vector(180, 315, 0)
  if (InvPos<0) then TileRotation.y= 135 end

  local takeParams = {rotation = TileRotation, smooth=true}

  local d = DiscoveryBag.takeObject(takeParams)
  d.setPositionSmooth(BoardPosition+Vector(InvPos*2.95, 1.5, InvPos*1.3), false, true)
end


-- place colony ships in front of the player
function PlaceColonyShips(number, TakeParams, PlayerPosition)
  local Object
  local offset

  local Inv = -1;
  if PlayerPosition.z < 0 then Inv=1 end

  local StartPosition = PlayerPosition + Vector(-22.4*Inv, 0, 14*Inv)
  if number ~= 3 then StartPosition = StartPosition + Vector(1.45*Inv, 0, 0) end
  if number > 3 then StartPosition = StartPosition + Vector(0, 0, 1*Inv) end

  for i=1,number do
      Object= getObjectFromGUID(ColonyShipTemplate_GUID).clone()
      Object.setRotation(TakeParams.rotation)
      Object.setLock(false)

      if i>2 and number>3 then offset = Vector((i-2)*2.9*Inv, 0, -2*Inv)
      else offset = Vector(i*2.9*Inv, 0, 0) end
      Object.setPositionSmooth(StartPosition + offset, false, true)
  end
end


-- search a container for all ambassadors and place them in front of the player
function PlaceAmbassadors(Container, TakeParams, PlayerPosition)
  TakeParams.guid = '000000'
  local guids = {}
  local Object
  local offset

  for k,v in pairs(Container.getObjects()) do
    if string.find(string.lower(v.name or v.nickname), string.lower('Ambassador')) then
      table.insert(guids, v.guid)
    end
  end

  if #guids == 0 then return false end

  local Inv = -1;
  if PlayerPosition.z < 0 then Inv=1 end
  local StartPosition =  PlayerPosition + Vector(13.9*Inv, 0, 24.2*Inv)

  if #guids < 3 then StartPosition.x = StartPosition.x + (1.3*Inv) end
  if #guids > 3 then StartPosition.x = StartPosition.x + (-1.1*Inv) end

  for k,id in pairs(guids) do
      TakeParams.guid = id
      Object = Container.takeObject(TakeParams)

      offset = Vector((k-1)*2.5*Inv, 0, 0)
      Object.setPositionSmooth(StartPosition + offset, false, true)
  end
end


-- spawn a ship based on existing template (interceptor, cruiser, starbase, ...)
function PlaceShip(ShipType, Position, Rotation, Color)
  local colorRGB = stringColorToRGB(Color)
  if (ShipType=='cruiser') then Rotation = Rotation + Vector(0, 180, 0) end

  local entity = nil
  if (ShipType=='interceptor') then entity = getObjectFromGUID(InterceptorTemplate_GUID).clone() end
  if (ShipType=='cruiser') then entity = getObjectFromGUID(CruiserTemplate_GUID).clone() end
  if (ShipType=='dreadnought') then entity = getObjectFromGUID(DreadnoughtTemplate_GUID).clone() end
  if (ShipType=='starbase') then entity = getObjectFromGUID(StarbaseTemplate_GUID).clone() end
  if (ShipType=='deathmoon') then entity = getObjectFromGUID(DeathmoonTemplate_GUID).clone() end
  if (ShipType=='shrine') then entity = getObjectFromGUID(ShrineTemplate_GUID).clone() end

  if (entity == nil) then return false end

  entity.setColorTint(colorRGB)
  entity.setDescription(Color)
  ShipState_markShip(entity, ShipType, Color)
  entity.setRotation(Rotation)
  entity.setPosition(Position)
  entity.setLock(false)

  return true
end


-- Spawn unused ships and starbases available to a faction and place them in front of the player
function PlaceFleet(PlayerPosition, PlayerColor, numInterceptors, numCruisers)
  numInterceptors= numInterceptors or 8
  numCruisers= numCruisers or 4

  local Inv = -1;
  local RotationVec = Vector(0,180,0)
  if PlayerPosition.z < 0 then
    Inv=1
    RotationVec.y = 0
  end

  local StartPosition = PlayerPosition + Vector(12.9*Inv, 0.3, 11*Inv)
  local position
  colorRGB = stringColorToRGB(PlayerColor)

  local OffsetX = 0
  --  Rho Indi does not have dreadnoughts -> layout changes
  if (PlayerSelection[PlayerColor] == "Rho Indi Syndicate") then OffsetX = 0.7*Inv end

  -- place 2 collumns of interceptors
  for i=0, (numInterceptors-1) do
    if (i<(numInterceptors/2)) then position = StartPosition + Vector(OffsetX * 1.2 + 1.8*Inv, 0, (4.5+i*2.2)*Inv)
    else position = StartPosition + Vector(OffsetX, 0, (4.5+(i-(math.ceil(numInterceptors/2)))*2.2)*Inv) end
    PlaceShip('interceptor', position, RotationVec, PlayerColor)
  end

  -- place cruisers
  for i=0, (numCruisers-1) do
    position = StartPosition + Vector(OffsetX*2.5 + 4.3*Inv, 0, (4.5 + i*2.21)*Inv)
    PlaceShip('cruiser', position, RotationVec, PlayerColor)
  end

  -- place star bases / Deathmooons (Pyxis Unity), unless Exiles were selected
  if (PlayerSelection[PlayerColor] ~= "The Exiles") then
    for i=0, 3 do
      position = StartPosition + Vector(i*2.4*Inv, 0, 2*Inv)
      if (PlayerSelection[PlayerColor] == "Pyxis Unity") then
        PlaceShip('deathmoon', position, RotationVec, PlayerColor)
      else
        PlaceShip('starbase', position, RotationVec, PlayerColor)
      end
    end
  end

  -- place dreadnoughts, unless Rho Indi was selected
  if (PlayerSelection[PlayerColor] ~= "Rho Indi Syndicate") then
    for i=0, 1 do
      position = StartPosition + Vector(7.1*Inv, 0, (5.5+ i*4)*Inv)
      PlaceShip('dreadnought', position, RotationVec, PlayerColor)
    end
  end

end


function setupPlayerInfluence(board, PlayerColor, numInfluence)
  numInfluence = numInfluence or 12

  board.setLock(true)
  local InfluenceBag= getObjectFromGUID(InfluenceDisks_GUID)

  local InvPos = getInvertFactor(board)
  local Pos=board.getPosition() + Vector(8.66*InvPos, 0.5, -5.6*InvPos)

  -- place influence disks
  for i=0, (numInfluence-1) do
    Disk = InfluenceBag.takeObject({guid=1})
    Disk.setColorTint(PlayerColor)
    Disk.setPosition(Pos)
    Pos.x = Pos.x - 0.99*InvPos
  end

  -- spawn bag for additional influence discs
  local bagSpawnParams = {
           type = "Bag",
           position    = board.getPosition() + Vector(16*InvPos, 0.11, -13.5*InvPos),
           rotation    = {x=0, y=0, z=0},
           sound       = false}
  local numDiscs=3

  --  Enlightened of Lyra have 1 more influence disc and different placing
  if (PlayerSelection[PlayerColor] == "Enlightened of Lyra") then
    numDiscs=4
    bagSpawnParams.position = board.getPosition() + Vector(9.8*InvPos, 0.11, -8.2*InvPos)
  end

  local bag = spawnObject(bagSpawnParams)
  bag.setName('Extra Influence Discs')
  bag.setColorTint(PlayerColor)

  -- place additional influence discs into the bag
  local takeParams = {guid=1}
  takeParams.position = bag.getPosition()+Vector(0, 2, 0)
  takeParams.smooth = false
  if (numInfluence>12) then numDiscs=2 end
  for i=0, (numDiscs-1) do
    Disk = InfluenceBag.takeObject(takeParams)
    Disk.setColorTint(PlayerColor)
    bag.putObject(Disk)
  end

  spawnInfluenceButton(board)
end


-- Spawns the Return Influence button underneath each player's board
function spawnInfluenceButton(board)

  local data = {
    click_function = "returnInfluenceDiscs",
    function_owner = self,
    label = "Return Influence",
    position = {-1.18, 0.09, 1.06},
    scale = {0.3, 0.3, 0.3},
    width = 955,
    font_size = 110,
    color = {0.7573, 0.7573, 0.7573, 1}
  }

  board.createButton(data)
end


-- return used influece discs on the board
function returnInfluenceDiscs(board)
  local discs = getUsedInfluence(board)
  local InvPos = getInvertFactor(board)
  local index = 1
  local position = board.getPosition()
  for _, disc in pairs(discs) do
    index = getEmptyInfluencePosition(board, index)
    disc.setPositionSmooth(position  + Vector(9.65*InvPos - 0.99*index*InvPos, 0.5, -5.6*InvPos), false, true)
    index = index+1
  end
end


-- return the first available spot for an influence disc on a player board
function getEmptyInfluencePosition(board, startindex)
  local InvPos = getInvertFactor(board)

  -- check influnce positions
  for i=startindex, 13 do
    local Pos=board.getPosition() + Vector(9.65*InvPos - 0.99*i*InvPos, 0.5, -5.6*InvPos)
    if (checkForTaggedObjects(Pos, 'Influence') == nil) then return i end
  end
  return 13
end


-- return a table of all influenced discs on the board used for actions
function getUsedInfluence(board)
    if board == nil then return {} end
    local InvPos = getInvertFactor(board)

    -- get all influence discs on the player board (box cast)
    local boardObjects = Physics.cast({
        origin = board.getPosition() + vector(-7.77*InvPos, 0, -5.25*InvPos),
        type = 3, -- box
        direction = {0,1,0},
        max_distance = 5,
        size = {7.40, 1.69, 2.36},
        debug = DebugMode
    })
    local discs = objectsHitByCast(boardObjects, 'Influence Disc')

    -- get all discs on the reaction board
    local reactionObjects = Physics.cast({
        origin = board.getPosition() + vector(-16.5*InvPos, 0, 0),
        type = 3,
        direction = {0,1,0},
        max_distance = 5,
        size = {4, 1.69, 6},
        debug = DebugMode
    })
    local reactionDiscs = objectsHitByCast(reactionObjects, 'Influence Disc')

    -- Merge all results into one table
    for _, v in ipairs(reactionDiscs) do table.insert(discs, v) end
    return discs
end


-- create a population cube and place it
function createPopulationCube(Position, Rotation, Color, GridSnap)
  local spawnParams = {
           type = "BLOCKSQUARE",
           position          = Position,
           rotation          = Rotation,
           scale             = {x=.5, y=.5, z=.5},
           sound             = false,
           snap_to_grid      = GridSnap
       }

  -- create and place population cube
  local cube = spawnObject(spawnParams)
  cube.use_grid=GridSnap
  cube.setName('Population')
  cube.setColorTint(Color)
  cube.addTag("Population")
  return cube
end


-- place one wheel of population cubes
function placePopulationWheel(Missing, Max, BoardPosition, OffsetX, OffsetZ, PlayerColor, rotationY)
  local cubeOffsets = { {x = 7.14, z = 7.98}, {x = 6.44, z = 8.72},
  {x = 5.58, z = 9.05}, {x = 4.54, z = 8.93}, {x = 3.78, z = 8.39},
  {x = 3.31, z = 7.55}, {x = 3.32, z = 6.50}, {x = 3.76, z = 5.66},
  {x = 4.55, z = 5.11}, {x = 5.59, z = 4.96}, {x = 6.49, z = 5.32} }

  for i=12-Max, 11-Missing, 1 do
    local rotation = math.rad(rotationY)
    local cubeX = (cubeOffsets[i].x * math.cos(rotation)) - (cubeOffsets[i].z * math.sin(rotation))
    local cubeZ = (cubeOffsets[i].x * math.sin(rotation)) + (cubeOffsets[i].z * math.cos(rotation))

    local Position= vector(BoardPosition.x+cubeX+OffsetX, 0.5, BoardPosition.z+cubeZ+OffsetZ)
    local cube= createPopulationCube(Position, {x=0, y=90, z=0}, PlayerColor, true)

    -- disable grid after the initial placement
    local UnGrid = function() cube.use_grid=false end
    triggerFunctionIfResting(cube, UnGrid)
  end
end


-- place population for Pyxis
function placePopulationPyxis(BoardPosition, PlayerColor, rotationY, Inv)
  local cubeX = BoardPosition.x - 4.7*Inv
  local cubeZ = BoardPosition.z + 2.1 *Inv
  
  -- horizontal lines
  for z=1, 2, 1 do
    for i=0, 10, 1 do
      local Position= vector(cubeX+0.9*i*Inv, 0.5, cubeZ)
      local cube= createPopulationCube(Position, {x=0, y=-90, z=0}, PlayerColor, false)
    end
    cubeZ= cubeZ - 4.2*Inv
  end

  placePopulationWheel(1, 2, BoardPosition, 0.0,     7*Inv, PlayerColor, rotationY)
  placePopulationWheel(8,11, BoardPosition, 0.0,     7*Inv, PlayerColor, rotationY)
  placePopulationWheel(2, 8, BoardPosition, 9.8*Inv, 7*Inv, PlayerColor, rotationY)

end


-- generate a resource marker (0=Materials, 1= Science, 2=Money) and position it
function spawnResourceMarker(type, boardPos, amount, offsetY)
  local position=boardPos
  local Inv= -1
  if position.z < 0 then Inv=1 end

  local OffsetX = -6.9*Inv + amount*0.91*Inv
  local OffsetZ = 3.45*Inv

  local marker = getObjectFromGUID(ResourceTemplate_GUID)
  local newMarker = marker.clone()

  if type==0 then
    newMarker.setColorTint({131/255, 77/255, 40/255})
    newMarker.setName("Materials")
  end

  if type==1 then
    newMarker.setColorTint({245/255, 112/255, 206/255})
    newMarker.setName("Science")
  end

  if type==2 then
    newMarker.setColorTint({255/255, 134/255, 50/255})
    newMarker.setName("Money")
  end

  if type==3 then
    newMarker.setName("Transmatter")
  end

  newMarker.setLock(false)

  if amount>15 and amount<24 then
    if amount==16 or amount==23 then
      OffsetX = -7.18*Inv + 16*0.91*Inv
    else OffsetX = -7*Inv + 16*0.91*Inv end
    OffsetZ = 3*Inv - (amount-16) *0.86*Inv
  end

  if amount>23 then
    OffsetX= 6.75*Inv - ((amount-24)*0.91*Inv)
    OffsetZ=-3.4*Inv
  end

  newMarker.setPosition(position + Vector(OffsetX, offsetY, OffsetZ))
end


-- delay execution of a function until an object is resting
function triggerFunctionIfResting(objTile, pointerFnc, waitSeconds)
  waitSeconds = waitSeconds or 1
  Wait.time( function()
          Wait.condition(pointerFnc, function() return objTile.resting end)
      end, waitSeconds )
end


-- place a player's starting sector
function placeHomeworld(homeworld, PlayerPos, PlayerColor, Population, ShipType, NumShips)
  NumShips= NumShips or 1
  local InvZ =1
  if PlayerPos.z < 0 then InvZ = -1 end

  local Pos = vector(0, 1, 11.92)
  local Rotation = vector(0, -60, 0)

  if PlayerPos.x > 5 then
    Pos.x = 10.32
    Rotation = vector(0, 60, 0)
  end

  if PlayerPos.x<-5 then Pos.x = -10.32 end

  if (PlayerPos.z<0) and (PlayerPos.x<-5) then Rotation.y = 240 end
  if (PlayerPos.z<0) and (PlayerPos.x>5) then Rotation.y = 120 end

  Pos.z = InvZ*5.96
  if (PlayerPos.x > -1) and (PlayerPos.x < 1) then
     Pos.z = InvZ*11.92
     if Pos.z<-1 then Rotation = vector(0, 180, 0)
     else Rotation = vector(0, 0, 0) end
  end

  homeworld.setRotation(Rotation)
  homeworld.setPosition(Pos)
  triggerFunctionIfResting(homeworld, function () homeworld.setLock(true) end)

  -- place influence disks
  local InfluenceBag= getObjectFromGUID(InfluenceDisks_GUID)
  local takeParams = {guid=1}
  local  Disk = InfluenceBag.takeObject(takeParams)
  Disk.setColorTint(PlayerColor)
  Disk.setPosition(Pos + vector(0, 0.5, 0))

  -- used to calculate roitated positions
  local NewPos
  local ItemPos

  -- place population cubes
  if (Population ~= nil) then
    for i=1, #Population, 1 do
      NewPos = calculateRotationOffset(Rotation.y, {x=Pos.x, z=Pos.z}, {x=Population[i].x, z=Population[i].z})
      ItemPos= vector(NewPos.x, 1.2, NewPos.z)
      createPopulationCube(ItemPos, Object.getRotation(), PlayerColor, false)
    end
  end

  -- place starting ship(s)
  local offsetX = -2.2
  local offsetZ = 0

  for i=1, NumShips, 1 do
      if (i==2) then
        offsetX=1.5
        offsetZ=-1.2
      end

      if (ShipType=='cruiser') then offsetX = offsetX + 0.25 end
      NewPos = calculateRotationOffset(Rotation.y, {x=Pos.x, z=Pos.z}, {x=offsetX, z=offsetZ})
      ItemPos= vector(NewPos.x, 1.2, NewPos.z)
      PlaceShip(ShipType, ItemPos, Rotation + vector(0, 180, 0), PlayerColor)
  end

end


-- Y rotate around a specified center
function calculateRotationOffset(rotation, base, offset)
    rotation = 360 - rotation
    rotation = math.rad(rotation)

    x3 = (offset.x * math.cos(rotation)) - (offset.z * math.sin(rotation))
    z3 = (offset.x * math.sin(rotation)) + (offset.z * math.cos(rotation))

    return {x = base.x + x3, z = base.z + z3}
end


-- remove all damage cubes and dice from the table area
function CleanUp()
  zoneObjects = TableZone.getObjects()
  for _,obj in pairs(zoneObjects) do
      if ((obj.getName()=="Damage Cube") or (obj.hasTag('Dice')))
      then destroyObject(obj) end
  end
end


-- Unflip all colony ships --
function refreshColonyShips()
    for _,obj in pairs(getAllObjects()) do
        if (obj.getName() == "Colony Ship" and obj.is_face_down)
        then obj.flip() end
    end
end


-- Unflip all action / pass cards
function refreshPassCards()
    for _,obj in pairs(getAllObjects()) do
        if (obj.getName() == "Actions" and obj.is_face_down)
        then obj.flip() end
    end
end


-- Draw and annouce each tech tile --
function drawTech()
    if TechBag.getQuantity() < 1 then return end
    local t = TechBag.takeObject({rotation = {0,270,0}})

    -- identify type (nano, grid, military, rare) and announce thr drawn tech
    local type = string.sub(t.getName(),1,1)
    local tColor = { M = {1, 0.7, 0.8},
                     G = {0.7, 1, 0.7},
                     N = {1, 1, 0.7},
                     R = {0.7, 0.8, 1}}
    printToAll(string.format("New %s", t.getName()), tColor[type])

    if type == 'R' then
        placeRareTech(t)
        Wait.time(drawTech, 0.2, 1) -- draw another, rare techs don't count
    else placeTech(t, type) end

end


-- PLace a tech tiles on its technology track spot
function placeTech(tech, type)
    local xBase = {M=40.95, G=39.10, N=37.25}  -- x position, type-dependant
    local text = string.sub(tech.getDescription(), 2,3)
    local num = tonumber(text) - 1
    local z = 19.35 + (-1.814 * num) -- base + (offset * tiles)
    tech.setPositionSmooth(Vector(xBase[type], 3.3, z), false, false)
end


-- place a rare tech on the first unoccupied slot for rare technologies
function placeRareTech(t)
  local x = 34.65
  local z = 19.352 - (1.814*rareTechIndex)
  local position = Vector(x, 1.3, z)

  for i=rareTechIndex, 24 do
    if (rareTechIndex<16) then x = 34.65 else x=32.7 end
    position = Vector(x, 1.3, 19.352 - (1.814*(rareTechIndex%15)))
    rareTechIndex = rareTechIndex + 1
    if (checkForTaggedObjects(position, 'TechTile') ==nil) then break end
  end
  t.setPositionSmooth(position+vector(0, 2, 0), false, false)
end


-- Stop players from accidentally taking a stack of techs --
function onObjectPickUp(player, obj)
    ShipState_onPickUp(obj)
    HexState_onPickUp(obj)
    ActionAnnounce_onPickUp(obj)
    if obj.tag == "Chip" and obj.getQuantity() > 1 then
        if string.find(obj.getName(), "Tech %-") != nil then
            obj.drop()
            obj.setVelocity(Vector(0,0,0))
        end
    end
end


-- Put unchosen reputation tiles back into the bag --
function discardRep(obj)
    if obj != nil then
        if obj.getName() == "Reputation" then
            obj.setRotation(Vector(0,270,180))
            ReputationBag.putObject(obj)
            Wait.time(function() ReputationBag.shuffle() end, 0.5, 1)
        end
    end
end


-- Blip the size of sector hexes so they fit together --
function onObjectDrop(player_color, obj)
    if obj.use_grid == true then
        Wait.condition(
            function() blip(obj) end,
            function() return rest(obj) end,
            2)
    end
    watchSector(obj)
    stopSectorWatchUnder(obj)
    ShipState_onDrop(obj)
    HexState_onDrop(obj)
    TechTrack_onDrop(player_color, obj)
    ActionAnnounce_onDrop(obj)
end

function onObjectDestroy(obj)
    ShipState_onDestroy(obj)
    HexState_onDestroy(obj)
    TechTrack_onDestroy(obj)
end

function onObjectSpawn(obj)
    ShipState_onSpawn(obj)
    HexState_onSpawn(obj)
end


-- Populate explored sectors --------------------------------------------------
-- When a sector tile is placed and locked, its discovery tile (face down) and
-- its ancient / guardian ships are put on it automatically.
-- Sector number -> what the tile shows in its centre (read from the tile art).
local SectorContents = {
  -- Sector I
  ['101'] = {ancients = 1}, ['104'] = {ancients = 2}, ['105'] = {ancients = 1},
  ['108'] = {ancients = 1}, ['109'] = {ancients = 2}, ['110'] = {},
  -- Sector II
  ['203'] = {ancients = 2}, ['204'] = {ancients = 1}, ['211'] = {ancients = 1},
  ['214'] = {ancients = 1}, ['206'] = {}, ['207'] = {}, ['208'] = {}, ['281'] = {},
  -- Guardian sectors
  ['271'] = {guardians = 1}, ['272'] = {guardians = 1},
  ['273'] = {guardians = 1}, ['274'] = {guardians = 1},
  -- Sector III
  ['301'] = {ancients = 2}, ['302'] = {ancients = 1}, ['303'] = {ancients = 1},
  ['305'] = {ancients = 1}, ['311'] = {}, ['312'] = {}, ['313'] = {}, ['314'] = {},
  ['315'] = {}, ['316'] = {}, ['381'] = {}, ['382'] = {},
}
-- every entry above has a discovery tile; ships go on top of it

local WatchedSectors = {}   -- GUID -> true: dropped, waiting to be locked
local SectorWatchTimer = nil

function isSectorTile(obj)
  local name = obj.getName()
  return name == "Sector 1" or name == "Sector 2" or name == "Sector 3"
      or name == "Guardian Sector"
end

function isSectorPopulated(guid)
  return table.contains(settings.PopulatedSectors or {}, guid)
end

-- a discovery tile or an ancient / guardian ship dropped on a watched sector means the
-- players are filling it by hand: stop watching it, and never fill it automatically
local SECTOR_DROP_RADIUS = 5.5   -- a little less than the hex's inner radius (5.96)

function stopSectorWatchUnder(obj)
  if next(WatchedSectors) == nil then return end
  if obj.type == "Infinite" or obj.type == "Bag" then return end
  if not (obj.getName() == "Discovery" or obj.hasTag("Discovery")
          or obj.hasTag("Ancient") or obj.hasTag("Guardian")) then return end

  local p = obj.getPosition()
  for guid in pairs(WatchedSectors) do
    local sector = getObjectFromGUID(guid)
    if sector ~= nil then
      local s = sector.getPosition()
      local dx, dz = p.x - s.x, p.z - s.z
      if dx * dx + dz * dz < SECTOR_DROP_RADIUS * SECTOR_DROP_RADIUS then
        WatchedSectors[guid] = nil
        settings.PopulatedSectors = settings.PopulatedSectors or {}
        table.insert(settings.PopulatedSectors, guid)
      end
    end
  end
end

function watchSector(obj)
  if not settings.setupCompleted or not isSectorTile(obj) then return end
  if SectorContents[HexState_baseDescription(obj)] == nil then return end
  if isSectorPopulated(obj.getGUID()) then return end
  WatchedSectors[obj.getGUID()] = true
  if SectorWatchTimer == nil then
    SectorWatchTimer = Wait.time(checkWatchedSectors, 0.5, -1)
  end
end

function checkWatchedSectors()
  local remaining = false
  for guid in pairs(WatchedSectors) do
    local obj = getObjectFromGUID(guid)
    if obj == nil or isSectorPopulated(guid) then
      WatchedSectors[guid] = nil      -- put back in a bag, or already done
    elseif obj.getLock() and obj.held_by_color == nil and not obj.is_face_down then
      WatchedSectors[guid] = nil
      populateSector(obj)
    else
      remaining = true
    end
  end
  if not remaining then
    Wait.stop(SectorWatchTimer)
    SectorWatchTimer = nil
  end
end

-- the infinite bag of ancient / guardian ships that setup left on the table
function findShipSource(tag)
  for _, o in ipairs(getObjectsWithTag(tag)) do
    if o.type == "Infinite" then return o end
  end
  return nil
end

function populateSector(sector)
  local number = HexState_baseDescription(sector)   -- without HexState's combat tooltip
  local contents = SectorContents[number]
  settings.PopulatedSectors = settings.PopulatedSectors or {}
  table.insert(settings.PopulatedSectors, sector.getGUID())

  local center = sector.getPosition()
  local yaw = sector.getRotation().y

  if DiscoveryBag ~= nil and DiscoveryBag.getQuantity() > 0 then
    DiscoveryBag.takeObject({
      position = center + Vector(0, 0.5, 0),
      rotation = {180, yaw, 0},
      smooth = false })
  else
    broadcastToAll("No discovery tiles left for sector " .. number, {1, 0.5, 0})
  end

  local ships = contents.ancients or contents.guardians or 0
  if ships == 0 then return end
  local tag = contents.ancients and "Ancient" or "Guardian"
  local source = findShipSource(tag)
  if source == nil then
    broadcastToAll("Could not find the " .. tag .. " ships to place on sector " .. number, {1, 0.5, 0})
    return
  end
  -- two ships are stacked, the top one shifted slightly so both stay visible
  -- (about 80% overlap), in the sector's own orientation
  local offsets = (ships == 1) and {0} or {-0.15, 0.15}
  local r = math.rad(yaw)
  for i, dx in ipairs(offsets) do
    local offset = Vector(dx * math.cos(r), 0, -dx * math.sin(r))
    -- wait a moment so each ship lands on top of the discovery tile
    Wait.time(function()
      source.takeObject({
        position = center + offset + Vector(0, 1 + 0.5 * i, 0),
        rotation = {0, yaw, 0},
        smooth = false })
    end, 0.3 * i)
  end
end

--
function blip(obj)
    obj.scale(24/25)
    Wait.time(function() obj.scale(25/24) end, 0.1)
end


function rest(obj)
    if obj != nil then return obj.resting end
    return false
end


-- Print a message to all players, but only broadcast to the target
function targetMessage(msg, TextRGB, target_color)
    for _, player in ipairs(Player.getPlayers()) do
        if player.color == target_color then
            player.broadcast(msg, TextRGB)
        else
            player.print(msg, TextRGB)
        end
    end
end


-- cast a ray to the specified position, return hits with the tag
function checkForTaggedObjects(position, tag, distance, single_result)
    if (position == nil) then print("WARNING: checkForTaggedObjects used without position") end
    -- default configuration: return only the first result, max distace=10
    local single_result = single_result or true
    local dist = distance or 10

    local CastResults = Physics.cast({
        origin = (Vector(position) + Vector(0,5,0)),
        direction = {0, -1, 0}, max_distance = dist,
        type = 1, -- Ray (1 =Ray, 2=Sphere, 3=Box)
        debug = DebugMode })

    local taggedObjects = {}
    for _, v in pairs(CastResults) do
        if v['hit_object'].hasTag(tag) then
            if single_result == true then return v['hit_object'] end
            table.insert(taggedObjects, v['hit_object'])
        end
    end

    if single_result then return nil end
    return taggedObjects
end


-- returns a subset of elements from a table based on a given name or tag
function objectsHitByCast(castResult, name, tag)
    if castResult == nil then return {} end

    local objects = {}
    for _, obj in ipairs(castResult) do
        if (obj['hit_object'].getName() == name or
            (tag ~= nil and obj['hit_object'].hasTag(tag))) then
            table.insert(objects, obj['hit_object'])
        end
    end
    return objects
end


-- check if a given element is part of the table
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then return true end
  end
  return false
end


-- identify the side of a table an object is located on
function getInvertFactor(object)
    if object.getPosition().z > 0 then return -1
    else return 1 end
end


-- ROTATING TURN ORDER --
-- The base game's turn order: clockwise from the start player, during play.
-- (Setup and race selection are run by the turn order code below, ATO_*, for both turn
-- orders.) Passing is tracked too: a player passes by flipping
-- their "Actions" card face down. The first player to pass gets the start player tile
-- and starts the next round, the second gets the "Direction of Play" card and chooses
-- the direction by flipping it. A small "Passed" list at the top right shows the order.
-- TTS's built-in turns are always on once the game has started, so there is always a
-- current player (passing, action announcements).

function STO_active()
  return settings.setupCompleted and not ATO_passOrder() and not ATO_inSetup()
end

-- switch on the built-in turns in clockwise table order, keeping the current turn (TTS
-- picks its own turn a few frames after turns are enabled or the order changes, so the
-- current one is set again with STO_setTurn)
function STO_enableTurns(current)
  current = current or Turns.turn_color
  local changed = false
  if not Turns.enable then
    Turns.enable = true
    Turns.pass_turns = true
    changed = true
  end
  -- saves made with TTS's automatic order: switch to the table order
  if Turns.type ~= 2 then
    Turns.type = 2
    Turns.order = STO_seatedOrder()
    changed = true
  end
  if changed and current ~= nil and current ~= "" then STO_setTurn(current) end
end

function STO_pass(color, card, flipper)
  settings.PassOrder = settings.PassOrder or {}
  if table.contains(settings.PassOrder, color) then return end

  -- when the built-in turns are used, passing is only allowed during your own turn
  local current = Turns.turn_color
  if Turns.enable and current ~= nil and current ~= "" and current ~= color then
    broadcastToColor("You can only pass during your own turn. It is " .. ATO_name(current) .. "'s turn.",
      flipper or color, {1, 0.4, 0.4})
    Wait.time(function()
      if card ~= nil and card.is_face_down and not table.contains(settings.PassOrder, color) then card.flip() end
    end, 1)
    return
  end

  table.insert(settings.PassOrder, color)
  local position = #settings.PassOrder
  if position == 1 then
    broadcastToAll(ATO_name(color) .. " passes first and takes the start player tile for the next round.", color)
    placeFirstPlayerTile(color)
  elseif position == 2 then
    broadcastToAll(ATO_name(color) .. " passes second and takes the Direction of Play card: flip it to choose the next round's direction.", color)
    STO_giveDirectionCard(color)
  else
    broadcastToAll(string.format("%s passes (#%d).", ATO_name(color), position), color)
  end

  if position >= #ATO_seatedPlayers() then
    broadcastToAll("All players have passed. Finish the round and press 'Next Round'.")
  end

  -- passing ends the turn
  if Turns.enable and Turns.turn_color == color then
    local nextColor = Turns.getNextTurnColor()
    if nextColor ~= nil and nextColor ~= "" and nextColor ~= color then Turns.turn_color = nextColor end
  end
  ATO_updateUI()
end

-- move the Direction of Play card in front of the given player, next to where the
-- start player tile goes, keeping the side it shows
function STO_giveDirectionCard(color)
  if TurnDirection == nil or Player[color] == nil then return end
  local hand = Player[color].getHandTransform()
  if hand == nil then return end
  local position = hand.position
  local inv = (position.z < 0) and 1 or -1
  local rotation = TurnDirection.getRotation()
  TurnDirection.setPositionSmooth(Vector(position.x - 4 * inv, 1.2, position.z + 28 * inv), false, false)
  TurnDirection.setRotationSmooth({rotation.x, (inv + 1) * 90, rotation.z}, false, false)
end

-- Direction of Play card, right click: apply the side it shows now to the current round
-- the seats around the table, clockwise (fixed). TTS's automatic turn order uses another
-- color sequence, so the rotating order is a custom turn order (Turns.type 2).
local STO_COLOR_ORDER = {"Yellow", "Red", "Green", "Blue", "Purple", "White"}

-- the seated colors clockwise around the table
function STO_seatedOrder()
  local seated = ATO_seatedPlayers()
  local order = {}
  for _, color in ipairs(STO_COLOR_ORDER) do
    if table.contains(seated, color) then table.insert(order, color) end
  end
  return order
end

-- the round's turn order in the normal direction
function STO_normalOrder()
  if Turns.type == 2 and Turns.order ~= nil and #Turns.order > 0 then return ATO_copy(Turns.order) end
  return STO_seatedOrder()
end

-- the seated colors in turn order, starting from a color
function STO_orderFrom(first)
  local order = STO_seatedOrder()
  local start = 1
  for i, color in ipairs(order) do
    if color == first then start = i end
  end
  local result = {}
  for i = 0, #order - 1 do table.insert(result, order[((start - 1 + i) % #order) + 1]) end
  return result
end

-- Yellow, or the first seated color after it in turn order
function STO_yellowOrNext()
  local seated = ATO_seatedPlayers()
  local start = 1
  for i, color in ipairs(STO_COLOR_ORDER) do
    if color == "Yellow" then start = i end
  end
  for i = 0, #STO_COLOR_ORDER - 1 do
    local color = STO_COLOR_ORDER[((start - 1 + i) % #STO_COLOR_ORDER) + 1]
    if table.contains(seated, color) then return color end
  end
  return seated[1]
end

function STO_reversed(list)
  local result = {}
  for i = #list, 1, -1 do table.insert(result, list[i]) end
  return result
end

-- give the turn to a color, and again once TTS has settled after an order change
-- (TTS picks its own turn a few frames after the order changes)
function STO_setTurn(color)
  if color == nil or color == "" then return end
  Turns.turn_color = color
  Wait.frames(function()
    if Turns.turn_color ~= color then Turns.turn_color = color end
  end, 10)
end

function STO_applyDirection()
  if TurnDirection == nil then return end
  local reverse = TurnDirection.is_face_down
  local current = Turns.turn_color

  if not Turns.enable or current == nil or current == "" then
    Turns.reverse_order = reverse
  else
    -- Changing Turns.reverse_order mid-turn leaves TTS's "next player" pointer at the
    -- old position, so the turn jumps to the wrong player. Instead, set an explicit order
    -- in the chosen direction and give the turn back to the current player.
    -- The original turn settings are restored at the next round.
    if settings.STO_Order == nil then
      settings.STO_Order = STO_normalOrder()
      settings.STO_TurnType = Turns.type
    end
    local order = ATO_copy(settings.STO_Order)
    if reverse then order = STO_reversed(order) end
    Turns.type = 2
    Turns.order = order
    Turns.reverse_order = false
    STO_setTurn(current)
  end

  if reverse then
    broadcastToAll("-- Direction of play: reverse --")
  else
    broadcastToAll("-- Direction of play: normal --")
  end
end

-- called by nextRound: the first player to pass starts the new round
function STO_newRound()
  -- undo the explicit order set by "Update direction" during the round
  if settings.STO_Order ~= nil then
    Turns.type = settings.STO_TurnType or 0
    if Turns.type == 2 then Turns.order = settings.STO_Order end
    settings.STO_Order = nil
    settings.STO_TurnType = nil
  end

  local first = (settings.PassOrder or {})[1]
  settings.PassOrder = {}
  if Turns.enable then STO_setTurn(first or Turns.turn_color) end
  ATO_updateUI()
end


-- TURN ORDER --
-- Two setup dropdowns:
--  "Turn order":      "Rotating" (default): clockwise from the start player (STO_* above).
--                     "Pass order": each round is played in the order the players passed
--                     the round before (formerly the Advanced Turn Order house rule).
--  "Starting player": "Yellow" (default; or the next seated color after it), "Random", or
--                     "Draft" (pass order only; with rotating, or with random races, it
--                     works as "Random").
-- After "Setup":
--  1. The round 1 turn order is set:
--     - Yellow / Random with rotating: clockwise from the starting player.
--     - Random with the pass order: a random order, revealed one player at a time.
--     - Draft: the players are put in a random draft order (revealed one at a time). In
--       draft order, each player takes either the best free race pick position or the
--       best free turn order position (for round 1), and is instantly put in the last
--       free position of the other track.
--  2. Factions are selected in race pick order, one player at a time: the reverse of the
--     turn order, or the drafted race pick order. Only the player picking sees the race
--     buttons (RaceButtons_update).
--  3. Play. Pass order: a player passes by flipping their "Actions" card face down during
--     their own turn: their turn ends immediately and they take the best free turn order
--     position for the next round. Rotating: the STO_* code above.
-- The turn order panel is shown during the draft and faction selection. During play
-- with the pass order, the built-in turn indicator (top right) shows the current order,
-- and a small list at the top of the screen, left of it, shows the next round's order.

function ATO_passOrder()
  return settings.TurnOrder == "pass"
end

-- how the starting player is chosen: "yellow", "random" or "draft"
function ATO_startMode()
  local mode = settings.StartingPlayer or "yellow"
  if mode == "draft" and (not ATO_passOrder() or settings.RandomRaces) then mode = "random" end
  return mode
end

function ATO_usesDraft()
  return ATO_startMode() == "draft"
end

-- the turn order code runs setup (before play starts)
function ATO_inSetup()
  local phase = ATO.phase
  return phase == "reveal" or phase == "draft" or phase == "seating" or phase == "race"
end

-- setup dropdowns
local ATO_TURN_ORDERS = {["Rotating"] = "rotating", ["Pass order"] = "pass"}
local ATO_START_MODES = {["Yellow"] = "yellow", ["Random"] = "random", ["Draft"] = "draft"}

function ATO_setTurnOrder(player, value, elementId)
  settings.TurnOrder = ATO_TURN_ORDERS[value] or "rotating"
end

function ATO_setStartingPlayer(player, value, elementId)
  settings.StartingPlayer = ATO_START_MODES[value] or "yellow"
end

-- saves made before the dropdowns: the Advanced Turn Order checkbox
function ATO_migrateSettings()
  if settings.TurnOrder == nil then
    settings.TurnOrder = settings.AdvancedTurnOrder and "pass" or "rotating"
    settings.StartingPlayer = settings.AdvancedTurnOrder and "draft" or "random"
    -- the Advanced Turn Order drew the starting techs after race selection
    settings.TechAfterRaces = settings.AdvancedTurnOrder == true
  end
  settings.StartingPlayer = settings.StartingPlayer or "yellow"
  settings.AdvancedTurnOrder = nil
end

-- true: players that passed still get turns (to take reactions), as in the base rules
-- false: players that passed are skipped until the next round
local ATO_KEEP_TURNS_AFTER_PASS = true

-- timing of the draft order reveal after "Setup" is pressed (seconds)
local ATO_REVEAL_INTRO_SECONDS = 4   -- explanation before the first player is revealed
local ATO_REVEAL_STEP_SECONDS = 1.5  -- between revealed players, and before the draft starts

function ATO_defaultState()
  return {
    phase = "off",      -- "off", "reveal", "draft", "race", "play"
    revealed = 0,       -- how many players of the draft order have been revealed
    draftOrder = {},    -- colors, random order in which positions are drafted
    draftIndex = 1,
    choice = {},        -- color -> "race" or "turn"
    raceSlots = {},     -- race pick position -> color (false = still free)
    turnSlots = {},     -- round 1 turn order position -> color (false = still free)
    raceIndex = 1,
    round = 0,
    order = {},         -- turn order of the current round
    passOrder = {},     -- colors in the order they passed this round
    actionCards = {}    -- Actions card GUID -> owner color
  }
end

-- restore the state from a save, filling in anything missing
function ATO_restore(state)
  ATO = ATO_defaultState()
  if type(state) ~= "table" then return end
  for key, value in pairs(state) do ATO[key] = value end
end

function ATO_name(color)
  if color == nil then return "-" end
  local p = Player[color]
  if p ~= nil and p.seated and p.steam_name ~= nil then return p.steam_name end
  return color
end

function ATO_shuffle(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end

function ATO_copy(list)
  local result = {}
  for i, value in ipairs(list) do result[i] = value end
  return result
end

function ATO_isPassed(color)
  return table.contains(ATO.passOrder, color)
end

-- players taking part: everyone seated at a player color
function ATO_seatedPlayers()
  local colors = {}
  for _, color in ipairs(getSeatedPlayers()) do
    if color ~= "Black" and color ~= "Grey" then table.insert(colors, color) end
  end
  return colors
end

-- hand the turn to a color using the built-in turn system
function ATO_setTurns(order, current)
  Turns.enable = true
  Turns.type = 2  -- custom order
  Turns.order = order
  Turns.reverse_order = false
  Turns.pass_turns = true
  if current == nil then return end
  Turns.turn_color = current

  -- TTS picks its own starting turn a few frames after turns are enabled or the order
  -- changes, which can override the color set above: set it again once that has happened
  Wait.frames(function()
    if Turns.turn_color ~= current and (ATO_expectedTurnColor() == current or ATO.phase == "play") then
      Turns.turn_color = current
    end
    ATO_syncHotseat(Turns.turn_color)
    ATO_updateUI()
  end, 10)
end

-- hot seat (or testing alone): everyone at the table is the same Steam account
function ATO_isHotseat()
  local players = Player.getPlayers()
  if #players <= 1 then return true end
  local steamId = players[1].steam_id
  for _, p in ipairs(players) do
    if p.steam_id ~= steamId then return false end
  end
  return true
end

-- in hot seat, move the shared screen to the given color
function ATO_syncHotseat(color)
  if color == nil or not ATO_isHotseat() then return end
  local players = Player.getPlayers()
  if #players ~= 1 then return end  -- hot seat already gives each color its own seat
  local p = players[1]
  if p.color ~= color then p.changeColor(color) end
end

-- whose turn it must be during the draft and faction selection (nil during play)
function ATO_expectedTurnColor()
  if ATO.phase == "draft" then return ATO.draftOrder[ATO.draftIndex] end
  if ATO.phase == "race" then return ATO.raceSlots[ATO.raceIndex] end
  return nil
end


-- round 1 turn order without a draft: races are picked in the reverse order
function ATO_setOrder(order)
  ATO.draftOrder = ATO_copy(order)
  ATO.turnSlots = ATO_copy(order)
  ATO.raceSlots = STO_reversed(order)
  ATO.draftIndex = #order + 1
end

-- Step 1: the starting player and round 1 turn order (called when "Setup" is pressed)
function ATO_startSetup()
  local players = ATO_seatedPlayers()
  if #players == 0 then
    broadcastToAll("Turn order: no seated players found.", {1, 0.4, 0.4})
    ATO = ATO_defaultState()
    ATO_updateUI()
    return
  end
  if #players ~= settings.PlayerCount then
    broadcastToAll(string.format("Turn order: %d players are seated, but the player count is set to %d. The turn order uses the seated players.",
      #players, settings.PlayerCount), {1, 0.8, 0.4})
  end

  -- the pass order decides the turn order, so the "Direction of Play" card is not used
  if ATO_passOrder() then
    local direction = getObjectFromGUID(TurnDirection_GUID)
    if direction ~= nil then direction.destruct() end
    TurnDirection = nil
  end

  local actionCards = ATO.actionCards  -- keep cards registered before setup
  ATO = ATO_defaultState()
  ATO.actionCards = actionCards
  for i = 1, #players do
    ATO.raceSlots[i] = false
    ATO.turnSlots[i] = false
  end

  local mode = ATO_startMode()

  -- seats randomized after race selection: the seats people sit at now decide nothing,
  -- so races are picked in a random order. Once the seats are randomized, the last
  -- player to pick starts and play goes clockwise from them (ATO_startPlay).
  if mode ~= "draft" and SEAT_timing() == "after" then
    local order = ATO_shuffle(players)
    ATO.draftOrder = ATO_copy(order)
    ATO.raceSlots = ATO_copy(order)
    ATO.draftIndex = #order + 1
    ATO.orderAfterSeats = true
    broadcastToAll("Factions are picked in a random order. After faction selection the seats are randomized: the last player to pick starts, and play goes clockwise from them.")
    ATO_finishDraft()
    return
  end

  if mode == "draft" or (mode == "random" and ATO_passOrder()) then
    -- a random draft order or turn order, revealed one player at a time
    ATO.phase = "reveal"
    ATO.revealed = 0
    ATO.draftOrder = ATO_shuffle(players)
    if mode == "draft" then
      broadcastToAll("Turn order draft: the draft order will now be randomized.")
      broadcastToAll("In draft order, each player picks either the best faction pick position or the best turn order position.")
    else
      broadcastToAll("Pass order: the round 1 turn order will now be randomized. Factions are picked in reverse turn order.")
    end
    ATO_updateUI()
    Wait.time(ATO_revealNext, ATO_REVEAL_INTRO_SECONDS)
    return
  end

  -- a starting player, then clockwise around the table
  local first
  if mode == "yellow" then
    first = STO_yellowOrNext()
    broadcastToAll("Starting player: " .. ATO_name(first) .. " (" .. first .. ")", first)
  else
    first = players[math.random(#players)]
    broadcastToAll("Starting player, chosen randomly: " .. ATO_name(first), first)
  end
  placeFirstPlayerTile(first)
  ATO_setOrder(STO_orderFrom(first))
  ATO_finishDraft()
end

-- reveal the next player of the random draft order
function ATO_revealNext()
  if ATO.phase ~= "reveal" then return end  -- setup was reset or the game was reloaded

  -- the last two are revealed together (once the second to last is known, so is the last)
  local count = (#ATO.draftOrder - ATO.revealed == 2) and 2 or 1
  for _ = 1, count do
    ATO.revealed = ATO.revealed + 1
    local color = ATO.draftOrder[ATO.revealed]
    broadcastToAll(string.format("%d. %s", ATO.revealed, ATO_name(color)), color)
  end
  ATO_updateUI()

  if ATO.revealed < #ATO.draftOrder then
    Wait.time(ATO_revealNext, ATO_REVEAL_STEP_SECONDS)
  else
    Wait.time(ATO_beginDraft, ATO_REVEAL_STEP_SECONDS)
  end
end

-- the whole draft order is known: the first player chooses
function ATO_beginDraft()
  if ATO.phase ~= "reveal" then return end
  ATO.revealed = #ATO.draftOrder

  -- no draft: the revealed order is the round 1 turn order, and races are picked
  -- in the reverse order
  if not ATO_usesDraft() then
    ATO_setOrder(ATO.draftOrder)
    ATO_finishDraft()
    return
  end

  ATO.phase = "draft"

  broadcastToAll("Draft order: " .. ATO_numberedList(ATO.draftOrder))
  ATO_setTurns(ATO_copy(ATO.draftOrder), ATO.draftOrder[1])
  ATO_announceDrafter()
  ATO_updateUI()
end

-- after loading a game saved mid-reveal, skip straight to the draft
function ATO_resume()
  if ATO.phase == "reveal" then ATO_beginDraft() end
  -- saved while the seats were being randomized: finish that step
  if ATO.phase == "seating" then
    if ATO.seatingNext == "race" then
      settings.SeatsRandomized = true
      ATO_beginRaceSelection()
    else
      settings.SeatsRandomized = true
      SEAT_placePending(ATO_startPlay)
    end
  end
  if ATO_isLastDrafter() then Wait.time(ATO_autoLastPick, ATO_REVEAL_STEP_SECONDS) end
  -- saved while random races were being given out: carry on
  if ATO.phase == "race" and settings.RandomRaces then RandomRaces_giveCurrent() end
end

-- best (first) and last free position of a track
function ATO_firstFree(slots)
  for i = 1, #slots do
    if not slots[i] then return i end
  end
  return nil
end

function ATO_lastFree(slots)
  for i = #slots, 1, -1 do
    if not slots[i] then return i end
  end
  return nil
end

-- "1. Name, 2. Name, ..."
function ATO_numberedList(slots)
  local names = {}
  for i, color in ipairs(slots) do
    names[i] = i .. ". " .. (color and ATO_name(color) or "-")
  end
  return table.concat(names, ", ")
end

function ATO_isLastDrafter()
  return ATO.phase == "draft" and ATO.draftIndex == #ATO.draftOrder
end

function ATO_announceDrafter()
  local color = ATO.draftOrder[ATO.draftIndex]
  if ATO_isLastDrafter() then
    -- one free position left on each track: nothing to choose
    broadcastToAll(string.format("%s gets the remaining positions: faction pick #%d, turn order #%d",
      ATO_name(color), ATO_firstFree(ATO.raceSlots), ATO_firstFree(ATO.turnSlots)), color)
    Wait.time(ATO_autoLastPick, ATO_REVEAL_STEP_SECONDS)
    return
  end
  broadcastToAll(string.format("%s: take the best faction pick (#%d) or the best turn order position (#%d)?",
    ATO_name(color), ATO_firstFree(ATO.raceSlots), ATO_firstFree(ATO.turnSlots)), color)
end

-- the last drafter gets the last free position of both tracks
function ATO_autoLastPick()
  if not ATO_isLastDrafter() then return end  -- already done, or the game was reset
  local color = ATO.draftOrder[ATO.draftIndex]
  ATO.choice[color] = "auto"
  ATO.raceSlots[ATO_firstFree(ATO.raceSlots)] = color
  ATO.turnSlots[ATO_firstFree(ATO.turnSlots)] = color
  ATO.draftIndex = ATO.draftIndex + 1
  ATO_finishDraft()
end

-- Step 2: draft buttons in the turn order panel
function ATO_ChooseRace(player) ATO_choose(player, "race") end
function ATO_ChooseTurn(player) ATO_choose(player, "turn") end

function ATO_choose(player, kind)
  if ATO.phase ~= "draft" or ATO_isLastDrafter() then return end
  local color = ATO.draftOrder[ATO.draftIndex]
  -- the choice always goes to the next player in the draft order; in hot seat the
  -- shared screen may still be sitting in another color, so accept the click anyway
  if player.color ~= color and not ATO_isHotseat() then
    player.broadcast("It is " .. ATO_name(color) .. "'s turn to choose.", {1, 0.4, 0.4})
    return
  end

  -- best free position of the chosen track, last free position of the other one
  ATO.choice[color] = kind
  local raceIndex, turnIndex
  if kind == "race" then
    raceIndex = ATO_firstFree(ATO.raceSlots)
    turnIndex = ATO_lastFree(ATO.turnSlots)
  else
    turnIndex = ATO_firstFree(ATO.turnSlots)
    raceIndex = ATO_lastFree(ATO.raceSlots)
  end
  ATO.raceSlots[raceIndex] = color
  ATO.turnSlots[turnIndex] = color
  broadcastToAll(string.format("%s takes %s: faction pick #%d, turn order #%d", ATO_name(color),
    kind == "race" and "the best faction pick" or "the best turn order position", raceIndex, turnIndex), color)

  ATO.draftIndex = ATO.draftIndex + 1
  if ATO.draftIndex > #ATO.draftOrder then
    ATO_finishDraft()
  else
    Turns.turn_color = ATO.draftOrder[ATO.draftIndex]
    ATO_announceDrafter()
    ATO_updateUI()
  end
end

-- all positions are taken: continue with faction selection
function ATO_finishDraft()
  broadcastToAll("Faction pick order: " .. ATO_numberedList(ATO.raceSlots))
  if not ATO.orderAfterSeats then
    broadcastToAll("Round 1 turn order: " .. ATO_numberedList(ATO.turnSlots))
  end

  -- randomized seats before race selection: move the players first
  if SEAT_timing() == "race" and not settings.SeatsRandomized then
    ATO.phase = "seating"
    ATO.seatingNext = "race"
    ATO_updateUI()
    SEAT_randomize(ATO_beginRaceSelection)
    return
  end
  ATO_beginRaceSelection()
end

function ATO_beginRaceSelection()
  ATO.phase = "race"
  ATO.raceIndex = 0
  -- a player's pick ends their turn: "End Turn" is undone (onPlayerTurn)
  ATO_setTurns(ATO_copy(ATO.raceSlots), nil)
  ATO_advanceRacePick()
end

-- Step 3: factions are selected in race pick order
function ATO_advanceRacePick()
  ATO.raceIndex = ATO.raceIndex + 1
  -- skip players that already selected a faction
  while ATO.raceSlots[ATO.raceIndex] ~= nil and PlayerSelection[ATO.raceSlots[ATO.raceIndex]] ~= nil
        and PlayerSelection[ATO.raceSlots[ATO.raceIndex]] ~= 'none' do
    ATO.raceIndex = ATO.raceIndex + 1
  end

  local color = ATO.raceSlots[ATO.raceIndex]
  if color == nil then
    ATO_startPlay()
    return
  end
  Turns.turn_color = color
  if settings.RandomRaces then
    RandomRaces_giveCurrent()
  else
    broadcastToAll(ATO_name(color) .. ": select your faction.", color)
  end
  RaceButtons_update()
  ATO_updateUI()
end

-- called by PlayerSetup before a faction is given to a player
-- returns: allowed, and the color the faction is for
function ATO_canPickRace(color)
  if ATO.phase == "off" then
    broadcastToColor("Press Setup before selecting factions.", color, {1, 0.4, 0.4})
    return false, color
  end
  if ATO.phase == "play" then
    broadcastToColor("Faction selection is over.", color, {1, 0.4, 0.4})
    return false, color
  end
  if ATO.phase == "reveal" or ATO.phase == "draft" then
    broadcastToColor("Finish the turn order draft before selecting factions.", color, {1, 0.4, 0.4})
    return false, color
  end
  if ATO.phase == "seating" then
    broadcastToColor("Wait until the seats have been randomized.", color, {1, 0.4, 0.4})
    return false, color
  end
  if ATO.phase == "race" and ATO.raceSlots[ATO.raceIndex] ~= color then
    local expected = ATO.raceSlots[ATO.raceIndex]
    if ATO_isHotseat() then
      -- shared screen: the pick is for the player whose turn it is, placed at their seat
      ATO_syncHotseat(expected)
      return true, expected
    end
    broadcastToColor("It is " .. ATO_name(expected) .. "'s turn to select a faction.", color, {1, 0.4, 0.4})
    return false, color
  end
  return true, color
end

-- called by PlayerSetup after a faction was given to a player
function ATO_racePicked(color)
  if ATO.phase == "race" and ATO.raceSlots[ATO.raceIndex] == color then
    ATO_advanceRacePick()
  else
    ATO_updateUI()
  end
end

-- Step 4: play round 1 in the round 1 turn order
function ATO_startPlay()
  -- randomized seats after race selection: move the players, then set up the factions
  -- at their new seats, then start playing
  if SEAT_timing() == "after" and not settings.SeatsRandomized then
    ATO.phase = "seating"
    ATO.seatingNext = "play"
    RaceButtons_update()
    ATO_updateUI()
    SEAT_randomize(function() SEAT_placePending(ATO_startPlay) end)
    return
  end

  ATO.phase = "play"
  RaceButtons_update()
  -- seats randomized after a random race pick order: the last player to pick starts,
  -- clockwise from their new seat
  if ATO.orderAfterSeats then
    ATO.orderAfterSeats = nil
    ATO.turnSlots = STO_orderFrom(ATO.raceSlots[#ATO.raceSlots])
    broadcastToAll("Round 1 turn order: " .. ATO_numberedList(ATO.turnSlots))
  end
  Wait.time(hideRaceSelection, 2)  -- let the last faction's setup finish first
  -- house rule: the starting techs are drawn now instead of at Setup
  if settings.TechAfterRaces then
    broadcastToAll("All factions selected: drawing the starting technologies.")
    drawStartingTechs()
  end

  -- rotating: clockwise around the table from the starting player
  if not ATO_passOrder() then
    local first = ATO.turnSlots[1]
    Turns.enable = true
    Turns.type = 2  -- custom order: the seats clockwise
    Turns.order = STO_seatedOrder()
    Turns.reverse_order = false
    Turns.pass_turns = true
    STO_setTurn(first)
    placeFirstPlayerTile(first)
    broadcastToAll("All factions selected. " .. ATO_name(first) .. " starts round 1.", first)
    ATO_updateUI()
    return
  end

  ATO.round =tonumber(RoundMarker.getDescription()) or 1
  ATO.order = ATO_copy(ATO.turnSlots)
  ATO.passOrder = {}
  ATO_beginRound()
end

function ATO_beginRound()
  broadcastToAll(string.format("Round %d turn order: %s", ATO.round, ATO_numberedList(ATO.order)))
  broadcastToAll("Flip your Actions card face down during your turn to pass.")

  ATO_setTurns(ATO_copy(ATO.order), ATO.order[1])
  placeFirstPlayerTile(ATO.order[1])
  ATO_updateUI()
end

-- called by nextRound; returns true if the advanced turn order handled the turn order
function ATO_newRound(round)
  if ATO.phase ~= "play" then return false end

  -- pass order first, then anyone that did not pass (in their current order)
  local order = ATO_copy(ATO.passOrder)
  for _, color in ipairs(ATO.order) do
    if not table.contains(order, color) then table.insert(order, color) end
  end

  ATO.round = round
  ATO.order = order
  ATO.passOrder = {}
  ATO_beginRound()
  return true
end

function ATO_nextColor(fromColor)
  local count = #ATO.order
  local index = 0
  for i, color in ipairs(ATO.order) do
    if color == fromColor then index = i end
  end
  for step = 1, count do
    local color = ATO.order[((index - 1 + step) % count) + 1]
    if ATO_KEEP_TURNS_AFTER_PASS or not ATO_isPassed(color) then return color end
  end
  return nil
end

-- a player flips their Actions card face down
function ATO_pass(color, card, flipper)
  if ATO_isPassed(color) or not table.contains(ATO.order, color) then return end

  if Turns.turn_color ~= color then
    broadcastToColor("You can only pass during your own turn. It is " .. ATO_name(Turns.turn_color) .. "'s turn.",
      flipper or color, {1, 0.4, 0.4})
    -- undo the flip once the card has settled
    Wait.time(function()
      if card ~= nil and card.is_face_down and not ATO_isPassed(color) then card.flip() end
    end, 1)
    return
  end

  table.insert(ATO.passOrder, color)
  broadcastToAll(string.format("%s passes and takes turn order position #%d for the next round.",
    ATO_name(color), #ATO.passOrder), color)

  -- the first player to pass starts the next round: move the start player tile to them now
  if #ATO.passOrder == 1 then placeFirstPlayerTile(color) end

  if #ATO.passOrder >= #ATO.order then
    broadcastToAll("All players have passed. Finish the round and press 'Next Round'.")
  end

  -- end the turn immediately
  local nextColor = ATO_nextColor(color)
  if nextColor ~= nil and nextColor ~= color then Turns.turn_color = nextColor end
  ATO_updateUI()
end

function onObjectRotate(object, spin, flip, player_color, old_spin, old_flip)
  local advanced = ATO_passOrder() and ATO.phase == "play"
  if not (advanced or STO_active()) then return end
  if object == nil or object.getName() ~= "Actions" then return end
  if type(flip) ~= "number" or flip == old_flip then return end

  local angle = flip % 360
  if angle < 90 or angle > 270 then return end  -- flipped face up, not a pass

  local owner = ATO.actionCards[object.getGUID()] or player_color
  if owner == nil then return end
  if advanced then ATO_pass(owner, object, player_color) else STO_pass(owner, object, player_color) end
end

function onPlayerTurn(player, previous_player)
  if STO_active() then
    -- testing alone: move to the player whose turn it is, as with the pass order
    if player ~= nil then ATO_syncHotseat(player.color) end
    return
  end

  -- during the draft and faction selection the turn follows the set order only:
  -- undo any other turn change (TTS auto-start, someone pressing "End Turn")
  local expected = ATO_expectedTurnColor()
  if expected ~= nil then
    local now = player and player.color or nil
    if now ~= expected and Player[expected] ~= nil
       and (Player[expected].seated or ATO_isHotseat()) then
      -- the turn only moves on with a choice or a race pick
      if previous_player ~= nil and previous_player.color == expected then
        local hint = ATO.phase == "race" and "Select a faction to end your turn."
          or "Choose the best faction pick or the best turn order position to end your turn."
        broadcastToColor(hint, expected, {1, 0.8, 0.4})
      end
      -- set it back, and again once TTS has settled
      local function restore()
        if ATO_expectedTurnColor() == expected and Turns.turn_color ~= expected then
          Turns.turn_color = expected
        end
      end
      Wait.frames(restore, 1)
      Wait.frames(restore, 10)
    end
    ATO_syncHotseat(expected)
    ATO_updateUI()
    return
  end

  if ATO.phase ~= "play" then return end
  ATO_updateUI()
  if player ~= nil then ATO_syncHotseat(player.color) end
  if ATO_KEEP_TURNS_AFTER_PASS or player == nil then return end

  -- skip players that already passed
  if ATO_isPassed(player.color) then
    local nextColor = ATO_nextColor(player.color)
    if nextColor ~= nil and nextColor ~= player.color then Turns.turn_color = nextColor end
  end
end


-- turn order panels
function ATO_slotLines(slots, count, marker)
  local lines = {}
  for i = 1, count do
    local color = slots[i]
    local line = string.format("%d. %s", i, color and ATO_name(color) or "-")
    if marker ~= nil and color then line = line .. marker(color) end
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

-- size the panel so all of its text fits (up to 6 players: about 25 lines during the draft)
local ATO_LINE_HEIGHT = 17     -- pixels per line at font size 13
local ATO_CHARS_PER_LINE = 38  -- characters that fit on one line of the 266 px wide text

-- length of a line without rich text tags such as <b>
-- (plain string.find only: patterns like "(.-)\n" are "too complex" for TTS's Lua engine)
function ATO_visibleLength(line)
  local length, position = 0, 1
  while true do
    local tagStart = string.find(line, "<", position, true)
    if tagStart == nil then return length + #line - position + 1 end
    local tagEnd = string.find(line, ">", tagStart, true)
    if tagEnd == nil then return length + #line - position + 1 end
    length = length + tagStart - position
    position = tagEnd + 1
  end
end

function ATO_fitPanel(text, showButtons)
  local lines, position = 0, 1
  while position <= #text + 1 do
    local lineEnd = string.find(text, "\n", position, true) or (#text + 1)
    local line = string.sub(text, position, lineEnd - 1)
    lines = lines + math.max(1, math.ceil(ATO_visibleLength(line) / ATO_CHARS_PER_LINE))
    position = lineEnd + 1
  end
  local textHeight = lines * ATO_LINE_HEIGHT + 10
  local buttonsHeight = showButtons and 96 or 10
  UI.setAttribute("ATO_Text", "height", textHeight)
  UI.setAttribute("ATO_Panel", "height", 40 + textHeight + buttonsHeight)
end

function ATO_updateUI()
  local count = math.max(#ATO.draftOrder, #ATO.order)
  local roundOneText = "<b>Round 1 turn order</b>\n" .. ATO_slotLines(ATO.turnSlots, count)
  if ATO.orderAfterSeats then
    roundOneText = "<b>Round 1 turn order</b>\nThe seats are randomized after faction selection. " ..
      "The last player to pick starts, and play goes clockwise from them."
  end

  -- draft / faction selection panel
  if ATO_inSetup() then
    local text = ""
    UI.setAttribute("ATO_Panel", "active", "true")

    if ATO.phase == "reveal" then
      local lines = {}
      for i = 1, #ATO.draftOrder do
        lines[i] = string.format("%d. %s", i, i <= ATO.revealed and ATO_name(ATO.draftOrder[i]) or "?")
      end
      if not ATO_usesDraft() then
        text = "<b>Randomizing the turn order...</b>\n\n" ..
          "This is the round 1 turn order. Factions are picked in the reverse order.\n\n" ..
          "<b>Turn order</b>\n" .. table.concat(lines, "\n")
      else
        text = "<b>Randomizing the draft order...</b>\n\n" ..
          "In draft order, each player picks either the best faction pick position or the best " ..
          "turn order position, and gets the last free position of the other.\n\n" ..
          "<b>Draft order</b>\n" .. table.concat(lines, "\n")
      end
      UI.setAttribute("ATO_Buttons", "active", "false")
    elseif ATO.phase == "draft" then
      local color = ATO.draftOrder[ATO.draftIndex]
      text = "<b>Draft</b> - choosing: " .. ATO_name(color) .. "\n\n" ..
        "<b>Draft order</b>\n" .. ATO_slotLines(ATO.draftOrder, count) .. "\n\n" ..
        "<b>Faction pick order</b>\n" .. ATO_slotLines(ATO.raceSlots, count) .. "\n\n" ..
        "<b>Round 1 turn order</b>\n" .. ATO_slotLines(ATO.turnSlots, count)

      UI.setAttribute("ATO_RaceButton", "text", string.format("Best faction pick (#%d)", ATO_firstFree(ATO.raceSlots) or 0))
      UI.setAttribute("ATO_TurnButton", "text", string.format("Best turn order (#%d)", ATO_firstFree(ATO.turnSlots) or 0))
      -- only the drafter sees the buttons; in hot seat everyone shares one screen
      UI.setAttribute("ATO_Buttons", "visibility", ATO_isHotseat() and "" or (color or ""))
      UI.setAttribute("ATO_Buttons", "active", ATO_isLastDrafter() and "false" or "true")
    elseif ATO.phase == "seating" then
      text = "<b>Randomizing seats...</b>\n\n" ..
        "<b>Faction pick order</b>\n" .. ATO_slotLines(ATO.raceSlots, count) .. "\n\n" ..
        roundOneText
      UI.setAttribute("ATO_Buttons", "active", "false")
    else
      local current = ATO.raceSlots[ATO.raceIndex]
      text = "<b>Faction selection</b> - picking: " .. ATO_name(current) .. "\n\n" ..
        "<b>Faction pick order</b>\n" .. ATO_slotLines(ATO.raceSlots, count, function(color)
          local faction = PlayerSelection[color]
          if faction ~= nil and faction ~= 'none' then return " (" .. faction .. ")" end
          if color == current then return "  (picking)" end
          return ""
        end) .. "\n\n" ..
        roundOneText
      UI.setAttribute("ATO_Buttons", "active", "false")
    end

    UI.setValue("ATO_Text", text)
    ATO_fitPanel(text, ATO.phase == "draft" and not ATO_isLastDrafter())
  else
    UI.setAttribute("ATO_Panel", "active", "false")
  end

  -- during play: the built-in turn indicator shows the current order,
  -- this small list at the top of the screen shows the order for the next round
  if ATO_passOrder() and ATO.phase == "play" then
    UI.setAttribute("ATO_NextPanel", "active", "true")
    UI.setAttribute("ATO_NextPanel", "offsetXY", "-180 0")
    UI.setValue("ATO_NextText", "<b>Next round</b>\n" .. ATO_slotLines(ATO.passOrder, #ATO.order))
  elseif STO_active() then
    -- standard turn order: who passed, and who gets the start player tile and direction card
    UI.setAttribute("ATO_NextPanel", "active", "true")
    -- sit left of the built-in turn indicator when it is shown, else in the corner
    UI.setAttribute("ATO_NextPanel", "offsetXY", Turns.enable and "-180 0" or "0 0")
    local passOrder = settings.PassOrder or {}
    local count = math.max(#passOrder, #ATO_seatedPlayers())
    UI.setValue("ATO_NextText", "<b>Passed</b>\n" .. ATO_slotLines(passOrder, count, function(color)
      if color == passOrder[1] then return " (start)" end
      if color == passOrder[2] then return " (direction)" end
      return ""
    end))
  else
    UI.setAttribute("ATO_NextPanel", "active", "false")
  end
end

ATO = ATO_defaultState()


--------------------------------------------------------------------------------
-- Player state: which faction each player color selected, and that player's
-- board. Saved with the game. Groundwork for ship state and the combat zone.
--
--   PlayerState[color] = { faction = "Orion Hegemony", boardGUID = "f3fd3a" }
--
-- Only colors that selected a faction have an entry. PlayerSelection (from the
-- original mod) is not saved by itself; it is filled in again from this on load.
--------------------------------------------------------------------------------

PlayerState = {}

-- called by PlayerSetup once a faction has been set up for a color
function PlayerState_record(color, faction, boardGUID)
  PlayerState[color] = { faction = faction, boardGUID = boardGUID }
end

-- restore from a save; also restores PlayerSelection
function PlayerState_restore(state)
  PlayerState = {}
  if type(state) ~= "table" then return end
  for color, entry in pairs(state) do
    if type(entry) == "table" and entry.faction ~= nil then
      PlayerState[color] = { faction = entry.faction, boardGUID = entry.boardGUID }
      PlayerSelection[color] = entry.faction
      if PlayerState_board(color) == nil then
        printToAll(string.format("Player state: the player board of %s (%s) was not found.",
                                 color, entry.faction), {1, 0.4, 0.4})
      end
    end
  end
end

-- faction name selected by a color, or nil
function PlayerState_faction(color)
  local entry = PlayerState[color]
  return entry and entry.faction
end

-- player board object of a color, or nil
function PlayerState_board(color)
  local entry = PlayerState[color]
  if entry == nil or entry.boardGUID == nil then return nil end
  return getObjectFromGUID(entry.boardGUID)
end


--------------------------------------------------------------------------------
-- Ship data and ship state (files in scripts/include/, see tools/tts_scripts.py)
--------------------------------------------------------------------------------
#include ShipData
#include ShipState
#include HexState
#include CombatZone


--------------------------------------------------------------------------------
-- Tech tiles on the player boards' tech tracks (scripts/include/TechTrack.ttslua)
--------------------------------------------------------------------------------
#include TechTrack


--------------------------------------------------------------------------------
-- Announce actions taken with influence discs (scripts/include/ActionAnnounce.ttslua)
--------------------------------------------------------------------------------
#include ActionAnnounce


--------------------------------------------------------------------------------
-- Randomize seat order (scripts/include/SeatOrder.ttslua)
--------------------------------------------------------------------------------
#include SeatOrder


--------------------------------------------------------------------------------
-- Random races (scripts/include/RandomRaces.ttslua)
--------------------------------------------------------------------------------
#include RandomRaces


--------------------------------------------------------------------------------
-- Race buttons shown only to the player picking (scripts/include/RaceButtons.ttslua)
--------------------------------------------------------------------------------
#include RaceButtons


--------------------------------------------------------------------------------
-- Combat simulator on the player boards (scripts/include/CombatSim.ttslua)
--------------------------------------------------------------------------------
#include CombatSim
