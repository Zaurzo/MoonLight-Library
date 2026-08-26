local util = {}

---@param pos Vector
---@param magnitude? number
---@param radius? number
function util.Explosion(pos, magnitude, radius)
    moon.assertarg(pos, 1, 'Vector')

    local explosion = ents.Create('env_explosion')

    if not explosion:IsValid() then 
        return NULL 
    end

    explosion:SetPos(pos)
    explosion:Spawn()
    explosion:SetKeyValue('iMagnitude', magnitude or 10.0)

    if radius then
        explosion:SetKeyValue('iRadiusOverride', radius)
    end

    explosion:Fire('Explode')

    return explosion
end

return util