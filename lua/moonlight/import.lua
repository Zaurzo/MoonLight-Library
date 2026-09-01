AddCSLuaFile()

local import = moon.callable()

import._cache = {}
import._caching_enabled = true

-- A hard-coded list is required as none of the modules are sent to the client by default
-- Therefore, file.Find will not find them on the client-side
local is_moonlight_module = {
    ['debug'] = true,
    ['net'] = true,
    ['table'] = true,
    ['util'] = true,
    ['jit'] = true,
    ['entity'] = true,
    ['color'] = true,
    ['rndx'] = true,
    ['classes.queue'] = true
}

function import.getpath(pkg)
    if is_moonlight_module[pkg] then
        pkg = 'moonlight.modules.' .. pkg
    elseif file.Exists('lua/' .. pkg, 'GAME') then
        return pkg, false
    end

    local path = pkg:gsub('%.', '/')

    if file.IsDir('lua/' .. path, 'GAME') then
        return path, true
    end

    return path .. '.lua', false
end

function import.include(file_name)
    local source = debug.getinfo(2, 'S').source
    local _, pos = source:find('lua/')

    if not pos then return end

    local folder = source:sub(pos + 1):GetPathFromFilename()

    return import(folder .. file_name)
end

function import.isloaded(pkg)
    local path = import.getpath(pkg)

    return import._cache[path] ~= nil
end

local add_cs_import = SERVER and function(path, is_dir)
    if not is_dir then
        return AddCSLuaFile(path)
    end

    local file_list = file.Find('lua/' .. path .. '/*', 'GAME')

    -- automatically mark all files that should be sent to the client

    for _, file_name in ipairs(file_list) do
        local prefix = file_name:sub(-3)

        if file_name == 'shared.lua' or prefix == 'cl_' or prefix == 'sh_' then
            AddCSLuaFile(path .. '/' .. file_name)
        end
    end
end

function moon.importcs(pkg)
    if SERVER then
        add_cs_import(import.getpath(pkg))
    end

    return import(pkg)
end

function moon.AddCSLuaImport(pkg)
    if SERVER then
        return add_cs_import(import.getpath(pkg))
    end
end

local function pack(...)
    return { n = select('#', ...), ... }
end

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
            file_path = path .. '/init.lua'
        else
            file_path = path .. '/cl_init.lua'
        end

        if not file.Exists('lua/' .. file_path, 'GAME') then
            file_path = path .. '/shared.lua'
        end
    end

    rets = pack(include(file_path))

    if rets.n > 0 then
        import._cache[path] = rets

        return unpack(rets, 1, rets.n)
    end

    import._cache[path] = true
end

import:setcall(import_package)

return import