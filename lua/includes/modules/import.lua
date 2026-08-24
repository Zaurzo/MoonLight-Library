local cache = {}
local cache_enabled = true

-- rets = returns / return values

---@param pkg string
---@return string
local function get_package_path(pkg)
    if pkg:EndsWith('.lua') then
        return pkg
    end

    return pkg:gsub('%.', '/') .. '.lua'
end

local AddCSLuaFile = AddCSLuaFile

---@param pkg string
function AddCSLuaImport(pkg)
    local path = get_package_path(pkg)

    return AddCSLuaFile(path)
end

if not import then
    local include, select, unpack = include, select, unpack
    local table_Pack = table.Pack

    ---@param pkg string
    ---@return table
    local function get_import_rets(pkg)
        local path = get_package_path(pkg)

        if cache_enabled then
            local rets = cache[path]
            if rets == true then return end

            if rets then
                return rets
            end
        end

        local rets, ret_count = table_Pack(include(path))

        rets.n = ret_count
        cache[path] = ret_count > 0 and rets or true

        return rets
    end

    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    function import(pkg, ...)
        local rets = get_import_rets(pkg)
        if not rets then return end

        local lib_field_count = select('#', ...)

        if lib_field_count > 0 and rets[1] then
            local lib_fields = {}
            local lib = rets[1]

            for i = 1, lib_field_count do
                local lib_field_name = select(i, ...)

                lib_fields[i] = lib[lib_field_name]
            end

            return unpack(lib_fields, 1, lib_field_count)
        end

        return unpack(rets, 1, rets.n)
    end
end

if not importcs then
    local import = import
    
    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    function importcs(pkg, ...)
        local path = get_package_path(pkg)

        AddCSLuaFile(path)

        return import(path, ...)
    end
end

-- For addon development/debugging
-- These should never be used in production

function debug.clearimportcache()
    cache = {}
end

---@param enabled boolean
function debug.setimportcaching(enabled)
    cache_enabled = enabled
end