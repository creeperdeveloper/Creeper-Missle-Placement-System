local function isCommandComputer()
    return type(commands) == "table"
        and type(commands.exec) == "function"
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

local function getComputerPosition()
    if type(commands.getBlockPosition) ~= "function" then
        return nil
    end

    local x, y, z = commands.getBlockPosition()

    if type(x) ~= "number"
        or type(y) ~= "number"
        or type(z) ~= "number" then
        return nil
    end

    return x, y, z
end

local function getComputerFacing()
    if type(commands.getBlockPosition) ~= "function"
        or type(commands.getBlockInfo) ~= "function" then
        return nil
    end

    local x, y, z = commands.getBlockPosition()

    local ok, info = pcall(function()
        return commands.getBlockInfo(x, y, z)
    end)

    if not ok or type(info) ~= "table" then
        return nil
    end

    if type(info.state) ~= "table" then
        return nil
    end

    if type(info.state.facing) == "string" then
        return info.state.facing
    end

    return nil
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

    local x, y, z = getComputerPosition()

    if not x then
        return
    end

    local targetY = y - 1
    local facing = getComputerFacing()

    local command

    if facing then
        command =
            "setblock "
            .. x
            .. " "
            .. targetY
            .. " "
            .. z
            .. " "
            .. block
            .. "[facing="
            .. facing
            .. "] replace"
    else
        command =
            "setblock "
            .. x
            .. " "
            .. targetY
            .. " "
            .. z
            .. " "
            .. block
            .. " replace"
    end

    local ok = pcall(function()
        commands.exec(command)
    end)

    if not ok then
        pcall(function()
            commands.exec(
                "setblock "
                .. x
                .. " "
                .. targetY
                .. " "
                .. z
                .. " "
                .. block
                .. " replace"
            )
        end)
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
