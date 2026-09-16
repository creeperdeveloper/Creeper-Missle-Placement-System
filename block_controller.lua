local function isCommandComputer()
    return type(commands) == "table"
        and type(commands.exec) == "function"
        and type(commands.getBlockPosition) == "function"
        and type(commands.getBlockInfo) == "function"
end

local function lockScreen()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)

    local width, height = term.getSize()
    local message = "SYSTEM LOCKED"

    local x = math.floor((width - #message) / 2) + 1
    local y = math.floor(height / 2)

    term.setCursorPos(x, y)
    term.write(message)

    while true do
        os.pullEventRaw()
    end
end

if not isCommandComputer() then
    lockScreen()
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

local previous = {}

for _, side in ipairs(sides) do
    previous[side] = redstone.getInput(side)
end

local function getComputerFacing()
    local x, y, z = commands.getBlockPosition()
    local info = commands.getBlockInfo(x, y, z)

    if not info or not info.state then
        return nil
    end

    return info.state.facing
end

local function placeBlock(side)
    local block = config[side]

    if type(block) ~= "string" then
        return
    end

    if block == "" or block == "minecraft:air" then
        return
    end

    if not isCommandComputer() then
        return
    end

    local facing = getComputerFacing()

    if facing then
        commands.exec(
            "setblock ~ ~-1 ~ " .. block .. "[facing=" .. facing .. "] replace"
        )
    else
        commands.exec(
            "setblock ~ ~-1 ~ " .. block .. " replace"
        )
    end
end

while true do
    for _, side in ipairs(sides) do
        local current = redstone.getInput(side)

        if current and not previous[side] then
            placeBlock(side)
        end

        previous[side] = current
    end

    sleep(0.05)
end
