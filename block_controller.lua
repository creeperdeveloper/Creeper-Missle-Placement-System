local config = dofile("/config.lua")

local sides = {
    "left",
    "right",
    "front",
    "back",
    "top",
    "bottom"
}

while true do
    for _, side in ipairs(sides) do
        if redstone.getAnalogInput(side) > 0 then
            local block = config[side]

            if type(block) == "string"
                and block ~= ""
                and block ~= "minecraft:air" then

                commands.setblock(
                    "~",
                    "~-1",
                    "~",
                    block
                )

                while redstone.getAnalogInput(side) > 0 do
                    sleep(0.05)
                end
            end
        end
    end

    sleep(0.05)
end
