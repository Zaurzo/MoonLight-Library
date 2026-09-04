local hooks = {}

-- PreEntityIgnite --

local hook_name = 'Moon.PreEntityIgnite'

-- Catch env_entity_igniter
hook.Add('AcceptInput', hook_name, function(ent, input)
    if not input or input:lower() ~= 'ignite' then return end
    if ent:GetClass() ~= 'env_entity_igniter' then return end

    local key_values = ent:GetKeyValues()
    local target = ents.FindByName(key_values.target)[1]

    if not target then return end

    local can_ignite = hook.Run(hook_name, target, key_values.lifetime, 0 --[[radius = 0]])

    if can_ignite == false then
        return true
    end
end)

-- Detour Entity.Ignite
-- I generally want to avoid detours, but this one is nice and simple
-- and it's a function that usually isn't called many times.

local meta_Entity = FindMetaTable('Entity')
local Ignite = meta_Entity.Ignite

function meta_Entity:Ignite(life_time, radius, ...)
    radius = radius or 0

    local can_ignite = hook.Run(hook_name, self, life_time, radius)

    if can_ignite ~= false then
        return Ignite(self, life_time, radius, ...)
    end
end

table.insert(hooks, hook_name)

return hooks