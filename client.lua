local socket = require('socket')
local lume = require('lume')

local client = {}
client.connected = false
local tcp

function client.connect()
   tcp = socket.tcp()
   local ok, err = tcp:connect("localhost", 8008) -- TODO allow the user to set this
   if err then
      error(err)
   end
   tcp:settimeout(0)
   client.connected = true
end

function client.updatePosition(networkedObject)
   local packet = string.format("move: <0x%x, %d, %d>\r\n",
                                networkedObject.id,
                                networkedObject.x,
                                networkedObject.y)
   tcp:send(packet)
end

function client.getEvents()
   events = {}
   while true do
      val, err = tcp:receive()
      if err == "timeout" or err == "closed" then
         break
      elseif val then
         lume.push(events, client.parseEvent(val))
      else
         error(err)
      end
   end
   return events
end

function client.parseEvent(val)
   action, values = string.match(val, "(.*): <(.*)>")
   if not action then
      return {action="unknown"}
   end
   if action == "move" then
      id, x, y = string.match(values, "(0x%x+), (%d+), (%d+)")
      return {action="move", id=tonumber(id), x=tonumber(x), y=tonumber(y)}
   end
end


return client
