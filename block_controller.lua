local config = dofile("/config.lua")

local sides = {
    "left",
    "right",
    "front",
    "back",
    "top",
    "bottom"
}

term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

local function line(y, text)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end

line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
line(2, "BLOCK CONTROLLER")
line(4, "STATUS: RUNNING")
line(5, "REDSTONE: WAITING")

while true do
    for _, side in ipairs(sides) do
        local signal = redstone.getAnalogInput(side)

        if signal > 0 then
            local block = config[side]

            line(5, "REDSTONE: " .. side)
            line(6, "SIGNAL: " .. tostring(signal))
            line(7, "BLOCK: " .. tostring(block))

            if type(block) == "string"
                and block ~= ""
                and block ~= "minecraft:air" then

                local success, result = pcall(
                    commands.setblock,
                    "~",
                    "~-1",
                    "~",
                    block
                )

                if success then
                    line(8, "PLACEMENT: SUCCESS")
                else
                    line(8, "PLACEMENT: FAILED")
                    line(9, tostring(result))
                end

                while redstone.getAnalogInput(side) > 0 do
                    sleep(0.05)
                end
            else
                line(8, "PLACEMENT: INVALID BLOCK")

                while redstone.getAnalogInput(side) > 0 do
                    sleep(0.05)
                end
            end

            line(5, "REDSTONE: WAITING")
            line(6, "")
            line(7, "")
            line(8, "")
            line(9, "")
        end
    end

    sleep(0.05)
end
