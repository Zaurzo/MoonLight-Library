-- MoonLight Library
-- By Zaurzo

moonlight = moonlight or {}

---@param expr any The expression to assert.
---@param msg? string The error message to throw if the assertion fails.
---@param level? number The level to throw the error at.
function moonlight.assert(expr, msg, level)
    if not expr then
        level = level or 1
        msg = msg or 'assertion failed!'

        return error(msg, level)
    end
    
    return expr
end

-- rets = returns / return values
-- mdule = module

--[[ moonlight.import ]] 
do
    local import = {
        _cache = {},
        _caching_enabled = true
    }

    local is_moonlight_module = {}

    do
        local file_list = file.Find('lua/moonlight/*.lua', 'GAME')

        for _, file_name in ipairs(file_list) do
            local mdule_name = file_name:sub(1, -5)

            is_moonlight_module[mdule_name] = true
        end
    end

    ---@param pkg string
    ---@return string
    function import.getpath(pkg)
        if is_moonlight_module[pkg] then
            return 'moonlight/' .. pkg .. '.lua'
        end
        
        if pkg:EndsWith('.lua') then
            return pkg
        end

        return pkg:gsub('%.', '/') .. '.lua'
    end

    ---@param pkg string
    function import.isloaded(pkg)
        local path = import.getpath(pkg)

        return import._cache[path] ~= nil
    end

    function moonlight.importcs(pkg)
        local path = import.getpath(pkg)

        AddCSLuaFile(path)

        return import(path)
    end

    function moonlight.AddCSLuaImport(pkg)
        local path = import.getpath(pkg)

        return AddCSLuaFile(path)
    end

    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    local function import_package(self, pkg)
        local path = import.getpath(pkg)

        if import._caching_enabled then
            local rets = import._cache[path]
            if rets == true then return end

            if rets then
                return unpack(rets, 1, rets.n)
            end
        end

        local rets, ret_count = table.Pack(include(path))

        rets.n = ret_count
        import._cache[path] = ret_count > 0 and rets or true

        if ret_count > 0 then
            return unpack(rets, 1, ret_count)
        end
    end

    setmetatable(import, { __call = import_package })

    moonlight.import = import
end

--[[ moonlight.extend ]] 
do
    local extension_meta = {
        __index = function(self, key)
            local mdule = rawget(self, '__mdule')
            local value = mdule[key]

            self[key] = value

            return value
        end
    }

    ---@param mdule table
    ---@return table
    function moonlight.extend(mdule)
        local extension = {}
        extension.__mdule = mdule

        return setmetatable(extension, extension_meta)
    end
end