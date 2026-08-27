local entity = moon.extendmeta('Entity')

---@param self Entity
---@return PhysObj[]
function entity.GetPhysicsObjects(self)
    local phys_objs = {}

    for i = 0, self:GetPhysicsObjectCount() - 1 do
        phys_objs[i + 1] = self:GetPhysicsObjectNum(i)
	end

    return phys_objs
end

return entity