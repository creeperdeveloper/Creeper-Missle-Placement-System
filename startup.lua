local controller = "/block_controller.lua"

while true do
    if not fs.exists(controller) then
        term.clear()
        term.setCursorPos(1, 1)

        print("BLOCK CONTROLLER")
        print("----------------")
        print()
        print("SYSTEM ERROR")
        print("Controller is missing.")
        print()
        print("System locked.")

        while true do
            os.pullEventRaw()
        end
    end

    local ok, err = pcall(function()
        shell.run(controller)
    end)

    if not ok then
        term.clear()
        term.setCursorPos(1, 1)

        print("BLOCK CONTROLLER")
        print("----------------")
        print()
        print("CONTROLLER ERROR")
        print()
        print(tostring(err))
        print()
        print("Restarting controller...")

        sleep(2)
    end
end
