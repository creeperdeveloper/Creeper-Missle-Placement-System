while true do
    if redstone.getAnalogInput("left") > 0 then
        commands.setblock("~", "~-1", "~", "minecraft:stone")

        while redstone.getAnalogInput("left") > 0 do
            sleep(0.05)
        end
    end

    sleep(0.05)
end
