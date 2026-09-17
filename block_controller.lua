local cfg=dofile("/config.lua")

local sides={"left","right","front","back","top","bottom"}
local names={
 left="LEFT",
 right="RIGHT",
 front="FRONT",
 back="BACK",
 top="TOP",
 bottom="BOTTOM"
}

local function enc(s)
 local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 return ((s:gsub('.',function(x)
  local r,bits='',x:byte()
  for i=8,1,-1 do r=r..(bits%2^i-bits%2^(i-1)>0 and'1'or'0') end
  return r
 end)..'0000'):gsub('%d%d%d?%d?%d?%d?',function(x)
  if #x<6 then return'' end
  local c=0
  for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
  return b:sub(c+1,c+1)
 end)..({ '', '==', '=' })[#s%3+1])
end

local function dec(s)
 local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 s=s:gsub('[^'..b..'=]','')
 return (s:gsub('.',function(x)
  if x=='=' then return'' end
  local r,bits='',b:find(x)-1
  for i=6,1,-1 do r=r..(bits%2^i-bits%2^(i-1)>0 and'1'or'0') end
  return r
 end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
  if #x~=8 then return'' end
  local c=0
  for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
  return string.char(c)
 end))
end

local logs={}
local maxLogs=7

local function log(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..s)
 while #logs>maxLogs do
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
 local w=select(1,term.getSize())
 term.setCursorPos(math.max(1,math.floor((w-#s)/2)+1),y)
 write(s)
end

local function title(s)
 clear()
 center(2,s)
end

local function keyName(k)
 if keys.getName then
  return keys.getName(k) or ""
 end
 return ""
end

local function safeRead(mask)
 local text=""
 local x,y=term.getCursorPos()

 while true do
  local e,a,b,c,d=os.pullEventRaw()

  if e=="char" then
   text=text..a
   write(mask and "*" or a)

  elseif e=="paste" then
   text=text..a
   write(mask and string.rep("*",#a) or a)

  elseif e=="key" then
   if a==keys.enter then
    print()
    return text

   elseif a==keys.backspace then
    if #text>0 then
     text=text:sub(1,-2)
     term.setCursorPos(x,y)
     write(string.rep(" ",w-x+1))
     term.setCursorPos(x,y)
     write(mask and string.rep("*",#text) or text)
    end

   elseif a==keys.left then
    term.setCursorPos(x,y)

   elseif a==keys.right then
    term.setCursorPos(x+#text,y)

   elseif a==keys.escape then
   end

  elseif e=="terminate" then
  end
 end
end

local function computerFacing()
 local ok,data=pcall(commands.getBlockInfo,"~","~","~")

 if ok and type(data)=="table" then
  if type(data.state)=="table" then
   local f=data.state.facing or data.state.Facing
   if f then return tostring(f) end
  end

  if type(data.properties)=="table" then
   local f=data.properties.facing or data.properties.Facing
   if f then return tostring(f) end
  end
 end

 return "north"
end

local function setBlock(block)
 local facing=computerFacing()
 local withFacing=block.."[facing="..facing.."]"

 local ok,result=pcall(commands.setblock,"~","~-1","~",withFacing)

 if ok and result~=false then
  return true,facing
 end

 local ok2,result2=pcall(commands.setblock,"~","~-1","~",block)

 if ok2 and result2~=false then
  return true,facing
 end

 return false,facing
end

local function place(side)
 local block=cfg[side]

 if not block or block=="" then
  log("["..names[side].."] NO BLOCK CONFIGURED")
  return
 end

 local ok,facing=setBlock(block)

 if ok then
  log("["..names[side].."] "..block.."  FACING "..facing)
 else
  log("["..names[side].."] PLACEMENT FAILED")
 end
end

local previous={}
for _,side in ipairs(sides) do
 previous[side]=redstone.getAnalogInput(side)>0
end

local function scan()
 for _,side in ipairs(sides) do
  local active=redstone.getAnalogInput(side)>0

  if active and not previous[side] then
   place(side)
  end

  previous[side]=active
 end
end

local function saveConfig()
 local f=fs.open("/config.lua","w")
 if not f then return false end

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

local function lockScreen()
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

 term.setCursorPos(2,select(2,term.getSize())-1)
 write("Press M to Open Admin Menu")
end

local function passwordCheck()
 title("ADMIN AUTHENTICATION")
 center(7,"ENTER ADMIN PASSWORD")
 center(9,"Password:")
 term.setCursorPos(math.floor(select(1,term.getSize())/2)-10,10)

 local input=safeRead(true)

 if enc(input)==cfg.admin_password then
  log("ADMIN AUTHENTICATED")
  return true
 end

 log("ADMIN AUTHENTICATION FAILED")
 title("ACCESS DENIED")
 center(8,"INVALID PASSWORD")
 sleep(1.5)
 return false
end

local function blockMenu()
 while true do
  title("BLOCK CONFIGURATION")

  center(5,"SELECT REDSTONE INPUT")

  local y=7
  for i,side in ipairs(sides) do
   center(y,names[side].."  :  "..tostring(cfg[side]))
   y=y+1
  end

  center(15,"ENTER SIDE")
  center(17,"Type LEFT / RIGHT / FRONT / BACK / TOP / BOTTOM")
  center(19,"Press B to Return")

  term.setCursorPos(math.floor(select(1,term.getSize())/2)-10,21)
  local side=safeRead(false):lower()

  if side=="b" then
   return
  end

  if cfg[side]~=nil then
   title("EDIT "..names[side])
   center(7,"CURRENT BLOCK")
   center(9,tostring(cfg[side]))
   center(12,"ENTER NEW BLOCK ID")
   term.setCursorPos(math.floor(select(1,term.getSize())/2)-15,14)

   local value=safeRead(false)

   if value~="" then
    cfg[side]=value
    saveConfig()
    log("CONFIG "..names[side].." = "..value)
   end
  end
 end
end

local function passwordMenu()
 title("CHANGE PASSWORD")

 center(6,"CURRENT PASSWORD")
 term.setCursorPos(math.floor(select(1,term.getSize())/2)-10,8)
 local current=safeRead(true)

 if enc(current)~=cfg.admin_password then
  log("PASSWORD CHANGE DENIED")
  center(11,"INVALID CURRENT PASSWORD")
  sleep(1.5)
  return
 end

 title("CHANGE PASSWORD")

 center(6,"NEW PASSWORD")
 term.setCursorPos(math.floor(select(1,term.getSize())/2)-10,8)
 local newPassword=safeRead(true)

 if newPassword=="" then
  return
 end

 cfg.admin_password=enc(newPassword)
 saveConfig()

 log("ADMIN PASSWORD CHANGED")

 center(11,"PASSWORD UPDATED")
 sleep(1.5)
end

local function adminMenu()
 if not passwordCheck() then
  return
 end

 while true do
  title("ADMIN CONTROL")

  center(5,"ADMINISTRATOR MODE")

  center(8,"1  BLOCK CONFIGURATION")
  center(10,"2  CHANGE PASSWORD")
  center(12,"3  RESTART SYSTEM")
  center(14,"4  SHUTDOWN")
  center(16,"5  EXIT ADMIN MODE")

  center(20,"Press B to Return")

  local _,key=os.pullEventRaw()

  if key=="terminate" then
  elseif key=="key" then
   if key==keys.one then
    blockMenu()

   elseif key==keys.two then
    passwordMenu()

   elseif key==keys.three then
    title("RESTART SYSTEM")
    center(8,"Restarting...")
    log("SYSTEM RESTART")
    sleep(1)
    os.reboot()

   elseif key==keys.four then
    title("SHUTDOWN")
    center(8,"Shutting down...")
    log("SYSTEM SHUTDOWN")
    sleep(1)
    os.shutdown()

   elseif key==keys.five then
    return

   elseif key==keys.b then
    return
   end
  end
 end
end

local function main()
 log("SYSTEM INITIALIZED")
 log("CONTROLLER ONLINE")
 log("FACING "..computerFacing())

 while true do
  lockScreen()

  local timer=os.startTimer(0.05)

  while true do
   local e,a=os.pullEventRaw()

   if e=="timer" and a==timer then
    scan()
    break

   elseif e=="key" then
    if a==keys.m then
     adminMenu()
     break
    end
   elseif e=="terminate" then
   end
  end
 end
end

main()
