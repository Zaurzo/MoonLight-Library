local table = moon.extend(table)

---@param ... any
---@return table
function table.ipack(...)
    return { [0] = select('#', ...), ... }
end

---@param tbl table
---@param deep boolean
---@return table copy
function table.copy(tbl, deep)
    if not deep then
        local copy = {}

        for k, v in pairs(tbl) do
            copy[k] = v
        end

        return copy
    end

    return table.Copy(tbl)
end

local weak_metatables = {
    k = { __mode = 'k' },
    v = { __mode = 'v' },
    kv = { __mode = 'kv' }
}

---@param mode string
---@return table
function table.weak(mode)
    local meta = mode and weak_metatables[mode]
    moon.assert(meta, 'invalid mode (must be k, v, or kv)', 2)

    return setmetatable({}, meta)
end

return table