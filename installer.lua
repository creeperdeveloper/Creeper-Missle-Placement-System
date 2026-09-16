local U="https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/"
local F={{"startup.lua","/startup.lua"},{"block_controller.lua","/block_controller.lua"},{"config.lua","/config.lua"},{"version.txt","/block_controller.version"}}
local function g(n,p)
 local h,e=http.get(U..n)
 if not h then return false end
 local d=h.readAll()
 h.close()
 local f=fs.open(p,"w")
 if not f then return false end
 f.write(d)
 f.close()
 return true
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
print("CREEPER MISSILE PLACEMENT SYSTEM")
print("INSTALLING...")
for _,v in ipairs(F) do
 if v[1]=="config.lua" and fs.exists("/config.lua") then
  print("KEEPING CONFIG")
 else
  if not g(v[1],v[2]) then
   print("INSTALL FAILED: "..v[1])
   return
  end
 end
end
fs.delete("/installer.lua")
print("INSTALL COMPLETE")
sleep(1)
os.reboot()
