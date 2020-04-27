local socket = require('socket')
local lume = require('lume')

local net = {}
net.connected = false
net.mode = nil
net.clients = {}
local tcp

function net.joinGame(hostname)
   tcp = socket.tcp()
   local ok, err = tcp:connect(hostname, 8008)
   if err then
      error(err)
   end
   tcp:settimeout(0)
   net.connected = true
   net.mode = "client"
   print("connected to server!")
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
   local joinEvents = {}
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
         lume.push(net.clients, {ip=ip, port=port, socket=client})
         lume.push(joinEvents, {action="join", ip=ip, port=port})
         print(string.format("accepted new client %s:%d", ip, port))
      end
   until done
   return joinEvents
end

function net.broadcast(packet)
   for _, client in ipairs(net.clients) do
      client.socket:send(packet)
   end
end

function net.updatePosition(networkedObject)
   local packet = string.format("move: <0x%x, %d, %d>\r\n",
                                networkedObject.id,
                                networkedObject.x,
                                networkedObject.y)
   if net.mode == "client" then
      tcp:send(packet)
   elseif net.mode == "server" then
      net.broadcast(packet)
   end
end

function net.sendGamestate(gamestate, ip, port)
   local client = lume.first(lume.filter(net.clients, function(x) return ip == x.ip and port == x.port end))
   local packet = string.format("gamestate: <%s>\r\n", gamestate)
   client.socket:send(packet)
end

function net.clientGetEvents()
   local events = {}
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

function net.serverGetEvents(dt)
   local events = net.acceptNewClients()
   for _, client in ipairs(net.clients) do
      local done = false
      repeat
         local val, err = client.socket:receive()
         if err == "timeout" or err == "closed" then
            break
         elseif val then
            local event = net.parseEvent(val)
            event.ip = client.ip
            event.port = client.port
            lume.push(events, event)
         else
            error(err)
         end
      until done
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
   if action == "gamestate" then
      return {action="gamestate", gamestate=values}
   end
end


return net
