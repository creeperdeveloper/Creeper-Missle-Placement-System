if commands == nil then
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)

    local width, height = term.getSize()

    local message = "SYSTEM LOCKED"
    local x = math.floor((width - #message) / 2) + 1

    term.setCursorPos(
        x,
        math.floor(height / 2)
    )

    term.write(message)

    while true do
        os.pullEventRaw()
    end
end

local config =
    dofile("/config.lua")

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
    previous[side] =
        redstone.getInput(side)
end

local function placeBlock(block)
    if not block
        or block == ""
        or block == "minecraft:air"
    then
        return
    end

    if commands == nil then
        return
    end

    commands.exec(
        "setblock ~ ~-1 ~ "
        .. block
        .. " replace"
    )
end

while true do
    for _, side in ipairs(sides) do
        local current =
            redstone.getInput(side)

        if current
            and not previous[side]
        then
            placeBlock(
                config[side]
            )
        end

        previous[side] =
            current
    end

    sleep(0.05)
end
