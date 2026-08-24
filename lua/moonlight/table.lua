local table = moonlight.extend(table)

---@param ... any
---@return table
function table.ipack(...)
    return { [0] = select('#', ...), ... }
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