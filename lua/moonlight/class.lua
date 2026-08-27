---@diagnostic disable
-- MoonLight Class Meta

local class_meta = {}
local reserved = {
    base = true,
    __name = true
}

function class_meta:__index(k)
    return self._class[k]
end

function class_meta:__newindex(k, v)
    moon.assert(not reserved[k], 'cannot override reserved field %q', 2, k)

    self._class[k] = v
end

function class_meta:__tostring()
    local class = self._class
    local base = getmetatable(class)

    if base then
        return string.format('Class [%s][%s]', class.__name, base.__name)
    end

    return string.format('Class [%s]', class.__name)
end

local function instance_init()
    return error('instance is already initialized')
end

function class_meta:__call(...)
    local instance = {}
    local class = self._class ---@as table

    instance.base = getmetatable(class)

    setmetatable(instance, class)

    instance:init(...)
    instance.init = instance_init

    return instance
end

-- Class Module

local class = {}

function class.ismoonlight(obj)
    return getmetatable(obj) == class_meta
end

---@param class table
function class.nameof(instance)
    if class.ismoonlight(instance) then
        return instance._class.__name
    end

    local class = getmetatable(instance)

    return class and class.__name or nil
end

function class.is(instance, class)
    class = class._class or class

    if not class then 
        return false 
    end

    local mt = getmetatable(instance)

    while mt do
        if mt == class or mt.__name == class then
            return true
        end

        mt = getmetatable(mt)
    end

    return false
end

local function instance_tostring(self)
    local class = getmetatable(self)

    return string.format('%s: %p', class.__name, self)
end

local emptyf = function() end

local function new_class(self, name, base)
    moon.assertarg(name, 1, 'string')

    local class = { init = emptyf }

    class.__name = name
    class.__index = class
    class.__tostring = instance_tostring

    if base then
        moon.assert(self.ismoonlight(base), 'base class is not a moonlight class', 2)

        setmetatable(class, base._class)
    end

    return setmetatable({ _class = class }, class_meta)
end

setmetatable(class, { __call = new_class })

return class