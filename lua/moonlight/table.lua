local table = moonlight.extend(table)

---@param ... any
---@return table
function table.ipack(...)
    return { [0] = select('#', ...), ... }
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
    moonlight.assert(meta, 'invalid mode (expected k, v, or kv)', 2)

    return setmetatable({}, meta)
end

---@param tbl table
---@return table copy
function table.ShallowCopy(tbl)
    local copy = {}

    for k, v in pairs(tbl) do
        copy[k] = v
    end

    return copy
end

return table