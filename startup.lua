term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

local width, height = term.getSize()

local function center(text, y)
    term.setCursorPos(
        math.floor((width - #text) / 2) + 1,
        y
    )
    term.write(text)
end

if settings.get("shell.allow_startup") == false then
    center("STARTUP DISABLED", math.floor(height / 2) - 1)
    center("shell.allow_startup = false", math.floor(height / 2) + 1)

    while true do
        os.pullEventRaw()
    end
end

if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    center("SYSTEM LOCKED", math.floor(height / 2))

    while true do
        os.pullEventRaw()
    end
end

if not fs.exists("/block_controller.lua") then
    center("CONTROLLER NOT FOUND", math.floor(height / 2))

    while true do
        os.pullEventRaw()
    end
end

center("SYSTEM STARTING", math.floor(height / 2))

sleep(1)

term.clear()
term.setCursorPos(1, 1)

shell.run("block_controller")
