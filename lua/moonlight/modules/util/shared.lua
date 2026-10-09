local util = moon.extend(util)
local ARG_ERROR = "bad argument #%d to '%s' (%s expected, got %s)"

function util.CheckArg(arg, expected_type, value, no_halt)
    local arg_type = type(value)

    if arg_type == expected_type then
        return true
    end

    local info = debug.getinfo(2, 'n')
    local func_name = (info and info.name) or '?'
    local error_msg = ARG_ERROR:format(arg, func_name, expected_type, arg_type)

    if no_halt then
        return ProtectedCall(error, error_msg, 3)
    end

    return error(error_msg, 2)
end

function util.GetCurrentFile(level)
    level = level or 1

    local info = debug.getinfo(level + 1, 'S')
    moon.assert(info, 'invalid level %d', 2, level)

    return info.source:sub(2)
end

local wreg = moon.getweakregistry()

local function iterator_cache_invalid()
    local _, cache = ents.Iterator() -- entity cache gets refreshed every time an entity is created or removed
    local is_invalid = cache ~= wreg[1]

    wreg[1] = cache

    return is_invalid
end

function util.CreateEntityIterator(collector)
    local cache

    local function iterator()
        if iterator_cache_invalid() then
            cache = collector()
        end

        return ipairs(cache)
    end

    return iterator
end

return util
