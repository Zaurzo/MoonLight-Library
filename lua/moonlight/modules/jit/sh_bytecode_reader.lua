---@class BytecodeReader
local BytecodeReader = moon.class('BytecodeReader')

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

---@param reader BytecodeReader
local function deserialize_element(reader)
    local t = reader:uleb()

    if t == 0 then
        return nil
    end

    if t == 1 then
        return false
    end

    if t == 2 then
        return true
    end

    if t == 3 then -- integer
        return reader:uleb()
    end

    if t == 4 then
        return reader:double()
    end

    if t >= 5 then
        return reader:string(t)
    end
end

---@return table
function BytecodeReader:table()
    local ktab = {}

    local array_count = self:uleb()
    local hash_count = self:uleb()

    for i = 0, array_count - 1 do
        ktab[i] = deserialize_element(self)
    end

    for i = 1, hash_count do
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