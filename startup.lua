local a="/block_controller.lua"
local b="/block_controller.version"
local c="https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/version.txt"
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
if not fs.exists(a) then
 print("SYSTEM ERROR")
 print("CONTROLLER NOT FOUND")
 return
end
local d=""
if fs.exists(b) then
 local f=fs.open(b,"r")
 if f then
  d=f.readAll():gsub("%s+","")
  f.close()
 end
end
if http then
 local ok,h=pcall(http.get,c)
 if ok and h then
  local v=h.readAll():gsub("%s+","")
  h.close()
  if v~="" and v~=d then
   local u="https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/"
   local q={{"startup.lua","/startup.lua"},{"block_controller.lua","/block_controller.lua"},{"version.txt",b}}
   for _,x in ipairs(q) do
    local ok2,r=pcall(http.get,u..x[1])
    if ok2 and r then
     local f=fs.open(x[2],"w")
     if f then
      f.write(r.readAll())
      f.close()
     end
     r.close()
    end
   end
   os.reboot()
   return
  end
 end
end
local e=setmetatable({},{__index=_ENV})
local ok,err=os.run(e,a)
if not ok then
 term.setBackgroundColor(colors.black)
 term.setTextColor(colors.white)
 term.clear()
 term.setCursorPos(1,1)
 print("SYSTEM ERROR")
 print(tostring(err))
end
