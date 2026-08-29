local net = moon.extend(net)
local moon_receivers = {}

net.Pool = util.AddNetworkString

if SERVER then
    net.Pool('moonlight')
end

net.super.Receive('moonlight', function(len, ply)
    local receiver_name = net.ReadString()
    local receiver = moon_receivers[receiver_name]

    if receiver then
        return receiver(len, ply)
    end
end)

function net.Receive(name, callback)
    moon_receivers[name] = callback
end

function net.Start(name)
    net.super.Start('moonlight')
    net.WriteString(name)
end

return net