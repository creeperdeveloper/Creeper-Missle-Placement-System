term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)

if not fs.exists("/block_controller.lua") then
    print("CONTROLLER NOT FOUND")
    return
end

local e=setmetatable({},{
    __index=_ENV
})

local ok,err=os.run(e,"/block_controller.lua")

if not ok then
    print("CONTROLLER ERROR")
    print(tostring(err))
end
