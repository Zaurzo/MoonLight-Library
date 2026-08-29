-- Some code was adapted from notcake's GLib library
-- That man is much smarter than me, haha. - Zaurzo

--[[ Bytecode Reader ]]

local BytecodeReader = moon.class('BytecodeReader')
local BCDUMP = moon.import.include('sh_bcdump_enum.lua')
local Proto = moon.import.include('sh_proto.lua')

function BytecodeReader:init(dump)
    moon.assertarg(dump, 1, 'string')

    self._pos = 1
    self._dump = dump

    self:skip(3) -- skip header
    self:skip(1) -- skip version

    self._flags = self:byte()
    self._source = self:char(self:uleb())

    local protos = {}
    local proto_n = 0
    local proto_length = self:uleb()

    while proto_length ~= 0 do
        local proto_end = proto_length + self._pos
        
        proto_n = proto_n + 1
        protos[proto_n] = Proto:new(self)

        self._pos = proto_end

        proto_length = self:uleb()
    end

    self._proto_n = proto_n
    self._protos = protos

    self:_link_protos(proto_n - 1, protos[proto_n])
end

-- internal
function BytecodeReader:_link_protos(child_index, proto)
    for i = 1, proto:constcountgc() do
        local const, t = proto:getconstgc(i)
        if t ~= BCDUMP.KGC.Child then continue end

        local child_proto = self._protos[child_index]
        proto._gc_consts[i] = child_proto

        child_index = child_index - 1

        if child_proto then
            self:_link_protos(child_index, child_proto)
        end
    end
end

-- Accessors

function BytecodeReader:flags()
    return self._flags
end

function BytecodeReader:source()
    return self._source
end

function BytecodeReader:getproto(index)
    index = index - 1

    return self._protos[self._proto_n - index]
end

function BytecodeReader:protocount()
    return self._proto_n
end

-- Reading / parsing

function BytecodeReader:char(amount)
    return string.char(self:byte(amount))
end

function BytecodeReader:string(len)
    return self:char(len - 5)
end

function BytecodeReader:skip(amount)
    self._pos = self._pos + amount
end

function BytecodeReader:byte(amount)
    amount = amount or 1

    local pos = self._pos
    local end_pos = pos + amount

    self._pos = end_pos

    return string.byte(self._dump, pos, end_pos - 1)
end

-- credits: https://github.com/notcake/glib/blob/master/lua/glib/io/inbuffer.lua#L61-L79
function BytecodeReader:uleb()
	local n, factor = 0, 1
	local done = false

	while not done do
		local byte = self:byte()

		if byte >= 0x80 then
			byte = byte - 0x80
		else
			done = true
		end
		
		n = n + byte * factor
		factor = factor * 128
	end
	
	return n
end

-- credits: https://github.com/notcake/glib/blob/master/lua/glib/bitconverter.lua#L215-L240
function BytecodeReader:double()
    local low, high = self:uleb(), self:uleb()
	local negative = false
	
	if high >= 0x80000000 then
		negative = true
		high = high - 0x80000000
	end
	
	local biasedExponent = bit.rshift(bit.band(high, 0x7FF00000), 20)
	local mantissa = (bit.band(high, 0x000FFFFF) * 4294967296 + low) / 2 ^ 52
	local f

	if biasedExponent == 0x0000 then
		f = mantissa == 0 and 0 or math.ldexp(mantissa, -1022)
	elseif biasedExponent == 0x07FF then
		f = mantissa == 0 and math.huge or (math.huge - math.huge)
	else
		f = math.ldexp(1 + mantissa, biasedExponent - 1023)
	end
	
	return negative and -f or f
end

local deserialize = {
    [BCDUMP.KTAB.Nil] = nil,
    [BCDUMP.KTAB.False] = false,
    [BCDUMP.KTAB.True] = true,
    [BCDUMP.KTAB.Integer] = BytecodeReader.uleb,
    [BCDUMP.KTAB.Number] = BytecodeReader.double
}

---@param reader BytecodeReader
local function deserialize_element(reader)
    local t = reader:uleb()

    if t >= BCDUMP.KTAB.String then
        return reader:string(t)
    end

    if t > BCDUMP.KTAB.True then
        return deserialize[t] (reader)
    end

    return deserialize[t]
end

---@return table
function BytecodeReader:table()
    local ktab = {}

    local array_count = self:uleb()
    local hash_count = self:uleb()

    for i = 0, array_count - 1 do
        ktab[i] = deserialize_element(self)
    end

    for _ = 1, hash_count do
        local key = deserialize_element(self)
        local value = deserialize_element(self)

        ktab[key] = value
    end

    return ktab
end

return BytecodeReader