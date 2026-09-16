if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local width, height = term.getSize()
    local text = "SYSTEM LOCKED"

    term.setCursorPos(
        math.floor((width - #text) / 2) + 1,
        math.floor(height / 2)
    )

    term.write(text)

    while true do
        os.pullEventRaw()
    end
end

local config = dofile("/config.lua")

local sides = redstone.getSides()

local function getSignal(side)
    return redstone.getAnalogInput(side)
end

local function placeBlock(side)
    local block = config[side]

    if type(block) ~= "string" then
        return
    end

    if block == ""
        or block == "minecraft:air" then
        return
    end

    commands.setblock(
        "~",
        "~-1",
        "~",
        block
    )
end

local previous = {}

for _, side in ipairs(sides) do
    previous[side] = getSignal(side)
end

for _, side in ipairs(sides) do
    if previous[side] > 0 then
        placeBlock(side)
    end
end

while true do
    os.pullEvent("redstone")

    for _, side in ipairs(sides) do
        local signal = getSignal(side)

        if signal > 0 and previous[side] == 0 then
            placeBlock(side)
        end

        previous[side] = signal
    end
end
