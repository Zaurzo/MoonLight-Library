local entity = moon.extendmeta('Entity')

function entity.GetPhysicsObjects(self)
    local phys_objs = {}

    for i = 0, entity.GetPhysicsObjectCount(self) - 1 do
        phys_objs[i + 1] = entity.GetPhysicsObjectNum(self, i)
	end

    return phys_objs
end

return entity