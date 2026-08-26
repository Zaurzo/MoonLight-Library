local net = moonlight.extend(net)
local moon_receivers = {}

net.Pool = util.AddNetworkString

if SERVER then
    net.Pool('moonlight')
end

---@param name string
---@param callback function
function net.SetMoonReceiver(name, callback)
    moon_receivers[name] = callback
end

---@param name string
function net.MoonStart(name)
    net.Start('moonlight')
    net.WriteString(name)
end

net.Receive('moonlight', function(len, ply)
    local receiver_name = net.ReadString()
    local receiver = moon_receivers[receiver_name]

    if receiver then
        return receiver(len, ply)
    end
end)

return net