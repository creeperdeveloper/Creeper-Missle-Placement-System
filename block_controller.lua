local cfg=dofile("/config.lua")

local sides={"left","right","front","back","top","bottom"}
local names={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local logs={}
local previous={}

local function b64(s)
 local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 return ((s:gsub(".",function(c)
  local n=c:byte()
  local r=""
  for i=8,1,-1 do
   r=r..(n%2^i-n%2^(i-1)>0 and"1"or"0")
  end
  return r
 end).."0000"):gsub("%d%d%d?%d?%d?%d?",function(x)
  if #x<6 then return"" end
  local n=0
  for i=1,6 do
   if x:sub(i,i)=="1" then n=n+2^(6-i) end
  end
  return chars:sub(n+1,n+1)
 end)..({"","==","="}[#s%3+1])
end

local function addLog(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..s)
 while #logs>7 do
  table.remove(logs)
 end
end

local function clear()
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 term.setCursorPos(1,1)
end

local function center(y,s)
 local w=term.getSize()
 term.setCursorPos(math.max(1,math.floor((w-#s)/2)+1),y)
 write(s)
end

local function input(mask)
 local w=term.getSize()
 local text=""
 local sx,sy=term.getCursorPos()

 while true do
  local e,a=os.pullEventRaw()

  if e=="char" then
   text=text..a
   write(mask and"*"or a)

  elseif e=="paste" then
   text=text..a
   write(mask and string.rep("*",#a)or a)

  elseif e=="key" then
   if a==keys.enter then
    return text

   elseif a==keys.backspace then
    if #text>0 then
     text=text:sub(1,#text-1)
     term.setCursorPos(sx,sy)
     write(string.rep(" ",w-sx+1))
     term.setCursorPos(sx,sy)
     write(mask and string.rep("*",#text)or text)
    end
   end

  elseif e=="terminate" then
  end
 end
end

local function getFacing()
 local ok,data=pcall(commands.getBlockInfo,"~","~","~")

 if ok and data then
  if data.state and data.state.facing then
   return tostring(data.state.facing)
  end

  if data.properties and data.properties.facing then
   return tostring(data.properties.facing)
  end
 end

 return"north"
end

local function placeBlock(side)
 local block=cfg[side]

 if not block or block=="" then
  addLog("["..names[side].."] NO BLOCK CONFIGURED")
  return
 end

 local dir=getFacing()
 local oriented=block.."[facing="..dir.."]"

 local ok,result=pcall(commands.setblock,"~","~-1","~",oriented)

 if ok and result~=false then
  addLog("["..names[side].."] "..block.."  FACING "..dir)
  return
 end

 local ok2,result2=pcall(commands.setblock,"~","~-1","~",block)

 if ok2 and result2~=false then
  addLog("["..names[side].."] "..block)
 else
  addLog("["..names[side].."] PLACEMENT FAILED")
 end
end

for _,side in ipairs(sides) do
 previous[side]=redstone.getAnalogInput(side)>0
end

local function scanRedstone()
 for _,side in ipairs(sides) do
  local active=redstone.getAnalogInput(side)>0

  if active and not previous[side] then
   placeBlock(side)
  end

  previous[side]=active
 end
end

local function saveConfig()
 local f=fs.open("/config.lua","w")
 if not f then
  return false
 end

 f.write("return{")
 f.write("left="..string.format("%q",cfg.left)..",")
 f.write("right="..string.format("%q",cfg.right)..",")
 f.write("front="..string.format("%q",cfg.front)..",")
 f.write("back="..string.format("%q",cfg.back)..",")
 f.write("top="..string.format("%q",cfg.top)..",")
 f.write("bottom="..string.format("%q",cfg.bottom)..",")
 f.write("admin_password="..string.format("%q",cfg.admin_password))
 f.write("}")

 f.close()
 return true
end

local function lockedScreen()
 clear()

 center(8,"SYSTEM LOCKED")
 center(10,"SYSTEM LOG")

 local y=12

 for i=#logs,1,-1 do
  if y<=18 then
   center(y,logs[i])
   y=y+1
  end
 end

 local _,h=term.getSize()
 term.setCursorPos(2,h-1)
 write("Press M to Open Admin Menu")
end

local function authenticate()
 clear()

 center(6,"ADMIN AUTHENTICATION")
 center(8,"ENTER ADMIN PASSWORD")

 local w=term.getSize()
 term.setCursorPos(math.max(1,math.floor(w/2)-10),10)

 local password=input(true)

 if b64(password)==cfg.admin_password then
  addLog("ADMIN AUTHENTICATED")
  return true
 end

 addLog("INVALID ADMIN PASSWORD")

 clear()
 center(8,"ACCESS DENIED")
 center(10,"INVALID PASSWORD")
 sleep(1.5)

 return false
end

local function blockConfig()
 while true do
  clear()

  center(3,"BLOCK CONFIGURATION")

  local y=6

  for _,side in ipairs(sides) do
   center(y,names[side].." : "..tostring(cfg[side]))
   y=y+2
  end

  center(19,"ENTER SIDE")
  center(21,"LEFT / RIGHT / FRONT / BACK / TOP / BOTTOM")
  center(23,"B = BACK")

  local w=term.getSize()
  term.setCursorPos(math.max(1,math.floor(w/2)-10),25)

  local side=input(false):lower()

  if side=="b" then
   return
  end

  if cfg[side]~=nil then
   clear()

   center(6,"EDIT "..names[side])
   center(8,"CURRENT")
   center(10,tostring(cfg[side]))
   center(13,"NEW BLOCK ID")

   term.setCursorPos(math.max(1,math.floor(w/2)-15),15)

   local value=input(false)

   if value~="" then
    cfg[side]=value
    saveConfig()
    addLog("CONFIG "..names[side].." UPDATED")
   end
  end
 end
end

local function changePassword()
 clear()

 center(6,"CHANGE PASSWORD")
 center(8,"CURRENT PASSWORD")

 local w=term.getSize()
 term.setCursorPos(math.max(1,math.floor(w/2)-10),10)

 local old=input(true)

 if b64(old)~=cfg.admin_password then
  addLog("PASSWORD CHANGE DENIED")

  clear()
  center(9,"INVALID CURRENT PASSWORD")
  sleep(1.5)
  return
 end

 clear()

 center(6,"CHANGE PASSWORD")
 center(8,"NEW PASSWORD")

 term.setCursorPos(math.max(1,math.floor(w/2)-10),10)

 local new=input(true)

 if new=="" then
  return
 end

 cfg.admin_password=b64(new)
 saveConfig()

 addLog("ADMIN PASSWORD CHANGED")

 clear()
 center(9,"PASSWORD UPDATED")
 sleep(1.5)
end

local function adminMenu()
 if not authenticate() then
  return
 end

 while true do
  clear()

  center(3,"ADMIN CONTROL")
  center(5,"ADMINISTRATOR MODE")

  center(8,"1  BLOCK CONFIGURATION")
  center(10,"2  CHANGE PASSWORD")
  center(12,"3  RESTART SYSTEM")
  center(14,"4  SHUTDOWN")
  center(16,"5  EXIT ADMIN MODE")

  center(20,"B = BACK")
  center(22,"ESC = DISABLED")

  local e,k=os.pullEventRaw()

  if e=="key" then
   if k==keys.one then
    blockConfig()

   elseif k==keys.two then
    changePassword()

   elseif k==keys.three then
    clear()
    center(9,"RESTARTING...")
    addLog("SYSTEM RESTART")
    sleep(1)
    os.reboot()

   elseif k==keys.four then
    clear()
    center(9,"SHUTTING DOWN...")
    addLog("SYSTEM SHUTDOWN")
    sleep(1)
    os.shutdown()

   elseif k==keys.five or k==keys.b then
    return
   end

  elseif e=="terminate" then
  end
 end
end

local function main()
 addLog("SYSTEM INITIALIZED")
 addLog("CONTROLLER ONLINE")
 addLog("FACING "..getFacing())

 while true do
  lockedScreen()

  local timer=os.startTimer(0.05)

  while true do
   local e,a=os.pullEventRaw()

   if e=="timer" and a==timer then
    scanRedstone()
    break

   elseif e=="key" and a==keys.m then
    adminMenu()
    break

   elseif e=="terminate" then
   end
  end
 end
end

main()
