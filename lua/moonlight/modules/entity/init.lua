local entity = include('shared.lua')

function entity.Kill(self, dmginfo)
    entity.SetHealth(self, 0)

    if dmginfo then
        local dmg = dmginfo:GetDamage()

        if dmg < 0 or math.IsNearlyEqual(dmg, 0) then
            dmginfo:SetDamage(1)
        end

        entity.TakeDamageInfo(self, dmginfo)

        dmginfo:SetDamage(dmg)
    else
        entity.TakeDamage(self, 1)
    end
end

return entity