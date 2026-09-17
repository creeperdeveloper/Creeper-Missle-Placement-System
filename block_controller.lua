local cfg=dofile("/config.lua")

local sides={"left","right","front","back","top","bottom"}
local names={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local logs={}
local previous={}

local function base64(s)
 local t="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 local r=""
 local i=1
 while i<=#s do
  local a=s:byte(i)or 0
  local b=s:byte(i+1)
  local c=s:byte(i+2)
  local n=a*65536+(b or 0)*256+(c or 0)
  r=r..t:sub(math.floor(n/262144)%64+1,math.floor(n/262144)%64+1)
  r=r..t:sub(math.floor(n/4096)%64+1,math.floor(n/4096)%64+1)
  if b then r=r..t:sub(math.floor(n/64)%64+1,math.floor(n/64)%64+1)else r=r.."="end
  if c then r=r..t:sub(n%64+1,n%64+1)else r=r.."="end
  i=i+3
 end
 return r
end

local function addLog(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..s)
 while #logs>3 do table.remove(logs)end
end

local function clear()
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 term.setCursorPos(1,1)
end

local function center(y,s)
 local w=term.getSize()
 local x=math.floor((w-#s)/2)+1
 if x<1 then x=1 end
 term.setCursorPos(x,y)
 write(s)
end

local function input(mask)
 local w=term.getSize()
 local text=""
 local sx,sy=term.getCursorPos()

 term.setCursorPos(sx,sy)
 write(string.rep(" ",math.max(0,w-sx+1)))
 term.setCursorPos(sx,sy)

 while true do
  local event,a=os.pullEventRaw()

  if event=="char" then
   text=text..a
   if mask then write("*")else write(a)end
  elseif event=="paste" then
   text=text..a
   if mask then write(string.rep("*",#a))else write(a)end
  elseif event=="key" then
   if a==keys.enter then
    return text
   elseif a==keys.backspace and #text>0 then
    text=text:sub(1,#text-1)
    term.setCursorPos(sx,sy)
    write(string.rep(" ",math.max(0,w-sx+1)))
    term.setCursorPos(sx,sy)
    if mask then write(string.rep("*",#text))else write(text)end
    term.setCursorPos(sx+#text,sy)
   end
  end
 end
end

local function localFacing()
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

local function facingVector(d)
 if d=="north" then return vector.new(0,0,-1)end
 if d=="south" then return vector.new(0,0,1)end
 if d=="east" then return vector.new(1,0,0)end
 if d=="west" then return vector.new(-1,0,0)end
 if d=="up" then return vector.new(0,1,0)end
 if d=="down" then return vector.new(0,-1,0)end
 return vector.new(0,0,-1)
end

local function rotateVector(v,q)
 local ok,r=pcall(function()
  return q:mul(v)
 end)

 if not ok or not r then
  return nil
 end

 local x=r.x
 local y=r.y
 local z=r.z

 if x==nil or y==nil or z==nil then
  return nil
 end

 return vector.new(x,y,z)
end

local function getWorldVector()
 local lf=localFacing()

 local ok,v=pcall(function()
  if type(sublevel)~="table" then
   return nil
  end

  if type(sublevel.isInPlotGrid)~="function" then
   return nil
  end

  if not sublevel.isInPlotGrid() then
   return nil
  end

  if type(sublevel.getLogicalPose)~="function" then
   return nil
  end

  local pose=sublevel.getLogicalPose()

  if type(pose)~="table" or not pose.orientation then
   return nil
  end

  return rotateVector(facingVector(lf),pose.orientation)
 end)

 if ok and v then
  return v
 end

 return facingVector(lf)
end

local function getDirection()
 local v=getWorldVector()

 local x=v.x or 0
 local y=v.y or 0
 local z=v.z or 0

 local ax=math.abs(x)
 local ay=math.abs(y)
 local az=math.abs(z)

 if ay>=ax and ay>=az then
  if y>=0 then
   return 0,-90,"up"
  else
   return 0,90,"down"
  end
 end

 if ax>=az then
  if x>0 then
   return -90,0,"east"
  else
   return 90,0,"west"
  end
 end

 if z>0 then
  return 0,0,"south"
 else
  return 180,0,"north"
 end
end

local function placeBlock(side)
 local block=cfg[side]

 if not block or block=="" then
  addLog("["..names[side].."] NO BLOCK CONFIGURED")
  return
 end

 local yaw,pitch,dir=getDirection()

 local cmd="execute rotated "..tostring(yaw).." "..tostring(pitch).." run setblock ^ ^-1 ^ "..block.."[facing="..dir.."]"

 local ok,result=commands.exec(cmd)

 if ok then
  addLog("["..names[side].."] "..block.." FACING "..dir)
  return
 end

 local cmd2="execute rotated "..tostring(yaw).." "..tostring(pitch).." run setblock ^ ^-1 ^ "..block

 local ok2,result2=commands.exec(cmd2)

 if ok2 then
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

local function lockedScreen()
 clear()

 center(8,"SYSTEM LOCKED")
 center(10,"SYSTEM LOG")

 local y=12

 for i=#logs,1,-1 do
  if y<=14 then
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
 center(10,"Password:")

 local w=term.getSize()
 local x=math.max(1,math.floor(w/2)-10)

 term.setCursorPos(x,11)
 write(string.rep(" ",20))
 term.setCursorPos(x,11)

 local password=input(true)

 if base64(password)==tostring(cfg.admin_password) then
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

  if side=="b" then return end

  if cfg[side]~=nil then
   clear()

   center(6,"EDIT "..names[side])
   center(8,"CURRENT BLOCK")
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

 if base64(old)~=tostring(cfg.admin_password) then
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

 if new=="" then return end

 cfg.admin_password=base64(new)
 saveConfig()

 addLog("ADMIN PASSWORD CHANGED")

 clear()
 center(9,"PASSWORD UPDATED")
 sleep(1.5)
end

local function adminMenu()
 if not authenticate() then return end

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

  local event,key=os.pullEventRaw()

  if event=="key" then
   if key==keys.one then
    blockConfig()
   elseif key==keys.two then
    changePassword()
   elseif key==keys.three then
    clear()
    center(9,"RESTARTING...")
    addLog("SYSTEM RESTART")
    sleep(1)
    os.reboot()
   elseif key==keys.four then
    clear()
    center(9,"SHUTTING DOWN...")
    addLog("SYSTEM SHUTDOWN")
    sleep(1)
    os.shutdown()
   elseif key==keys.five or key==keys.b then
    return
   end
  end
 end
end

local function main()
 addLog("SYSTEM INITIALIZED")
 addLog("CONTROLLER ONLINE")

 local _,_,f=getDirection()
 addLog("FACING "..f)

 while true do
  lockedScreen()

  local timer=os.startTimer(0.05)

  while true do
   local event,a=os.pullEventRaw()

   if event=="timer" and a==timer then
    scanRedstone()
    break
   elseif event=="key" and a==keys.m then
    adminMenu()
    break
   elseif event=="terminate" then
   end
  end
 end
end

main()
