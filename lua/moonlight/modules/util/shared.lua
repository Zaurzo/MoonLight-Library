local util = moon.extend(util)

function util.GetCurrentFile(level)
    level = level or 1

    local info = debug.getinfo(level + 1, 'S')
    moon.assert(info, 'invalid level %d', 2, level)

    return info.source:sub(2)
end

return util