AddCSLuaFile()

local import = {
    _cache = {},
    _caching_enabled = true
}

-- A hard-coded list is required as none of the modules are sent to the client by default
-- Therefore, file.Find will not find them on the client-side
local is_moonlight_module = {
    ['class'] = true,
    ['debug'] = true,
    ['net'] = true,
    ['table'] = true,
    ['classes.queue'] = true
}

---@param pkg string
---@return string path
---@return boolean isDirectory
function import.getpath(pkg)
    if is_moonlight_module[pkg] then
        pkg = 'moonlight.modules.' .. pkg
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

return import