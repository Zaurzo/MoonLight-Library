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

function util.CreateEntityIterator(collector)
    local cache
    local entity_cache

    local function iterator()
        local _, current_entity_cache = ents.Iterator()
        
        if entity_cache ~= current_entity_cache then
            cache = collector()
            entity_cache = current_entity_cache
        end

        return ipairs(cache)
    end

    return iterator
end

return util
