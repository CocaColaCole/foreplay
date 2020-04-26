local lume = require('lume')
local client = require('client')
math.randomseed(os.time())
local gameObjects = {}
local nextId = 1
local hexLocation = {{300,150},{250,225},{200,300},{250,375},{300,450},{400,450},{500,450},{550,375},{600,300},{550,225},{500,150},{400,150},
                     {350,225},{300,300},{350,375},{450,375},{500,300},{450,225},{400,300}} --spiral layout
--[[                    {{300,150},{400,150},{500,150},
                {250,225},{350,225},{450,225},{550,225},
            {200,300},{300,300},{400,300},{500,300},{600,300},
                {250,375},{350,375},{450,375},{550,375},
                    {300,450},{400,450},{500,450}}--x,y --]]
local terrainDistribution = {{"wood",4},{"sheep",4},{"wheat",4},{"brick",3},{"stone",3},{"desert",1}}
local devCardDistribution = {{"knight",14},{"VP",5},{"cornucopia",2},{"top-hat",2},{"road",2}}
local resourceDistribution = {{"wood",19},{"sheep",19},{"wheat",19},{"brick",19},{"stone",19}}
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



--local hexChoices = {"wood","wood","wood","wood","sheep","sheep","sheep","sheep","wheat","wheat","wheat","wheat","brick","brick","brick","stone","stone","stone","desert"}
function love.load()
   initializeGameboard()
   --client.connect()
end

local cursorx = 0
local cursory = 0
local mouseclicked = 0
local dice = 0


function love.update()
   --local events = client.getEvents()
  -- for _, event in ipairs(events) do
      --if event.action == "move" then
      --   obj = lume.first(lume.filter(gameObjects, function(obj) return obj.id == event.id end))
      --   if not obj.grabbed then
      --      moveGrabbableObject(obj, event.x, event.y)
      --   end
    --  end
  -- end
   lume.each(gameObjects, moveIfGrabbed)
  --print(love.mouse.getX()..","..love.mouse.getY())

end



function moveIfGrabbed(obj)
   if obj.grabbed then
      moveGrabbableObject(obj, love.mouse.getX() + obj.grabOffsetx, love.mouse.getY() + obj.grabOffsety)
      if client.connected then -- If this is a networked game send the new coords
         client.updatePosition(obj)
      end
   end
end


function love.draw()
   for i, obj in ipairs(gameObjects) do
     if obj.pieceType == "number" then
       love.graphics.setColor(0,0,0)
     else
       love.graphics.reset()
     end
   drawGrabbableObject(obj)
   end
   --lume.each(gameObjects, drawGrabbableObject)
   love.graphics.setBackgroundColor(0/255, 80/255, 161/255)
end

function love.mousepressed(x,y,button,istouch,presses)
   local cursorx, cursory = love.mouse.getPosition()
   local grabbedObjIdx
   for i, obj in lume.ripairs(gameObjects) do -- go in reverse so we grab the top objects first
      if button == 1 and aboveGrabbableObject(obj, cursorx, cursory) then
         mouseclicked = 1
         if obj.grabbable then
           obj.grabbed = true
           obj.grabOffsetx = obj.x-love.mouse.getX()
           obj.grabOffsety = obj.y-love.mouse.getY()
           if presses == 2 then
             if not obj.flipped then
               obj.flipped = true
             else
               obj.flipped = false
             end
           end
           grabbedObjIdx = i
           break
         end
         if obj.pieceType == "dice" and presses == 2 then
           obj.text = rollDice()
           obj.image = love.graphics.newText(love.graphics.newFont("resources/arial.ttf"),obj.text)
        end
      end
   end
   if grabbedObjIdx then
      -- Move this object to the top of the list
      lume.push(gameObjects, table.remove(gameObjects, grabbedObjIdx))
   end
end

function love.mousereleased(x,y,button,istouch,presses)
   if button == 1 then
      mouseclicked = 0
      lume.each(gameObjects, function(obj) obj.grabbed = false end)
   end
end

