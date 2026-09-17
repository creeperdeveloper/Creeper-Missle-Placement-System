```lua
local cfg=dofile("/config.lua")

local sides={"left","right","front","back","top","bottom"}
local names={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local logs={}
local previous={}
local maxLogs=7

local function enc(s)
 local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 return ((s:gsub(".",function(x)
  local r="",n=x:byte()
  for i=8,1,-1 do r=r..(n%2^i-n%2^(i-1)>0 and"1"or"0") end
  return r
 end).."0000"):gsub("%d%d%d?%d?%d?%d?",function(x)
  if #x<6 then return"" end
  local n=0
  for i=1,6 do n=n+(x:sub(i,i)=="1" and 2^(6-i) or 0) end
  return b:sub(n+1,n+1)
 end)..({"","==","="}[#s%3+1])
end

local function log(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..s)
 while #logs>maxLogs do table.remove(logs) end
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

local function input(mask)
 local w,h=term.getSize()
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
    print()
    return text

   elseif a==keys.backspace then
    if #text>0 then
     text=text:sub(1,-2)
     term.setCursorPos(sx,sy)
     write(string.rep(" ",w-sx+1))
     term.setCursorPos(sx,sy)
     write(mask and string.rep("*",#text)or text)
     term.setCursorPos(sx+#text,sy)
    end

   elseif a==keys.escape then
   end

  elseif e=="terminate" then
  end
 end
end

local function facing()
 local ok,data=pcall(commands.getBlockInfo,"~","~","~")

 if ok and type(data)=="table" then
  if type(data.state)=="table" and data.state.facing then
   return tostring(data.state.facing)
  end

  if type(data.properties)=="table" and data.properties.facing then
   return tostring(data.properties.facing)
  end
 end

 return"north"
end

local function place(side)
 local block=cfg[side]

 if not block or block=="" then
  log("["..names[side].."] NO BLOCK CONFIGURED")
  return
 end

 local dir=facing()
 local target=block.."[facing="..dir.."]"

 local ok,result=pcall(commands.setblock,"~","~-1","~",target)

 if ok and result~=false then
  log("["..names[side].."] "..block.."  FACING "..dir)
  return
 end

 local ok2,result2=pcall(commands.setblock,"~","~-1","~",block)

 if ok2 and result2~=false then
  log("["..names[side].."] "..block.."  FACING "..dir)
 else
  log("["..names[side].."] PLACEMENT FAILED")
 end
end

for _,s in ipairs(sides) do
 previous[s]=redstone.getAnalogInput(s)>0
end

local function scan()
 for _,s in ipairs(sides) do
  local active=redstone.getAnalogInput(s)>0

  if active and not previous[s] then
   place(s)
  end

  previous[s]=active
 end
end

local function save()
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

local function lock()
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
 title("ADMIN AUTHENTICATION")

 center(7,"ENTER ADMIN PASSWORD")
 center(9,"Password:")

 local w=select(1,term.getSize())
 term.setCursorPos(math.max(1,math.floor(w/2)-10),10)

 local p=input(true)

 if enc(p)==cfg.admin_password then
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

  center(5,"REDSTONE INPUT / BLOCK")

  local y=7
  for _,s in ipairs(sides) do
   center(y,names[s].."  :  "..tostring(cfg[s]))
   y=y+1
  end

  center(15,"TYPE SIDE")
  center(17,"LEFT / RIGHT / FRONT / BACK / TOP / BOTTOM")
  center(19,"Type B to Return")

  local w=select(1,term.getSize())
  term.setCursorPos(math.max(1,math.floor(w/2)-10),21)

  local s=input(false):lower()

  if s=="b" then
   return
  end

  if cfg[s]~=nil then
   title("EDIT "..names[s])

   center(7,"CURRENT BLOCK")
   center(9,tostring(cfg[s]))
   center(12,"ENTER NEW BLOCK ID")

   term.setCursorPos(math.max(1,math.floor(w/2)-15),14)

   local v=input(false)

   if v~="" then
    cfg[s]=v
    save()
    log("CONFIG "..names[s].." = "..v)
   end
  end
 end
end

local function passwordMenu()
 title("CHANGE PASSWORD")

 center(6,"CURRENT PASSWORD")

 local w=select(1,term.getSize())
 term.setCursorPos(math.max(1,math.floor(w/2)-10),8)

 local old=input(true)

 if enc(old)~=cfg.admin_password then
  log("PASSWORD CHANGE DENIED")
  center(11,"INVALID CURRENT PASSWORD")
  sleep(1.5)
  return
 end

 title("CHANGE PASSWORD")

 center(6,"NEW PASSWORD")
 term.setCursorPos(math.max(1,math.floor(w/2)-10),8)

 local new=input(true)

 if new=="" then
  return
 end

 cfg.admin_password=enc(new)
 save()

 log("ADMIN PASSWORD CHANGED")

 center(11,"PASSWORD UPDATED")
 sleep(1.5)
end

local function admin()
 if not authenticate() then
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

  local e,k=os.pullEventRaw()

  if e=="key" then
   if k==keys.one then
    blockMenu()

   elseif k==keys.two then
    passwordMenu()

   elseif k==keys.three then
    title("RESTART SYSTEM")
    center(8,"Restarting...")
    log("SYSTEM RESTART")
    sleep(1)
    os.reboot()

   elseif k==keys.four then
    title("SHUTDOWN")
    center(8,"Shutting down...")
    log("SYSTEM SHUTDOWN")
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
 log("SYSTEM INITIALIZED")
 log("CONTROLLER ONLINE")
 log("FACING "..facing())

 while true do
  lock()

  local timer=os.startTimer(.05)

  while true do
   local e,a=os.pullEventRaw()

   if e=="timer" and a==timer then
    scan()
    break

   elseif e=="key" and a==keys.m then
    admin()
    break

   elseif e=="terminate" then
   end
  end
 end
end

main()
```
