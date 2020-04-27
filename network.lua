local socket = require('socket')
local lume = require('lume')

local net = {}
net.connected = false
net.mode = nil
net.clients = {}
local tcp

function net.joinGame()
   tcp = socket.tcp()
   local ok, err = tcp:connect("localhost", 8008) -- TODO allow the user to set this
   if err then
      error(err)
   end
   tcp:settimeout(0)
   net.connected = true
   net.mode = "client"
end

function net.hostGame()
   tcp = socket.tcp()
   tcp:bind("*", 8008)
   tcp:settimeout(0)
   tcp:listen()
   net.connected = true
   net.mode = "server"
end

function net.acceptNewClients()
   local done = false
   repeat
      client, err = tcp:accept()
      if err then
         if err == "timeout" then
            done = true
         else
            error(err)
         end
      else
         local ip, port = client:getpeername()
         client:settimeout(0)
         lume.push(clients, {ip=ip, port=port, socket=client})
         print(string.format("accepted new client %s:%d", ip, port))
      end
   until done
end

function net.propogate(packet)
   for _, client in ipairs(net.clients) do
      client.socket.send(packet)
   end
end

function net.updatePosition(networkedObject)
   local packet = string.format("move: <0x%x, %d, %d>\r\n",
                                networkedObject.id,
                                networkedObject.x,
                                networkedObject.y)
   if mode == "client" then
      tcp:send(packet)
   elseif mode == "server" then
      net.broadcast(packet)
   end
end

function net.getEvents()
   if net.connected and net.mode == "server" then
      net.acceptNewClients()
   end
   events = {}
   while true do
      val, err = tcp:receive()
      if err == "timeout" or err == "closed" then
         break
      elseif val then
         lume.push(events, net.parseEvent(val))
      else
         error(err)
      end
   end
   return events
end

function net.parseEvent(val)
   action, values = string.match(val, "(.*): <(.*)>")
   if not action then
      return {action="unknown"}
   end
   if action == "move" then
      id, x, y = string.match(values, "(0x%x+), (%d+), (%d+)")
      return {action="move", id=tonumber(id), x=tonumber(x), y=tonumber(y)}
   end
end


return net
