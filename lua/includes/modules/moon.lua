AddCSLuaFile()

-- MoonLight Library
-- By Zaurzo

moon = {}

moon.import = include('moonlight/import.lua')
moon.class = include('moonlight/class.lua')

---@param expr any The expression to assert.
---@param msg? string The error message to throw if the assertion fails.
---@param level? number The level to throw the error at.
---@param ... string The parameters to use to format the error message string.
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

---An assert method that, when fails, mimics the vanilla Lua bad argument error message.
---@param value any The value of passed argument.
---@param arg_num int The argument number.
---@param expected_type string The type the argument value must be.
---@return any value
function moon.assertarg(value, arg_num, expected_type)
    local got_type = type(value)

    if got_type == expected_type then
        return value
    end

    local func_name = debug.getinfo(2, 'n').name or '?'
    local err = BAD_ARG_ERROR:format(arg_num, func_name, expected_type, got_type)

    return error(err, 2)
end

local extension_meta = {
    __index = function(self, key)
        local mdule = rawget(self, 'super')
        local value = mdule[key]

        self[key] = value

        return value
    end
}

---@param mdule table
---@return table
function moon.extend(mdule)
    local extension = {}
    extension.super = mdule

    return setmetatable(extension, extension_meta)
end