-- MoonLight Library
-- By Zaurzo

moonlight = moonlight or {}

--[[ moonlight.import ]] 
do
    local import = {
        cache = {},
        caching_enabled = true
    }

    local is_moonlight_lib do
        local file_list = file.Find('lua/moonlight/*.lua', 'GAME')
    
        is_moonlight_lib = {}

        for _, file_name in ipairs(file_list) do
            local lib_name = file_name:sub(1, -5)

            is_moonlight_lib[lib_name] = true
        end
    end

    ---@param pkg string
    ---@return string
    local function get_package_path(pkg)
        if is_moonlight_lib[pkg] then
            return 'moonlight/' .. pkg .. '.lua'
        end

        if pkg:EndsWith('.lua') then
            return pkg
        end

        return pkg:gsub('%.', '/') .. '.lua'
    end

    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    local function import_package(self, pkg)
        local path = get_package_path(pkg)

        if import.caching_enabled then
            local rets = import.cache[path]
            if rets == true then return end

            if rets then
                return unpack(rets, 1, rets.n)
            end
        end

        local rets, ret_count = table.Pack(include(path))

        rets.n = ret_count
        import.cache[path] = ret_count > 0 and rets or true

        if ret_count > 0 then
            return unpack(rets, 1, ret_count)
        end
    end

    setmetatable(import, { __call = import_package })

    function import.clearcache()
        import.cache = {}
    end

    ---@param enabled boolean
    function import.setcaching(enabled)
        import.caching_enabled = enabled
    end

    function moonlight.importcs(pkg)
        local path = get_package_path(pkg)

        AddCSLuaFile(path)

        return import(path)
    end

    function moonlight.AddCSLuaImport(pkg)
        local path = get_package_path(pkg)

        return AddCSLuaFile(path)
    end

    moonlight.import = import
end

--[[ moonlight.extend ]] 
do
    local extension_meta = {
        __index = function(self, key)
            local parent_lib = rawget(self, '__lib')
            local value = parent_lib[key]

            self[key] = value

            return value
        end
    }

    ---@param lib table
    ---@return table
    function moonlight.extend(lib)
        local extension = {}
        extension.__lib = lib

        return setmetatable(extension, extension_meta)
    end
end