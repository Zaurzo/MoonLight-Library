local class = moon.callable()

function class.is(obj, class)
    if obj == class then return true end

    local mt = getmetatable(obj)

    while mt do
        if mt == class or mt.__name == class then
            return true
        end

        mt = getmetatable(mt)
    end

    return false
end

function class.nameof(obj)
    local mt = getmetatable(obj)

    return mt and mt.__name or obj.__name
end

local function instance_init()
    return error('instance has already been initialized')
end

local function instance_tostring(self)
    local class = getmetatable(self)

    return string.format('%s: %p', class.__name, self)
end

local function new(class, ...)
    local instance = setmetatable({}, class)

    instance:init(...)
    instance.init = instance_init

    return instance
end

local function meta_merge(class, base)
    for k, v in pairs(base) do
        if isstring(k) and k:sub(1, 2) == '__' then
            class[k] = v
        end
    end
end

local function create_class(self, name, base, inherit_meta_methods)
    moon.assertarg(name, 1, 'string')

    local class = {
        init = moon.pass,
        new = new,
        __name = name,
        __tostring = instance_tostring
    }

    if base then
        moon.assertarg(base, 2, 'table')

        if inherit_meta_methods ~= false then
            meta_merge(class, base)
        end

        setmetatable(class, base)
    end

    class.__index = class

    return class
end

class:setcall(create_class)

return class