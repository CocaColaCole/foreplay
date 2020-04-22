local socket = require("socket")
local lume = require("lume")

local udp
local clients = {}

function main()
   udp = socket.udp()
   udp:setsockname("*", 8008)
   udp:settimeout(0)
   while true do
      local events = getEvents()
      for _, event in ipairs(events) do
         handleEvent(event)
      end
   end
end

function getEvents()
   local events = {}
   while true do
      val, ip, port = udp:receivefrom()
      if ip == "timeout" then
         break
      else
         lume.push(events, parseEvent(val, ip, port))
      end
      if not lume.find(clients, {ip=ip, port=port}) then
         lume.push(clients, {ip=ip, port=port})
      end
   end
   return events
end

function parseEvent(val, ip, port)
   event = {ip=ip, port=port}
   action, values = string.match(val, "(.*): <(.*)>")
   if not action then
      return event.action == "unknown"
   end
   if action == "move" then
      id, x, y = string.match(values, "(0x%x+), (%d+), (%d+)")
      event.action = "move"
      event.id = tonumber(id)
      event.x = tonumber(x)
      event.y = tonumber(y)
   end
   return event
end

function handleEvent(event)
   if event.action == "move" then
      packet = string.format("move: <0x%x, %d, %d>", event.id, event.x, event.y)
      for _, client in ipairs(clients) do
         if client.ip ~= event.ip or client.port ~= event.port then
            udp:sendto(packet, client.ip, client.port)
         end
      end
   end
end


main()
