local lume = require('lume')
local client = require('client')
math.randomseed(os.time())
local gameObjects = {}
local nextId = 1
local hexLocation = {{300,150},{400,150},{500,150},
                {250,225},{350,225},{450,225},{550,225},
            {200,300},{300,300},{400,300},{500,300},{600,300},
                {250,375},{350,375},{450,375},{550,375},
                    {300,450},{400,450},{500,450}}--x,y
local hexChoices = {"wood","wood","wood","wood","sheep","sheep","sheep","sheep","wheat","wheat","wheat","wheat","brick","brick","brick","stone","stone","stone","desert"}
function love.load()
   initializeGameboard()
   --client.connect()
end

local cursorx = 0
local cursory = 0
local mouseclicked = 0

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
   lume.each(gameObjects, drawGrabbableObject)
   love.graphics.setBackgroundColor(0/255, 80/255, 161/255)
end

function love.mousepressed(x,y,button,istouch,presses)
   local cursorx, cursory = love.mouse.getPosition()
   local grabbedObjIdx
   for i, obj in lume.ripairs(gameObjects) do -- go in reverse so we grab the top objects first
      if button == 1 and aboveGrabbableObject(obj, cursorx, cursory) then
         mouseclicked = 1
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
    table.insert(gameObjects, newGrabbableObject(love.graphics.newImage("resources/wheat.png"),love.graphics.newImage("resources/honeycomb.png"),100,100, 100, 100, true))
    table.insert(gameObjects, newGrabbableObject(love.graphics.newImage("resources/wheat.png"),love.graphics.newImage("resources/honeycomb.png"),100,300, 100, 100, true))
--gameboard render
lume.shuffle(hexChoices)
    for i = 1, 19 do
        local terrain = lume.randomchoice(hexChoices)
        lume.remove(hexChoices,terrain)
        table.insert(gameObjects, newGrabbableObject(love.graphics.newImage("resources/"..terrain.."-hex.png"),love.graphics.newImage("resources/water-hex.png"),hexLocation[i][1],hexLocation[i][2],100,100,true))
    end
end

function newGrabbableObject (image, back, x, y, w, h, centered, rot)
   local grabbableObject = {}
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
   return grabbableObject
end

function drawGrabbableObject (grabbableObject)
  if grabbableObject.flipped then
    love.graphics.draw(grabbableObject.back, grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
  else
    love.graphics.draw(grabbableObject.image, grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
  end
end

function aboveGrabbableObject(grabbableObject, cursorx, cursory)
   return cursorx > grabbableObject.x - grabbableObject.width/2 and
      cursorx < grabbableObject.x + grabbableObject.width/2 and
      cursory > grabbableObject.y - grabbableObject.height/2 and
      cursory < grabbableObject.y + grabbableObject.height/2
end

function moveGrabbableObject(grabbableObject, x, y)
   grabbableObject.x = x
   grabbableObject.y = y
end
