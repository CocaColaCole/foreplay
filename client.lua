local socket = require('socket')
local lume = require('lume')

local client = {}
client.connected = false
local udp

function client.connect()
   udp = socket.udp()
   udp:settimeout(0)
   udp:setsockname("*", 5555)
   udp:setpeername("localhost", 8008) -- TODO allow the user to set this
   client.connected = true
end

function client.updatePosition(networkedObject)
   local packet = string.format("move: <0x%x, %d, %d>",
                                networkedObject.id,
                                networkedObject.x,
                                networkedObject.y)
   udp:send(packet)
end

function client.getEvents()
   events = {}
   while true do
      val, err = udp:receive()
      if err == "timeout" or err == "connection refused" then
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
