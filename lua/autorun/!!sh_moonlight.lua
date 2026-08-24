-- MoonLight Library
-- By Zaurzo

require('import')

moonlight = moonlight or {}

local extension_meta = {
    __index = function(self, key)
        local parent_lib = rawget(self, '__lib')
        local value = parent_lib[key]

        self[key] = value

        return value
    end
}

---@param lib table
---@return table
function moonlight.extend(lib)
    local extension = {}

    for k, v in pairs(lib) do
        extension[k] = v
    end

    extension.__lib = lib

    return setmetatable(extension, extension_meta)
end