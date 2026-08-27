local debug = moon.extend(debug)
local func_info_cache = setmetatable({}, { __mode = 'k' })

---@param func function
function debug.funcinfo(func)
    local info = func_info_cache[func]
    
    if info then
        return info
    end

    moon.assertarg(func, 1, 'function')

    info = debug.getinfo(func)
    info.func = nil -- remove strong reference

    ---@diagnostic disable-next-line
    local jit_info = jit.util.funcinfo(func)

    -- Merge some debug info from jit.util.funcinfo
    info.loc = jit_info.loc
    info.gcconsts = jit_info.gcconsts
    info.nconsts = jit_info.nconsts
    info.bytecodes = jit_info.bytecodes
    info.children = jit_info.children
    info.stackslots = jit_info.stackslots

    func_info_cache[func] = info

    return info
end

local import = moon.import

---@param pkg string
function debug.clearimport(pkg)
    if pkg == '*' then
        import._cache = {}
    else
        local path = import.getpath(pkg)

        import._cache[path] = nil
    end
end

---@param enabled boolean
function debug.setcacheimports(enabled)
    import._caching_enabled = enabled
end

return debug