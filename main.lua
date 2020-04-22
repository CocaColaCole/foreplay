function love.load()
  wheat = newGrabbableObject(love.graphics.newImage("wheat.png"),100,100, 100, 100, true)
end



local cursorx = 0
local cursory = 0
local mouseclicked = 0

function love.update()
  if wheat.grabbed then
    wheat.x = love.mouse.getX() + wheat.grabOffsetx
    wheat.y = love.mouse.getY() + wheat.grabOffsety
  end
end

function love.draw()
  drawGrabbableObject(wheat)
  love.graphics.print(cursorx..","..cursory,10,10)
  love.graphics.print(wheat.x..","..wheat.y..","..wheat.width..","..wheat.height,500,500)
end

function love.mousepressed(x,y,button,istouch,presses)
  cursorx, cursory = love.mouse.getPosition()
  if button == 1 and aboveGrabbableObject(wheat, cursorx, cursory) then
    mouseclicked = 1
    wheat.grabbed = true
    wheat.grabOffsetx = wheat.x-love.mouse.getX()
    wheat.grabOffsety = wheat.y-love.mouse.getY()
  end
end

function love.mousereleased(x,y,button,istouch,presses)
  if button == 1 then
    mouseclicked = 0
    wheat.grabbed = false
  end
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
