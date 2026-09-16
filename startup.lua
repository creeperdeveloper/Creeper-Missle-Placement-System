term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("CREEPER MISSILE PLACEMENT SYSTEM")
print("")
print("Starting controller...")
print("")

if not fs.exists("/block_controller.lua") then
    print("ERROR: block_controller.lua not found")
    return
end

local environment = setmetatable({}, {
    __index = _ENV
})

local success, errorMessage = os.run(
    environment,
    "/block_controller.lua"
)

if not success then
    print("")
    print("CONTROLLER STOPPED")
    print("")
    print(tostring(errorMessage))
end
