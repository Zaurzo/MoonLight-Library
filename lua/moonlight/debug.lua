local debug = moonlight.extend(debug)
local import = moonlight.import

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