AddCSLuaFile()

-- MoonLight Library
-- By Zaurzo

moonlight = {}

-- A hard-coded list is required as none of the modules are sent to the client by default
-- Therefore, file.Find will not find them on the client-side
local is_moonlight_module = {
    ['class'] = true,
    ['debug'] = true,
    ['net'] = true,
    ['table'] = true,
    ['classes.queue'] = true
}

---@param expr any The expression to assert.
---@param msg? string The error message to throw if the assertion fails.
---@param level? number The level to throw the error at.
---@param ... string The parameters to use to format the error message string.
function moonlight.assert(expr, msg, level, ...)
    if not expr then
        msg = msg or 'assertion failed!'

        if (...) ~= nil then
            msg = msg:format(...)
        end

        return error(msg, level or 1)
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

    ---@param pkg string
    ---@return string path
    ---@return boolean isDirectory
    function import.getpath(pkg)
        if is_moonlight_module[pkg] then
            pkg = 'moonlight.' .. pkg
        end

        local path = pkg:gsub('%.', '/')

        if file.IsDir('lua/' .. path, 'GAME') then
            return path, true
        end

        return path .. '.lua', false
    end

    ---@param pkg string
    function import.isloaded(pkg)
        local path = import.getpath(pkg)

        return import._cache[path] ~= nil
    end

    function moonlight.importcs(pkg)
        local path, is_dir = import.getpath(pkg)

        if is_dir then
            AddCSLuaFile(path .. '/cl_init.lua')
        else
            AddCSLuaFile(path)
        end

        return import(pkg)
    end

    function moonlight.AddCSLuaImport(pkg)
        local path, is_dir = import.getpath(pkg)

        if is_dir then
            path = path .. '/cl_init.lua'
        end

        return AddCSLuaFile(path)
    end

    ---@return table
    local function pack(...)
        return { n = select('#', ...), ... }
    end

    ---@param pkg string
    ---@param ...? string
    ---@return ... any
    local function import_package(self, pkg)
        local path, is_dir = import.getpath(pkg)
        local rets = import._caching_enabled and import._cache[path]

        if rets then
            if rets ~= true then
                return unpack(rets, 1, rets.n)
            end

            return
        end

        local file_path = path

        if is_dir then
            if SERVER then
                file_path = file_path .. '/init.lua'
            else
                file_path = file_path .. '/cl_init.lua'
            end
        end

        rets = pack(include(file_path))

        if rets.n > 0 then
            import._cache[path] = rets

            return unpack(rets, 1, rets.n)
        end

        import._cache[path] = true
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