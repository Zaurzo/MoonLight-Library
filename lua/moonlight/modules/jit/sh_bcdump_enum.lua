local BCDUMP = {
    --Type codes for the GC constants of a prototype. Plus length for strings.
    --https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_bcdump.h#L53
    KGC = {
        Child = 0,
        Table = 1,
        I64 = 2, -- unused in gmod
        U64 = 3, -- unused in gmod
        Complex = 4, -- unused in gmod
        String = 5
    },
    -- Type codes for the keys/values of a constant table.
    -- https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_bcdump.h#L59
    KTAB = {
         Nil = 0,
        False = 1,
        True = 2,
        Integer = 3,
        Number = 4,
        String = 5
    }
}

return BCDUMP