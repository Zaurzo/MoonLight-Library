local jit = moon.extend(jit)

--[[ Bytecode and Protos ]]

local BytecodeReader = include('sh_bytecode_reader.lua')
local Proto = moon.import.include('sh_proto.lua')
local BCDUMP = moon.import.include('sh_bcdump_enum.lua')

function jit.dumpbc(func)
    local ok, dump = pcall(string.dump, func)
    if not ok then return end

    return BytecodeReader:new(dump)
end

local proto_cache = setmetatable({}, { __mode = 'k' })

function jit.getproto(func)
    local proto = proto_cache[func]
    if proto then return proto end

    if moon.class.is(func, Proto) then
        return func
    end

    local bc = jit.dumpbc(func)
    if not bc then return end

    proto = bc:getproto(1)
    proto_cache[func] = proto

    return proto
end

-- [[ Partially re-implement jit.util.funck ]]
-- 
-- These functions are inferior and return pseudos of some constants, such as tables.
-- This is no problem though, as I only use it for analyzation.

local function get_gc_const(proto, index, const_type)
    local const, t = proto:getconstgc(proto:constcountgc() - index)
    if const_type and t ~= const_type then return end

    if t == BCDUMP.KGC.Table then
        local copy = {}

        for k, v in pairs(const) do
            copy[k] = v
        end

        const = copy
    end

    return const, t
end

function jit.getconstgc(func, index)
    local proto = jit.getproto(func)
    if not proto then return end

    return get_gc_const(proto, index - 1)
end

function jit.getconstsgc(func, const_type)
    local proto = jit.getproto(func)
    if not proto then return {} end

    local gc_consts = {}
    local n = 0

    for i = 1, proto:constcountgc() do
        local const, t = get_gc_const(proto, i - 1, const_type)

        if const then
            n = n + 1
            gc_consts[n] = const
        end
    end

    return gc_consts
end

function jit.protoinfo(proto)
    if isfunction(proto) then
        return jit.util.funcinfo(proto)
    end

    return proto:info()
end

jit.BCDUMP = BCDUMP

return jit