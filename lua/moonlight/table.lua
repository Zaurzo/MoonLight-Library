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
    if not mode or not weak_metatables[mode] then
        return error('invalid mode')
    end

    return setmetatable({}, weak_metatables[mode])
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