function initializeGameboard()
    local terrainHexMapping = unpackDistribution(terrainDistribution,true)
    for i, terrain in lume.ripairs(terrainHexMapping) do
        table.insert(gameObjects, newGrabbableObject("terrainHex", love.graphics.newImage("resources/"..terrain.."-hex.png"),love.graphics.newImage("resources/water-hex.png"),hexLocation[i][1],hexLocation[i][2],100,100,true))
        if terrain ~= "desert" then
          table.insert(gameObjects,newScaleableText("number",numberMapping[1],hexLocation[i][1],hexLocation[i][2],50,50,true,0))
        end
    end
    local devCardMapping = unpackDistribution(devCardDistribution,true)
    for i, card in lume.ripairs(devCardMapping) do
      table.insert(gameObjects, newGrabbableObject("card", love.graphics.newImage("resources/round-shield.png"),love.graphics.newImage("resources/"..card..".png"),750,550,100,100,true))
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
        table.insert(gameObjects, newGrabbableObject("card", love.graphics.newImage("resources/"..resource..".png"),love.graphics.newImage("resources/honeycomb.png"),750,ypos, 100, 100, true))
    end
    local buildingMapping = unpackDistribution(buildingDistribution)
    for i, building in ipairs(buildingMapping) do
      local h = 30
      local w = 30
      if building == "path" then
        h = 5
        w = 50
      end
      table.insert(gameObjects, newGrabbableObject(building, love.graphics.newImage("resources/"..building..".png"),love.graphics.newImage("resources/"..building..".png"),200,50,h,w,true))
    end

end


function newGrabbableObject (pieceType, image, back, x, y, w, h, centered, rot)
   local grabbableObject = {}
   grabbableObject.pieceType = pieceType
   grabbableObject.centered = centered
   grabbableObject.image  = image
   grabbableObject.back = back
   grabbableObject.sx = w/image:getWidth()
   grabbableObject.sy = h/image:getHeight()
   grabbableObject.ox = 0
   grabbableObject.oy = 0
   grabbableObject.width = w
   grabbableObject.height = h
   if centered == true then
      grabbableObject.ox = image:getWidth()/2
      grabbableObject.oy = image:getWidth()/2
   end
   grabbableObject.rotation = rot
   grabbableObject.x = x
   grabbableObject.y = y
   grabbableObject.grabbed = false
   grabbableObject.id = nextId
   nextId = nextId + 1
   grabbableObject.grabbable = true
   return grabbableObject
end

function newScaleableText (pieceType, text, x, y, w, h, centered, rot)
   local scaleableText = {}
   scaleableText.font = love.graphics.newFont("resources/arial.ttf")
   scaleableText.pieceType = pieceType
   scaleableText.centered = centered
   scaleableText.text = text
   scaleableText.image  = love.graphics.newText(scaleableText.font,text)
   scaleableText.sx = w/scaleableText.font:getWidth(text)
   scaleableText.sy = h/scaleableText.font:getHeight(text)
   scaleableText.ox = 0
   scaleableText.oy = 0
   scaleableText.width = w
   scaleableText.height = h
   if centered == true then
      scaleableText.ox = scaleableText.font:getWidth(text)/2
      scaleableText.oy = scaleableText.font:getHeight(text)/2
   end
   scaleableText.rotation = rot
   scaleableText.x = x
   scaleableText.y = y
   scaleableText.grabbable = false
   return scaleableText
end

--function drawScaleableText (scaleableText)
  --love.graphics.print(scaleableText.text,scaleableText.x,scaleableText.y,scaleableText.rotation,scaleableText.sx,scaleableText.sy,scaleableText.ox,scaleableText.oy)
--end

function drawGrabbableObject (grabbableObject)
    if grabbableObject.flipped then
      love.graphics.draw(grabbableObject.back, grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
    else
      love.graphics.draw(grabbableObject.image, grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
    end
end

function aboveGrabbableObject(grabbableObject, cursorx, cursory)
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
  local diceRoll = 0
  diceRoll = lume.randomchoice(dicePossibilities) + lume.randomchoice(dicePossibilities)
  return diceRoll
end
