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

local function errorScreen(message)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1, 1)

    local width, height = term.getSize()

    local title = "SYSTEM ERROR"

    local x1 = math.floor((width - #title) / 2) + 1
    local x2 = math.floor((width - #message) / 2) + 1

    term.setCursorPos(x1, math.floor(height / 2) - 1)
    term.write(title)

    term.setCursorPos(x2, math.floor(height / 2) + 1)
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

    local command =
        "setblock ~ ~-1 ~ "
        .. block
        .. " replace"

    local ok, output = pcall(function()
        return commands.exec(command)
    end)

    if not ok then
        errorScreen(tostring(output))
        return
    end

    if output == false then
        local success, lines = commands.exec(command)

        if not success then
            local message = "SETBLOCK FAILED"

            if type(lines) == "table" and #lines > 0 then
                message = tostring(lines[1])
            end

            errorScreen(message)
        end
    end
end

for _, side in ipairs(sides) do
    if redstone.getInput(side) then
        placeBlock(side)
    end
end

while true do
    local event = { os.pullEvent() }

    if event[1] == "redstone" then
        for _, side in ipairs(sides) do
            if redstone.getInput(side) then
                placeBlock(side)
            end
        end
    end
end
