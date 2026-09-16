local function lockScreen()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)

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

local function showError(title, message)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local width, height = term.getSize()

    term.setCursorPos(
        math.max(1, math.floor((width - #title) / 2) + 1),
        math.floor(height / 2) - 3
    )

    term.write(title)

    local lines = {}

    for line in tostring(message):gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end

    for i, line in ipairs(lines) do
        local y = math.floor(height / 2) - 1 + i

        if y > height then
            break
        end

        term.setCursorPos(
            math.max(1, math.floor((width - #line) / 2) + 1),
            y
        )

        term.write(line)
    end

    term.setCursorPos(1, height)
    term.write("Press any key to restart.")

    os.pullEvent("key")
    os.reboot()
end

if type(commands) ~= "table"
    or type(commands.exec) ~= "function" then
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

local function executeSetblock(block)
    local command =
        "setblock ~ ~-1 ~ "
        .. block
        .. " replace"

    local ok, output, affected = commands.exec(command)

    return ok, output, affected, command
end

local function placeBlock(side)
    local block = config[side]

    if type(block) ~= "string"
        or block == ""
        or block == "minecraft:air" then
        return true
    end

    local ok, output, affected, command =
        executeSetblock(block)

    if ok then
        return true
    end

    local message = {
        "SIDE: " .. side,
        "BLOCK: " .. block,
        "COMMAND:",
        command,
        "",
        "COMMAND FAILED"
    }

    if type(affected) == "number" then
        message[#message + 1] =
            "AFFECTED: " .. tostring(affected)
    end

    if type(output) == "table" then
        for _, line in ipairs(output) do
            message[#message + 1] = tostring(line)
        end
    elseif output ~= nil then
        message[#message + 1] = tostring(output)
    end

    showError(
        "BLOCK CONTROLLER ERROR",
        table.concat(message, "\n")
    )

    return false
end

local previous = {}

for _, side in ipairs(sides) do
    previous[side] = redstone.getInput(side)
end

for _, side in ipairs(sides) do
    if previous[side] then
        placeBlock(side)
    end
end

while true do
    os.pullEvent("redstone")

    for _, side in ipairs(sides) do
        local current = redstone.getInput(side)

        if current and not previous[side] then
            placeBlock(side)
        end

        previous[side] = current
    end
end
