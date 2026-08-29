local table = moon.extend(table)

function table.ipack(...)
    return { [0] = select('#', ...), ... }
end

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

function table.weak(mode)
    local meta = mode and weak_metatables[mode]
    moon.assert(meta, 'invalid mode (must be k, v, or kv)', 2)

    return setmetatable({}, meta)
end

return table