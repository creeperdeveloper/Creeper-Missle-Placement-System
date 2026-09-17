local a="/block_controller.lua"
local b="/block_controller.version"

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)

if not fs.exists(a) then
 print("SYSTEM ERROR")
 print("CONTROLLER NOT FOUND")
 while true do os.pullEventRaw() end
end

local e=setmetatable({},{__index=_ENV})
local o,r=os.run(e,a)

if not o then
 term.setBackgroundColor(colors.black)
 term.setTextColor(colors.white)
 term.clear()
 term.setCursorPos(1,1)
 print("SYSTEM ERROR")
 print("")
 if r~=nil then
  print(tostring(r))
 else
  print("CONTROLLER FAILED")
 end
 while true do os.pullEventRaw() end
end
