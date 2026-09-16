local a,b,c,d,e,f,g,h="","/block_controller.lua","/block_controller.version","https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/version.txt",false,nil,nil,nil
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
if not fs.exists(b) then print("SYSTEM ERROR") return end
if http then
 local x=fs.open(c,"r")
 if x then
  a=x.readAll():gsub("%s+","")
  x.close()
 end
 local y,z=pcall(http.get,d)
 if y and z then
  local q=z.readAll():gsub("%s+","")
  z.close()
  if q~="" and q~=a then
   local u="https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/"
   local t={{"startup.lua","/startup.lua"},{"block_controller.lua","/block_controller.lua"},{"version.txt",c}}
   for _,v in ipairs(t) do
    local r,s=pcall(http.get,u..v[1])
    if r and s then
     local w=fs.open(v[2],"w")
     if w then w.write(s.readAll()) w.close() end
     s.close()
    end
   end
   os.reboot()
   return
  end
 end
end
local i=setmetatable({},{__index=_ENV})
local j,k=os.run(i,b)
if not j then
 term.setBackgroundColor(colors.black)
 term.setTextColor(colors.white)
 term.clear()
 term.setCursorPos(1,1)
 print("SYSTEM ERROR")
 print(tostring(k))
end
