--[[ Psuedo Proto Class ]]

local Proto = moon.class('Proto')
local BCDUMP = moon.import.include('sh_bcdump_enum.lua')

function Proto:init(reader)
    self._flags = reader:byte() 
    self._param_count = reader:byte()
    self._frame_size = reader:byte() 
    self._upvalue_count = reader:byte()
    self._gc_const_count = reader:uleb()
    self._num_const_count = reader:uleb()
    self._instruction_count = reader:uleb() 

    reader:uleb() -- debug data length

    self._start_line = reader:uleb()
    self._line_count = reader:uleb()
    self._end_line = self._start_line + self._line_count

    reader:skip(self._instruction_count * 4)
    reader:skip(self._upvalue_count * 2)

    local children = {}
    local gc_consts = {}

    for i = 1, self._gc_const_count do
        local t = reader:uleb() -- constant type
        local const

        if t == BCDUMP.KGC.Child then
            const = 0 -- placeholder

            self._children = true
        elseif t == BCDUMP.KGC.Table then
            const = reader:table()
        elseif t >= BCDUMP.KGC.String then
            const = reader:string(t)
            t = 5
        end

        if const then
            gc_consts[i] = const
            gc_consts[-i] = t -- optimization: put the type in the negative index
        end
    end

    self._source = reader:source()
    self._loc = self._source:GetFileFromFilename() .. ':' .. self._start_line
    self._gc_consts = gc_consts
end

-- Accessors

function Proto:isvararg()
    return bit.band(self._flags, 2) ~= 0
end

function Proto:getconstgc(index)
    return self._gc_consts[index], self._gc_consts[-index]
end

function Proto:constcountgc()
    return self._gc_const_count
end

function Proto:info()
    return {
        gcconsts = self._gc_const_count,
        nconsts = self._num_const_count,
        stacksize = self._frame_size,
        loc = self._loc,
        params = self._param_count,
        bytecodes = self._instruction_count,
        children = self._children,
        currentline = self._start_line,
        source = self._source,
        lastlinedefined = self._end_line,
        linedefined = self._start_line,
        upvalues = self._upvalue_count,
        isvararg = self:isvararg(),
    }
end

return Proto