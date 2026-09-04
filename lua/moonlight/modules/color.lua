local color = {
    white = Color(255, 255, 255),
    black = Color(0, 0, 0, 255),
    clear = Color(0, 0, 0, 0),
    red = Color(255, 0, 0),
    orange = Color(255, 127, 0),
    yellow = Color(255, 255, 0),
    green = Color(0, 255, 0),
    blue = Color(0, 0, 255),
    purple = Color(127, 0, 255),
    pink = Color(255, 0, 255),
    cyan = Color(0, 255, 255)
}

function color.Rainbow(speed)
    speed = speed or 1.0

    local hue = (SysTime() * speed) % 360

    return HSVToColor(hue, 1, 1)
end

return color