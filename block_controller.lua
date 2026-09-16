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
    local width = term.getSize()

    term.setCursorPos(1, y)
    term.clearLine()

    if #text > width then
        text = text:sub(1, width)
    end

    term.write(text)
end

local function drawHeader()
    line(1, "CREEPER MISSILE PLACEMENT SYSTEM")
    line(2, "BLOCK CONTROLLER")
    line(3, "")
end

local function drawStatus()
    line(4, "STATUS: RUNNING")
    line(5, "REDSTONE: WAITING")
    line(6, "")
    line(7, "")
    line(8, "")
    line(9, "")
end

local function showReady()
    clear()
    drawHeader()
    drawStatus()
end

local function showSignal(side, signal, block)
    line(4, "STATUS: RUNNING")
    line(5, "REDSTONE: " .. side)
    line(6, "SIGNAL: " .. tostring(signal))
    line(7, "BLOCK: " .. tostring(block))
end

local function showSuccess()
    line(8, "PLACEMENT: SUCCESS")
end

local function showFailed(errorMessage)
    line(8, "PLACEMENT: FAILED")
    line(9, tostring(errorMessage))
end

local function showInvalid()
    line(8, "PLACEMENT: INVALID BLOCK")
end

local function placeBlock(side)
    local block = config[side]
    local signal = redstone.getAnalogInput(side)

    showSignal(side, signal, block)

    if type(block) ~= "string" or block == "" then
        showInvalid()
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
        showSuccess()
    else
        showFailed(result)
    end
end

local function stopController()
    clear()

    drawHeader()
    line(4, "STATUS: STOPPED")
    line(5, "CONTROLLER TERMINATED")
    line(7, "Returning to CraftOS...")

    sleep(1)
end

showReady()

while true do
    local event = { os.pullEventRaw() }

    if event[1] == "terminate" then
        stopController()
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
                        stopController()
                        return
                    end
                end

                showReady()
            end
        end
    end
end
