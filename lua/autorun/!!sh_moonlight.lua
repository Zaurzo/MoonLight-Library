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
    ---@return table
    local function get_import_rets(pkg)
        local path = get_package_path(pkg)

        if import.caching_enabled then
            local rets = import.cache[path]
            if rets == true then return end

            if rets then
                return rets
            end
        end

        local rets, ret_count = table.Pack(include(path))

        rets.n = ret_count
        import.cache[path] = ret_count > 0 and rets or true

        return rets
    end

    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    local function import_package(self, pkg, ...)
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

    setmetatable(import, { __call = import_package })

    function import.clearcache()
        import.cache = {}
    end

    ---@param enabled boolean
    function import.setcaching(enabled)
        import.cache_enabled = enabled
    end

    function moonlight.importcs(pkg, ...)
        local path = get_package_path(pkg)

        AddCSLuaFile(path)

        return import(pkg, ...)
    end

    function moonlight.AddCSLuaImport(pkg)
        local path = get_package_path(pkg)

        AddCSLuaFile(path)
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

        for k, v in pairs(lib) do
            extension[k] = v
        end

        extension.__lib = lib

        return setmetatable(extension, extension_meta)
    end
end