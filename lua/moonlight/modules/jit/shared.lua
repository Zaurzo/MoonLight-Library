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
        end

        if const then
            gc_const_n = gc_const_n + 1
            gc_consts[gc_const_n] = const
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

-- TODO: Allow these functions to return pseudo protos

local function get_gc_const(proto, index)
    return proto._gc_consts[proto._gc_const_n - index]
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
---@return table<int, string|table>
function jit.getconstsgc(func)
    local gc_consts = {}
    local proto = proto_cache[func]

    if proto then
        for i = 1, proto._gc_const_n do
            gc_consts[i] = get_gc_const(proto, i - 1)
        end
    end

    return gc_consts
end

return jit