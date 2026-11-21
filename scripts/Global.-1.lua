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

  NoRoundLimit = false
}

-- print the settings as currently configured
function printSettings()
  printToAll("Settings:")
  printToAll(string.format(" - Player count: %s", tostring(settings.PlayerCount)))
  printToAll(string.format(" - Rift Cannon: %s", tostring(settings.RiftWeapons)))
  printToAll(string.format(" - Mionor Species: %s", tostring(settings.MinorSpecies)))
  printToAll(string.format(" - Galactic Events: %s", tostring(settings.GalacticEvents)))
  printToAll(string.format(" - Round Limit: %s", tostring(not settings.NoRoundLimit)))
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


  if (settings.NoRoundLimit) then UI.setAttribute("NoRoundLimit", "isOn", true)
  else UI.setAttribute("NoRoundLimit", "isOn", false) end

  for i = 2, 6 do UI.setAttribute(i .. 'Players', 'isOn', settings.PlayerCount == i) end
end


-- Called when the game is saved, save global settings
function onSave()
  return JSON.encode(settings)
end


-- The onLoad event is called after the game save finishes loading. --
function onLoad(saveData)
    RoundMarker = getObjectFromGUID(RoundMarker_GUID)
    TurnDirection = getObjectFromGUID(TurnDirection_GUID)
    TechBag = getObjectFromGUID(TechBag_GUID)
    ReputationBag = getObjectFromGUID(ReputationBag_GUID)
    DiscoveryBag = getObjectFromGUID(DiscoveryBag_GUID)
    Sector1Bag = getObjectFromGUID(Sector1Bag_GUID)
    Sector2Bag = getObjectFromGUID(Sector2Bag_GUID)
    Sector3Bag = getObjectFromGUID(Sector3Bag_GUID)
    ExtraS3Bag = getObjectFromGUID(ExtraS3Bag_GUID)
    MinorSpeciesBag = getObjectFromGUID(MinorSpeciesBag_GUID)
    TableZone = getObjectFromGUID(TableZone_GUID)

    local round = tonumber(RoundMarker.getDescription())
    if (round>0) then
      -- Load the save data, if present
      if saveData and saveData ~= "" then
        settings = JSON.decode(saveData)
        printToAll("Save state initialized")
        printToAll(string.format("Round: %s", round))
        printSettings()
      end
    end

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
end


-- perform the initial game setup for the first round
function gameSetup()
  local round = tonumber(RoundMarker.getDescription()) + 1
  local players = settings.PlayerCount

  broadcastToAll(string.format("--  Round #1 (Setup for %d players)  --", players))
  chooseFirstPlayer()

  -- update round marker
  RoundMarker.setPositionSmooth({42.87, 1.32, 19.24}, false, false)
  RoundMarker.setRotationSmooth({0,180,0})
  RoundMarker.setDescription(round)

  settings.setupCompleted = true
  updateUI_Visibility()

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

  rareTechIndex = 0
  newTechs = (players * 2) + 8
  Wait.time(drawTech, 0.4, newTechs)  -- repeat drawTech [newTech] times
end


function chooseFirstPlayer()
  local FirstPlayer_Tile = getObjectFromGUID(FirstPlayer_GUID)
  local Traitor_Tile = getObjectFromGUID(Traitor_GUID)
  local player_color = getSeatedPlayers()[math.random(1, #getSeatedPlayers())]
  Turns.turn_color = player_color

  broadcastToAll("First Player, chosen randomly: " .. Player[player_color].steam_name, player_color) 

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
      Traitor_Tile.setPositionSmooth({35.7, 0.96, -23.10}, false, false)
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

  Turns.reverse_order = false
  if TurnDirection == nil then return 
  end
  if (TurnDirection.is_face_down) then
    Turns.reverse_order = true
    broadcastToAll("-- Reverse turn order --")
  end
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
  local object = nil
  for _,GUID in pairs(DisabledGUIDs) do getObjectFromGUID(GUID).interactable = isInteractable end
  for _,GUID in pairs(BehindTheScenes_GUIDs) do getObjectFromGUID(GUID).interactable = isInteractable end
  for _,GUID in pairs(ButtonGUIDs) do getObjectFromGUID(GUID).interactable = isInteractable end
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

  -- check if the player already selected a faction
  if PlayerSelection[PlayerColor] ~= 'none' then
    print('You already selected ', PlayerSelection[PlayerColor], '. You can only select one faction.')
    return false
  end

  PlayerSelection[PlayerColor] = Faction.Name
  print(Player[PlayerColor].steam_name, ' selected ', Faction.Name)

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
  Object = SeekAndTake('Player Board', Box, takeParams)
  if (Object~=false) then
    destination = PlayerPosition + Vector(0, 0, 19*InvPos)
    Object.setPositionSmooth(destination, false, true)
    -- place influenbce discs, once the board is in place
    local funcInfluenceSetup = function() setupPlayerInfluence(Object, PlayerColor, Faction.Influence-1) end
    triggerFunctionIfResting(Object, funcInfluenceSetup)

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
function onObjectDrop(_, obj)
    if obj.use_grid == true then
        Wait.condition(
            function() blip(obj) end,
            function() return rest(obj) end,
            2)
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