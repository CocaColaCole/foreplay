local lume = require('lume')

local gameObjects = {}

function love.load()
   initializeGameboard()
end

local cursorx = 0
local cursory = 0
local mouseclicked = 0

function love.update()
   lume.each(gameObjects, moveIfGrabbed)
end

function moveIfGrabbed(obj)
   if obj.grabbed then
      obj.x = love.mouse.getX() + obj.grabOffsetx
      obj.y = love.mouse.getY() + obj.grabOffsety
   end
end


function love.draw()
   lume.each(gameObjects, drawGrabbableObject)
   love.graphics.print(cursorx..","..cursory,10,10)
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
   table.insert(gameObjects, newGrabbableObject(love.graphics.newImage("resources/wheat.png"),100,100, 100, 100, true))
   table.insert(gameObjects, newGrabbableObject(love.graphics.newImage("resources/wheat.png"),100,300, 100, 100, true))
end

function newGrabbableObject (image, x, y, w, h, centered, rot)
   local grabbableObject = {}
   grabbableObject.image  = image
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
   return grabbableObject
end

function drawGrabbableObject (grabbableObject)
   love.graphics.draw(grabbableObject.image, grabbableObject.x, grabbableObject.y , grabbableObject.rotation, grabbableObject.sx, grabbableObject.sy, grabbableObject.ox, grabbableObject.oy)
end

function aboveGrabbableObject(grabbableObject, cursorx, cursory)
   return cursorx > grabbableObject.x - grabbableObject.width/2 and
      cursorx < grabbableObject.x + grabbableObject.width/2 and
      cursory > grabbableObject.y - grabbableObject.height/2 and
      cursory < grabbableObject.y + grabbableObject.height/2
end
