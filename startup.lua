term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

local function line(y, text)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end

line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
line(2, "STARTUP: RUNNING")

if type(commands) ~= "table" then
    line(4, "COMMANDS: NOT FOUND")
    line(5, "SYSTEM LOCKED")

    while true do
        os.pullEventRaw()
    end
end

if type(commands.setblock) ~= "function" then
    line(4, "SETBLOCK: NOT FOUND")
    line(5, "SYSTEM LOCKED")

    while true do
        os.pullEventRaw()
    end
end

line(4, "COMMANDS: OK")
line(5, "SETBLOCK: OK")

if not fs.exists("/config.lua") then
    line(7, "CONFIG: NOT FOUND")

    while true do
        os.pullEventRaw()
    end
end

local success, config = pcall(dofile, "/config.lua")

if not success then
    line(7, "CONFIG: ERROR")
    line(8, tostring(config))

    while true do
        os.pullEventRaw()
    end
end

line(7, "CONFIG: OK")
line(9, "REDSTONE: WAITING")

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
        local signal = redstone.getAnalogInput(side)

        if signal > 0 then
            local block = config[side]

            line(9, "REDSTONE: " .. side)
            line(10, "SIGNAL: " .. tostring(signal))
            line(11, "BLOCK: " .. tostring(block))

            if type(block) ~= "string" or block == "" then
                line(12, "PLACEMENT: INVALID BLOCK")
            elseif block == "minecraft:air" then
                line(12, "PLACEMENT: AIR")
            else
                local ok, result = pcall(
                    commands.setblock,
                    "~",
                    "~-1",
                    "~",
                    block
                )

                if ok then
                    line(12, "PLACEMENT: SUCCESS")
                else
                    line(12, "PLACEMENT: FAILED")
                    line(13, tostring(result))
                end
            end

            while redstone.getAnalogInput(side) > 0 do
                sleep(0.05)
            end

            line(9, "REDSTONE: WAITING")
            line(10, "")
            line(11, "")
            line(12, "")
            line(13, "")
        end
    end

    sleep(0.05)
end
