-- Library imports
local lume = require('lume')
local gui = require('gspot')
-- Local imports
local net = require('network')

-- Gameboard setup
math.randomseed(os.time())
local gameObjects = {}
function objectById(id)
   return lume.first(lume.filter(gameObjects, function(obj) return obj.id == id end))
end
function objectsByType(pieceType)
   return lume.filter(gameObjects, function(obj) return obj.pieceType == pieceType) end)
end
local nextId = 1
--local diceRoll1 = 1
--local diceRoll2 = 1
local dice1
local dice2
local hexLocation = {{300,150},{250,225},{200,300},{250,375},{300,450},{400,450},{500,450},{550,375},{600,300},{550,225},{500,150},{400,150},
                     {350,225},{300,300},{350,375},{450,375},{500,300},{450,225},{400,300}} --spiral layout
local harborLocation = {{250,75},{200,150},{150,225},{100,300},{150,375},{200,450},{250,525},{350,525},{450,525},{550,525},
                        {600,450},{650,375},{700,300},{650,225},{600,150},{550,75},{450,75},{350,75}}
--[[                    {{300,150},{400,150},{500,150},
                {250,225},{350,225},{450,225},{550,225},
            {200,300},{300,300},{400,300},{500,300},{600,300},
                {250,375},{350,375},{450,375},{550,375},
                    {300,450},{400,450},{500,450}}--x,y --]]
local terrainDistribution = {{"wood",4},{"sheep",4},{"wheat",4},{"brick",3},{"stone",3},{"desert",1}}
local devCardDistribution = {{"knight",14},{"VP",5},{"cornucopia",2},{"top-hat",2},{"road",2}}
local resourceDistribution = {{"wood",19},{"sheep",19},{"wheat",19},{"brick",19},{"stone",19}}
local harborDistribution = {{"wood",1},{"sheep",1},{"wheat",1},{"brick",1},{"stone",1},{"question",4}}
local buildingDistribution = {{"path",15},{"settlement",5},{"city",4}}
local numberMapping = {5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11}
function unpackDistribution(distribution, shuffle)
  unpackedDistribution = {}
  for _, item in ipairs(distribution) do
    for i = 1, item[2] do
      table.insert(unpackedDistribution,item[1])
    end
  end
  if shuffle == true then
    unpackedDistribution = lume.shuffle(unpackedDistribution)
  end
  return unpackedDistribution
end


-- Preload graphics
local graphics = {}
function preloadGraphics()
   local files = love.filesystem.getDirectoryItems("resources")
   for _, file in ipairs(files) do
      local name = string.match(file, "(.*)%.png")
      if name then
         graphics[name] = love.graphics.newImage("resources/" .. file)
      end
   end
end

--local hexChoices = {"wood","wood","wood","wood","sheep","sheep","sheep","sheep","wheat","wheat","wheat","wheat","brick","brick","brick","stone","stone","stone","desert"}

local gamemode

function love.load()
   preloadGraphics()
   gamemode = "menu"
   initializeMenu()
end


local dice = 0
local specialClick = false

function love.update(dt)
   if gamemode == "menu" then
      gui:update(dt)
   elseif gamemode == "foreplay" then
      if net.connected then
         if net.mode == "server" then
            serverEventHandler(dt)
         else
            clientEventHandler(dt)
         end
      end
      lume.each(gameObjects, moveIfGrabbed)
   end
end

function moveIfGrabbed(obj)
   if obj.grabbed then
      moveGrabbableObject(obj, love.mouse.getX() + obj.grabOffsetx, love.mouse.getY() + obj.grabOffsety)
      if net.connected then -- If this is a networked game send the new coords
         net.updatePosition(obj)
      end
   end
end

function serverEventHandler(dt)
   events = net.serverGetEvents(dt)
   for _, event in ipairs(events) do
      if event.action == "join" then
         net.sendGamestate(lume.serialize(gameObjects), event.ip, event.port)
      end
      if event.action == "move" then
         obj = objectById(event.id)
         if obj then
           obj.x = event.x
           obj.y = event.y
           obj.rotation = event.rotation
           obj.flipped = event.flipped
           lume.remove(gameObjects, obj)
           lume.push(gameObjects, obj)
           net.updatePosition(obj)
         end
      end
   end
end

function clientEventHandler(dt)
   events = net.clientGetEvents(dt)
   for _, event in ipairs(events) do
      if event.action == "gamestate" then
         print("deserializing gamestate")
         gameObjects = lume.deserialize(event.gamestate)
         local dice = objectsByType("dice")
         if string.match(dice[1].image, "white") then
            dice1 = dice[1]
            dice2 = dice[2]
         else
            dice2 = dice[1]
            dice1 = dice[2]
         end
      end
      if event.action == "move" then
         local obj = objectById(event.id)
         if obj then
           obj.x = event.x
           obj.y = event.y
           obj.rotation = event.rotation
           obj.flipped = event.flipped
           lume.remove(gameObjects, obj)
           lume.push(gameObjects, obj)
         end
      end
   end
