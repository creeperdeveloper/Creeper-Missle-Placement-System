if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local width, height = term.getSize()
    local message = "SYSTEM LOCKED"

    term.setCursorPos(
        math.floor((width - #message) / 2) + 1,
        math.floor(height / 2)
    )

    term.write(message)

    while true do
        os.pullEventRaw()
    end
end

local config = dofile("/config.lua")

local sides = {
    "left",
    "right",
    "front",
    "back",
    "top",
    "bottom"
}

while true do
    for _, side in ipairs(sides) do
        local signal = redstone.getInput(side)

        if signal then
            local block = config[side]

            if type(block) == "string"
                and block ~= ""
                and block ~= "minecraft:air" then

                commands.setblock(
                    "~",
                    "~-1",
                    "~",
                    block
                )

                while redstone.getInput(side) do
                    sleep(0.05)
                end
            end
        end
    end

    sleep(0.05)
end
