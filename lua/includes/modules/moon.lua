AddCSLuaFile()

-- MoonLight Library
-- By Zaurzo

moon = {}
moon.pass = function() end

function moon.assert(expr, msg, level, ...)
    if not expr then
        msg = msg or 'assertion failed!'

        if (...) ~= nil then
            msg = msg:format(...)
        end

        return error(msg, level or 1)
    end
    
    return expr
end

local BAD_ARG_ERROR = 'bad argument #%d to \'%s\' (%s expected, got %s)'
local type = type

function moon.assertarg(value, arg_num, expected_type)
    local got_type = type(value) ---@as string

    if got_type == expected_type then
        return value
    end

    local func_name = debug.getinfo(2, 'n').name or '?'
    local err = BAD_ARG_ERROR:format(arg_num, func_name, expected_type, got_type)

    return error(err, 2)
end

-- [[ Extending ]]

local extension_meta = {}

function extension_meta:__index(key)
    local super = rawget(self, 'super')
    local value = super[key]

    rawset(self, key, value)

    return value
end

-- Insert the name of the new field to the extension table.
-- We treat this array portion as a list of all the fields from the actual extension.
function extension_meta:__newindex(key, value)
    rawset(self, #self + 1, key)
    rawset(self, key, value)
end

function moon.extend(tbl)
    return setmetatable({ super = tbl }, extension_meta)
end

-- [[ Extending Meta Tables ]]

local function install(self, target)
    if isentity(target) then
        target = target:GetTable()
    end

    for _, name in ipairs(self) do
        target[name] = self[name]
    end
end

function moon.extendmeta(meta_name)
    local meta = FindMetaTable(meta_name)
    if not meta then return end

    local extension = { super = meta }
    extension.Install = install

    return setmetatable(extension, extension_meta)
end

--[[ Callables ]]

local callable_meta = {}
callable_meta.__index = callable_meta

function callable_meta:setcall(call)
    self.__call = call
end

function callable_meta:__call(...)
    return self:__call(...)
end

-- Creates a callable library.
function moon.callable(func)
    return setmetatable({ __call = func }, callable_meta)
end

moon.import = include('moonlight/import.lua')
moon.class = include('moonlight/class.lua')