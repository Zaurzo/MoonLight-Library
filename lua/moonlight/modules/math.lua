local math = moon.extend(math)

-- Recreate Lua 5.3 math.type
function math.type(num)
    return num == math.floor(num) and 'integer' or 'float'
end

return math