local config = dofile("/config.lua")

local sides = {
    "left",
    "right",
    "front",
    "back",
    "top",
    "bottom"
}

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function line(y, text)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end

local function draw()
    clear()

    line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
    line(2, "BLOCK CONTROLLER")
    line(4, "STATUS: RUNNING")
    line(5, "REDSTONE: WAITING")
    line(6, "")
    line(7, "")
    line(8, "")
    line(9, "")
end

local function placeBlock(side)
    local block = config[side]

    line(5, "REDSTONE: " .. side)
    line(6, "SIGNAL: " .. tostring(redstone.getAnalogInput(side)))
    line(7, "BLOCK: " .. tostring(block))

    if type(block) ~= "string" or block == "" then
        line(8, "PLACEMENT: INVALID BLOCK")
        return
    end

    if block == "minecraft:air" then
        line(8, "PLACEMENT: SKIPPED")
        return
    end

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
end

draw()

while true do
    local event = { os.pullEventRaw() }

    if event[1] == "terminate" then
        clear()

        line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
        line(3, "CONTROLLER STOPPED")
        line(5, "Returning to CraftOS...")

        sleep(1)

        return
    end

    if event[1] == "redstone" then
        for _, side in ipairs(sides) do
            local signal = redstone.getAnalogInput(side)

            if signal > 0 then
                placeBlock(side)

                while redstone.getAnalogInput(side) > 0 do
                    local waitEvent = { os.pullEventRaw() }

                    if waitEvent[1] == "terminate" then
                        clear()

                        line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
                        line(3, "CONTROLLER STOPPED")
                        line(5, "Returning to CraftOS...")

                        sleep(1)

                        return
                    end
                end

                line(5, "REDSTONE: WAITING")
                line(6, "")
                line(7, "")
                line(8, "")
                line(9, "")
            end
        end
    end
end
