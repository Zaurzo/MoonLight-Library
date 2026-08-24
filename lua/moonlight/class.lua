local class_meta = {}

class_meta.__init = function() end
class_meta.__index = class_meta
class_meta.__name = 'Class'

function class_meta:__call(...)
    local instance = setmetatable({}, self)
    instance:__init(...)

    return instance
end

function class_meta:__tostring()
    local base = self.base
    local name = self.__name
    
    if base then
        return string.format('Class [%s][%s]', name, base.__name)
    end

    return string.format('Class [%s]', name)
end

local function instance_tostring(self)
    return string.format('%s: %p', self.__name, self)
end

local function new_class(name, base)
    moonlight.assert(isstring(name), 'class name must be a string', 2)
    moonlight.assert(not base or istable(base), 'base class must be a table', 2)

    local class = {}

    if base then
        for k, v in pairs(base) do
            class[k] = v
        end

        class.base = base
    end

    class.__index = class
    class.__name = name
    class.__tostring = instance_tostring

    return setmetatable(class, class_meta)
end

return new_class