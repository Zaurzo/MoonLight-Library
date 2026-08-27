---@class BytecodeReader
local BytecodeReader = moon.class('BytecodeReader')

-- Some code was adapted from notcake's GLib library
-- That man is much smarter than me, haha. - Zaurzo

---@enum BCDUMP_KTAB Type codes for the keys/values of a constant table.
---https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_bcdump.h#L59
local BCDUMP_KTAB = {
    Nil = 0,
    False = 1,
    True = 2,
    Integer = 3,
    Number = 4,
    String = 5
}

function BytecodeReader:init(dump)
    moon.assertarg(dump, 1, 'string')

    self.pos = 1
    self.dump = dump

    self:skip(5) -- skip header, version, and flags
    self:skip(self:uleb()) -- skip chunk name
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

function BytecodeReader:byte(amount)
    amount = amount or 1

    local pos = self.pos
    local end_pos = pos + amount

    self.pos = end_pos

    return self.dump:byte(pos, end_pos - 1)
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

local deserializer = {
    [BCDUMP_KTAB.Nil] = nil,
    [BCDUMP_KTAB.False] = false,
    [BCDUMP_KTAB.True] = true,
    [BCDUMP_KTAB.Integer] = BytecodeReader.byte,
    [BCDUMP_KTAB.Number] = BytecodeReader.double,
    [BCDUMP_KTAB.String] = BytecodeReader.string
}

---@param reader BytecodeReader
local function deserialize_element(reader)
    local t = reader:uleb()

    if t > 2 then
        return deserializer[t] (reader, t)
    end

    return deserializer[t]
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

function BytecodeReader:char(amount)
    return string.char(self:byte(amount))
end

function BytecodeReader:string(len)
    return self:char(len - 5)
end

function BytecodeReader:skip(amount)
    self.pos = self.pos + amount
end

return BytecodeReader