local jit = moon.extend(jit)

-- Pseudo Proto Class
local Proto = moon.class('Proto') ---@class Proto

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

    for i = 1, gc_const_count do
        local t = reader:uleb() -- constant type
        local const

        if t == 1 then
            const = reader:table()
        elseif t >= 5 then
            const = reader:string(t)
        end

        if const then
            gc_const_n = gc_const_n + 1
            gc_consts[gc_const_n] = const
        end
    end

    self._gc_const_count = gc_const_n
    self._gc_consts = gc_consts
end

local BytecodeReader = include('sh_bytecode_reader.lua') ---@class BytecodeReader

---@param func function
---@return BytecodeReader?
function jit.dump(func)
    local ok, dump = pcall(string.dump, func)
    if not ok then return end

    return BytecodeReader(dump)
end

local proto_cache = {}

setmetatable(proto_cache, {
    __mode = 'k',
    __index = function(self, func)
        local reader = jit.dump(func)
        moon.assert(reader, 'unable to dump given function', 3)

        local proto = Proto(reader)
        self[func] = proto

        return proto
    end
})

-- TODO: Allow these functions to return pseudo protos

---Returns the garbage-collected constant in the function at the given index.
---@param func function
---@param index int
function jit.getgckonst(func, index)
    local proto = proto_cache[func]
    if not proto then return end

    index = index - 1

    return proto._gc_consts[proto._gc_const_count - index]
end

---Returns all garbage-collected constants in the function.
---@param func function
---@return table<int, string|table>
function jit.getgckonsts(func)
    local gc_consts = {}
    local proto = proto_cache[func]

    if proto then
        local count = proto._gc_const_count

        for i = count, 1, -1 do
            gc_consts[count - (i - 1)] = proto._gc_consts[i]
        end
    end

    return gc_consts
end

return jit