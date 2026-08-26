AddCSLuaFile()

-- MoonLight Library
-- By Zaurzo

moonlight = {}
moonlight.import = include('moonlight/import.lua')

---@param expr any The expression to assert.
---@param msg? string The error message to throw if the assertion fails.
---@param level? number The level to throw the error at.
---@param ... string The parameters to use to format the error message string.
function moonlight.assert(expr, msg, level, ...)
    if not expr then
        msg = msg or 'assertion failed!'

        if (...) ~= nil then
            msg = msg:format(...)
        end

        return error(msg, level or 1)
    end
    
    return expr
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
function moonlight.extend(mdule)
    local extension = {}
    extension.super = mdule

    return setmetatable(extension, extension_meta)
end