end

function love.draw()
   if gamemode == "menu" then
      gui:draw()
   elseif gamemode == "foreplay" then
      for i, obj in ipairs(gameObjects) do
         if obj.pieceType == "building" then
           love.graphics.setColor(obj.r,obj.g,obj.b)
         else
           love.graphics.reset()
         end
         drawGrabbableObject(obj)
      end
      love.graphics.setBackgroundColor(0/255, 80/255, 161/255)
   end
end

function love.mousepressed(x,y,button,istouch,presses)
   if gamemode == "menu" then
      gui:mousepress(x, y, button)
   elseif gamemode == "foreplay" then
      -- Racer X! Racer X!
      local cursorx, cursory = love.mouse.getPosition()
      local grabbedObjIdx
      for i, obj in lume.ripairs(gameObjects) do -- go in reverse so we grab the top objects first
         if button == 1 and aboveGrabbableObject(obj, cursorx, cursory) then
            if obj.grabbable then
               obj.grabbed = true
               obj.grabOffsetx = obj.x-love.mouse.getX()
               obj.grabOffsety = obj.y-love.mouse.getY()
               if presses >= 2 then
                  if not obj.flipped then
                     obj.flipped = true
                  else
                     obj.flipped = false
                  end
               end
               grabbedObjIdx = i
               if obj.pieceType == "dice" and presses == 2 then
                  rollDice()
               elseif obj.pieceType == "building" and presses == 2 then
                  obj.rotation = obj.rotation + math.rad(120)
               end
               break
            end
         end
      end
      if grabbedObjIdx then
         -- Move this object to the top of the list
         lume.push(gameObjects, table.remove(gameObjects, grabbedObjIdx))
      end
   end
end

function love.mousereleased(x,y,button,istouch,presses)
   if gamemode == "menu" then
      -- TODO
   elseif gamemode == "foreplay" then
      if button == 1 then
         mouseclicked = 0
         lume.each(gameObjects, function(obj) obj.grabbed = false end)
      end
   end
end

function love.keypressed(key, code, isrepeat)
   if gamemode == 'menu' then
      gui:keypress(key)
   elseif gamemode == 'foreplay' then
      if key == 'rshift' or key == 'lshift' then
         specialClick = true
      end
   end
end

function love.keyreleased(key, code, isrepeat)
   if gamemode == 'menu' then
      -- TODO
   elseif gamemode == 'foreplay' then
      if key == 'rshift' or key == 'lshift' then
         specialClick = false
      end
   end
end

function love.textinput(key)
   if gamemode == "menu" then
      gui:textinput(key)
   end
end

function initializeMenu()
   local menu = gui:group('', {x = 300, y=200})
   local offlineButton = gui:button("Offline", {
                                       y = 0,
                                       w = 200,
                                       h = 50
                                               }, menu)
   offlineButton.click = offlineMode
   local hostButton = gui:button("Host Online Game", {
                                    y = 60,
                                    w = 200,
                                    h = 50
                                                     }, menu)
   hostButton.click = hostMode
   local joinHostname = gui:input("Hostname", {
                                     y = 120,
                                     w = 200,
                                     h = 50
                                              }, menu)
   joinHostname.value = "localhost"
   local joinButton = gui:button("Join Online Game", {
                                    y = 180,
                                    w = 200,
                                    h = 50
                                                     }, menu)
   joinButton.click = function() joinMode(joinHostname.value) end
end

function offlineMode()
   gamemode = "foreplay"
   initializeGameboard()
end

function hostMode()
   gamemode = "foreplay"
   net.hostGame()
   initializeGameboard()
end

function joinMode(hostname)
   gamemode = "foreplay"
   net.joinGame(hostname)
   -- Board state will be sent by server
end

