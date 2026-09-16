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

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    print("BLOCK CONTROLLER")
    print("----------------")
    print("SYSTEM: LOCKED")
    print("STATUS: RUNNING")
    print()

    for _, side in ipairs(sides) do
        local state = redstone.getInput(side)
        local block = config[side] or "minecraft:air"

        if state then
            print(string.upper(side) .. ": ON")
            print("  -> " .. block)
        else
            print(string.upper(side) .. ": OFF")
        end
    end
end

local function place(block)
    if not block
        or block == ""
        or block == "minecraft:air"
    then
        return
    end

    local ok, result = commands.exec(
        "setblock ~ ~-1 ~ " ..
        block ..
        " replace"
    )

    if not ok then
        term.clear()
        term.setCursorPos(1, 1)

        print("SETBLOCK ERROR")
        print()
        print(tostring(result))

        sleep(2)
    end
end

local function processRedstone()
    for _, side in ipairs(sides) do
        local current =
            redstone.getInput(side)

        if current and not previous[side] then
            place(config[side])
        end

        previous[side] = current
    end
end

while true do
    processRedstone()
    draw()

    sleep(0.05)
end
