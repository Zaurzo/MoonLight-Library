local jit = moon.extend(jit)

--[[ Bytecode and Protos ]]

local Proto = moon.class('Proto') ---@class Proto A pseudo proto class.
local BytecodeReader = include('sh_bytecode_reader.lua') ---@class BytecodeReader

---@enum BCDUMP_KGC Type codes for the GC constants of a prototype. Plus length for strings.
---https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_bcdump.h#L53
local BCDUMP_KGC = {
    Child = 0,
    Table = 1,
    I64 = 2, -- unused in gmod
    U64 = 3, -- unused in gmod
    Complex = 4, -- unused in gmod
    String = 5
}

---@param reader BytecodeReader
function Proto:init(reader)
    reader:uleb() -- proto len
    reader:byte() -- flags
    reader:byte() -- argument/parameter count
    reader:byte() -- frame size
    
    local upvalue_count = reader:byte()
    local gc_const_count = reader:uleb()

    reader:uleb() -- numerical constant count
    
    local instruction_count = reader:uleb() 

    reader:uleb() -- debug data length
    reader:uleb() -- function definition start line
    reader:uleb() -- function definition line count

    reader:skip(instruction_count * 4)
    reader:skip(upvalue_count * 2)

    local gc_consts = {}
    local gc_const_n = 0

    for _ = 1, gc_const_count do
        local t = reader:uleb() -- constant type
        local const

        if t == BCDUMP_KGC.Child then
            -- TODO: Handle child functions/protos
        elseif t == BCDUMP_KGC.Table then
            const = reader:table()
        elseif t >= BCDUMP_KGC.String then
            const = reader:string(t)
            t = 5
        end

        if const then
            gc_const_n = gc_const_n + 1

            gc_consts[gc_const_n] = const
            gc_consts[-gc_const_n] = t -- optimization: put the type in the negative index
        end
    end

    self._gc_const_n = gc_const_n
    self._gc_consts = gc_consts
end

---@param func function
---@return BytecodeReader?
function jit.dumpbc(func)
    local ok, dump = pcall(string.dump, func)
    if not ok then return end

    return BytecodeReader(dump)
end

local proto_cache = {}

setmetatable(proto_cache, {
    __mode = 'k',
    __index = function(self, func)
        local reader = jit.dumpbc(func)
        moon.assert(reader, 'unable to dump given function', 3)

        local proto = Proto(reader)
        self[func] = proto

        return proto
    end
})

-- [[ Partially re-implement jit.util.funck ]]
-- 
-- These functions are inferior and return pseudos of some constants, such as tables.
-- This is no problem though, as I only use it for analyzation.
-- 
-- TODO: Allow these functions to return pseudo protos

---@param proto Proto
---@param index int
local function get_gc_const(proto, index)
    index = proto._gc_const_n - index

    local const, t = proto._gc_consts[index], proto._gc_consts[-index]

    if t == BCDUMP_KGC.Table then
        local copy = {}

        for k, v in pairs(const --[[@as table]]) do
            copy[k] = v
        end

        const = copy
    end

    return const, t
end

---Returns the garbage-collected constant in the function at the given index.
---@param func function
---@param index int
function jit.getconstgc(func, index)
    local proto = proto_cache[func]
    if not proto then return end

    return get_gc_const(proto, index - 1)
end

---Returns all garbage-collected constants in the function.
---@param func function
---@param const_type? BCDUMP_KGC
---@return table<int, string|table>
function jit.getconstsgc(func, const_type)
    local proto = proto_cache[func]
    if not proto then return {} end

    local gc_consts = {}
    local n = 0

    for i = 1, proto._gc_const_n do
        local const, t = get_gc_const(proto, i - 1)

        if not const_type or t == const_type then
            n = n + 1
            gc_consts[n] = const
        end
    end

    return gc_consts
end

jit.BCDUMP_KGC = BCDUMP_KGC

return jit