function initializeGameboard()
    dice1 = newGrabbableObject("dice","white-1","white-1",25,25,50,50,true)
    table.insert(gameObjects, dice1)
    dice2 = newGrabbableObject("dice","black-1","black-1",75,25,50,50,true)
    table.insert(gameObjects, dice2)
    local terrainHexMapping = unpackDistribution(terrainDistribution,true)
    for i, terrain in lume.ripairs(terrainHexMapping) do
        table.insert(gameObjects, newGrabbableObject("terrainHex", terrain.."-hex", "water-hex",hexLocation[i][1],hexLocation[i][2],100,100,true))
        if terrain ~= "desert" then
          table.insert(gameObjects,newGrabbableObject("numberChit",numberMapping[1].."-chit", "0-chit",hexLocation[i][1],hexLocation[i][2],50,50,true,0))
          table.remove(numberMapping,1)
        else
          table.insert(gameObjects,newGrabbableObject("thief","thief","thief",hexLocation[i][1],hexLocation[i][2],50,50,true))
        end
        table.remove(terrainHexMapping,i)
    end
    local harborMapping = unpackDistribution(harborDistribution,true)
    local j = 1
    for i = 1, 18 do
        if i % 2 == 1 then
          table.insert(gameObjects, newGrabbableObject("harbor", harborMapping[j].."-harbor", "water-hex", harborLocation[i][1],harborLocation[i][2],100,100,true))
          j = j + 1
        else
          table.insert(gameObjects, newGrabbableObject("water", "water-hex", "water-hex", harborLocation[i][1],harborLocation[i][2],100,100,true))
        end
    end
    local devCardMapping = unpackDistribution(devCardDistribution,true)
    for i, card in lume.ripairs(devCardMapping) do
      table.insert(gameObjects, newGrabbableObject("card", "round-shield", card,750,550,100,100,true))
    end
    local resourceMapping = unpackDistribution(resourceDistribution,false)
    for i, resource in lume.ripairs(resourceMapping) do
        local ypos = 50
        if resource == "wood" then
            ypos = 50
        elseif resource == "sheep" then
          ypos = 150
        elseif resource == "wheat" then
          ypos = 250
        elseif resource == "brick" then
          ypos = 350
        else --stone
          ypos = 450
        end
        table.insert(gameObjects, newGrabbableObject("card", resource, "honeycomb",750,ypos, 100, 100, true))
    end
    local buildingMapping = unpackDistribution(buildingDistribution)
    local colorMapping =  {{0/255,255/255,0/255},{255/255,165/255,0/255},{160/255,32/255,240/255},{150/255,75/255,0/255}}
    for k = 1, 4 do
      local r = colorMapping[k][1]
      local g = colorMapping[k][2]
      local b = colorMapping[k][3]
      for i, building in ipairs(buildingMapping) do
        local h = 30
        local w = 30
        if building == "path" then
          w = 15
          h = 50
        end
        table.insert(gameObjects, newGrabbableObject("building", building, building,200,50,w,h,true,0,r,g,b))
      end
    end
end

function newGrabbableObject (pieceType, image, back, x, y, w, h, centered, rot , r, g, b)
   local grabbableObject = {}
   grabbableObject.pieceType = pieceType
   grabbableObject.centered = centered
   grabbableObject.image = image
   grabbableObject.back = back
   grabbableObject.sx = w/graphics[image]:getWidth()
   grabbableObject.sy = h/graphics[image]:getHeight()
   grabbableObject.ox = 0
   grabbableObject.oy = 0
   grabbableObject.width = w
   grabbableObject.height = h
   grabbableObject.r = r
   grabbableObject.g = g
   grabbableObject.b = b
   if centered == true then
      grabbableObject.ox = graphics[image]:getWidth()/2
      grabbableObject.oy = graphics[image]:getHeight()/2
   end
   if rot then
     grabbableObject.rotation = rot
   else
     grabbableObject.rotation = 0
   end
   grabbableObject.x = x
   grabbableObject.y = y
   grabbableObject.grabbed = false
   grabbableObject.id = nextId
   nextId = nextId + 1
   grabbableObject.grabbable = true
   return grabbableObject
end

function drawGrabbableObject (grabbableObject)
   if grabbableObject.flipped then
       love.graphics.draw(graphics[grabbableObject.back], grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
   else
      love.graphics.draw(graphics[grabbableObject.image], grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
    end
end

function aboveGrabbableObject(grabbableObject, cursorx, cursory)
   -- Don't grab if it's a special type and we dont have special keys enabled
   if not specialClick and lume.find({"terrainHex", "water", "harbor","numberChit", "dice"}, grabbableObject.pieceType) then
      return false
   end
  if grabbableObject.centered then
    return cursorx > grabbableObject.x - grabbableObject.width/2 and
      cursorx < grabbableObject.x + grabbableObject.width/2 and
      cursory > grabbableObject.y - grabbableObject.height/2 and
      cursory < grabbableObject.y + grabbableObject.height/2
  else
    return cursorx > grabbableObject.x and
      cursorx < grabbableObject.x + grabbableObject.width and
      cursory > grabbableObject.y and
      cursory < grabbableObject.y + grabbableObject.height
  end
end

function moveGrabbableObject(grabbableObject, x, y)
   grabbableObject.x = x
   grabbableObject.y = y
end

function rollDice()
  local dicePossibilities = {1,2,3,4,5,6}
  local diceRoll1 = lume.randomchoice(dicePossibilities)
  local diceRoll2 =  lume.randomchoice(dicePossibilities)
  dice1.image = "white-"..diceRoll1
  dice2.image = "black-"..diceRoll2
end
