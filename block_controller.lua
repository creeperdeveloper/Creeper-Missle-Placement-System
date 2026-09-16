if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local w, h = term.getSize()
    local text = "SYSTEM LOCKED"

    term.setCursorPos(
        math.floor((w - #text) / 2) + 1,
        math.floor(h / 2)
    )

    term.write(text)

    while true do
        os.pullEventRaw()
    end
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

local function placeBlock(side)
    local block = config[side]

    if type(block) ~= "string" then
        return
    end

    if block == "" or block == "minecraft:air" then
        return
    end

    commands.setblock(
        "~",
        "~-1",
        "~",
        block
    )
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
