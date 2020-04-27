local socket = require("socket")
local lume = require("lume")

local tcp


function getEvents()
   local events = {}
   for i, client in ipairs(clients) do
      local done = false
      repeat
         val, err = client.socket:receive() -- Read one line of text
         if err then
            if err == "timeout" then
               done = true
            elseif err == "closed" then
               table.remove(clients, i)
               done = true
            else
               error(err)
            end
         else
            lume.push(events, parseEvent(val, client.ip, client.port))
         end
      until done
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
      packet = string.format("move: <0x%x, %d, %d>\r\n", event.id, event.x, event.y)
      for _, client in ipairs(clients) do
         if client.ip ~= event.ip or client.port ~= event.port then
            client.socket:send(packet)
         end
      end
   end
end

main()
