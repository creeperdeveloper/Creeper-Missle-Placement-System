if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local w, h = term.getSize()

    local text = "SYSTEM LOCKED"

    term.setCursorPos(
        math.floor((w - #text) / 2) + 1,
        math.floor(h / 2)
    )

    term.write(text)

    return
end
