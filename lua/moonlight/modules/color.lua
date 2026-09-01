local color = {
    white = Color(255, 255, 255),
    black = Color(0, 0, 0, 255),
    clear = Color(0, 0, 0, 0),
    red = Color(255, 0, 0),
    green = Color(0, 255, 0),
    blue = Color(0, 0, 255)
}

function color.Rainbow(speed)
    speed = speed or 1.0

    local hue = (SysTime() * speed) % 360

    return HSVToColor(hue, 1, 1)
end

return color