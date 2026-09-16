```lua
local u="https://raw.githubusercontent.com/creeperdeveloper/Creeper-Missle-Placement-System/main/"
local f={
 {"startup.lua","/startup.lua",true},
 {"block_controller.lua","/block_controller.lua",true},
 {"config.lua","/config.lua",false},
 {"version.txt","/block_controller.version",true}
}

term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

local w,h=term.getSize()

local function center(y,s)
 term.setCursorPos(math.max(1,math.floor((w-#s)/2)+1),y)
 write(s)
end

local function header()
 center(3,"Creeper Missle Placement System / Installer")
end

local function progress(p)
 local bw=math.min(w-10,40)
 local x=math.floor((w-bw)/2)
 local y=math.floor(h/2)+1
 local n=math.floor(bw*p)

 term.setCursorPos(x,y)
 write("[")
 write(string.rep("#",n))
 write(string.rep(" ",bw-n))
 write("]")

 local s=tostring(math.floor(p*100)).."%"
 term.setCursorPos(math.floor((w-#s)/2)+1,y+2)
 write(s)
end

local function installing(name,p)
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 header()

 local y=math.floor(h/2)-2
 center(y,name)
 progress(p)
end

local function errorScreen(s)
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 header()
 center(math.floor(h/2),"Installation failed")
 center(math.floor(h/2)+2,s)
end

header()
sleep(.5)

if not http then
 errorScreen("HTTP API is disabled.")
 return
end

for i,v in ipairs(f) do
 local name=v[1]
 local path=v[2]
 local overwrite=v[3]
 local p=(i-1)/#f

 if not overwrite and fs.exists(path) then
  installing(name,p)
  sleep(.4)
 else
  installing(name,p)
  
  local ok,r=pcall(http.get,u..name)
  
  if not ok or not r then
   errorScreen("Failed to download "..name)
   return
  end

  local data=r.readAll()
  r.close()

  installing(name,(i-.5)/#f)

  local hnd=fs.open(path,"w")
  
  if not hnd then
   errorScreen("Failed to write "..name)
   return
  end

  hnd.write(data)
  hnd.close()

  sleep(.3)
 end

 installing(name,i/#f)
 sleep(.25)
end

term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

header()

center(math.floor(h/2)-1,"INSTALLATION COMPLETE")
center(math.floor(h/2)+1,"Rebooting...")

sleep(2)
os.reboot()
```
