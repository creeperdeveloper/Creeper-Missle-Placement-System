local cfg=dofile("/config.lua")
local sides={"left","right","front","back","top","bottom"}
local names={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local logs={}

local function decode(x)
 x=x:gsub("[^"..chars.."=]","")
 local r={}
 for i=1,#x,4 do
  local a=chars:find(x:sub(i,i),1,true)
  local b=chars:find(x:sub(i+1,i+1),1,true)
  local c=chars:find(x:sub(i+2,i+2),1,true)
  local d=chars:find(x:sub(i+3,i+3),1,true)
  if a and b then
   local q=(a-1)*262144+(b-1)*4096
   if c then q=q+(c-1)*64 end
   if d then q=q+(d-1) end
   r[#r+1]=string.char(math.floor(q/65536)%256)
   if c then r[#r+1]=string.char(math.floor(q/256)%256) end
   if d then r[#r+1]=string.char(q%256) end
  end
 end
 return table.concat(r)
end

local function encode(x)
 local r={}
 for i=1,#x,3 do
  local a=x:byte(i) or 0
  local b=x:byte(i+1)
  local c=x:byte(i+2)
  local q=a*65536+(b or 0)*256+(c or 0)
  local x1=math.floor(q/262144)%64+1
  local x2=math.floor(q/4096)%64+1
  local x3=math.floor(q/64)%64+1
  local x4=q%64+1
  r[#r+1]=chars:sub(x1,x1)..chars:sub(x2,x2)..(b and chars:sub(x3,x3)or"=")..(c and chars:sub(x4,x4)or"=")
 end
 return table.concat(r)
end

local function clearScreen()
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 term.setCursorPos(1,1)
end

local function line(y,text)
 local w=term.getSize()
 term.setCursorPos(1,y)
 term.clearLine()
 if #text>w then text=text:sub(1,w) end
 term.write(text)
end

local function center(y,text)
 local w=term.getSize()
 if #text>w then text=text:sub(1,w) end
 term.setCursorPos(math.max(1,math.floor((w-#text)/2)+1),y)
 term.write(text)
end

local function addLog(text)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..text)
 while #logs>6 do
  table.remove(logs)
 end
end

local function home()
 clearScreen()
 local _,h=term.getSize()
 local y=math.max(2,math.floor(h/2)-4)

 center(y,"SYSTEM LOCKED")
 center(y+2,"SYSTEM LOG")

 if #logs==0 then
  center(y+4,"SYSTEM READY")
 else
  for i=1,math.min(#logs,6) do
   center(y+3+i,logs[i])
  end
 end

 line(h,"Press M to Open Admin Menu")
end

local function quote(x)
 return tostring(x):gsub("\\","\\\\"):gsub("\"","\\\"")
end

local function saveConfig()
 local f=fs.open("/config.lua","w")
 if not f then
  return false
 end

 f.write("return{")
 f.write("left=\""..quote(cfg.left).."\",")
 f.write("right=\""..quote(cfg.right).."\",")
 f.write("front=\""..quote(cfg.front).."\",")
 f.write("back=\""..quote(cfg.back).."\",")
 f.write("top=\""..quote(cfg.top).."\",")
 f.write("bottom=\""..quote(cfg.bottom).."\",")
 f.write("admin_password=\""..quote(cfg.admin_password).."\"")
 f.write("}")

 f.close()
 return true
end

local function authenticate()
 clearScreen()
 center(3,"ADMINISTRATOR AUTHENTICATION")
 center(5,"PASSWORD")
 term.setCursorPos(1,7)

 local password=read("*")

 if password==decode(cfg.admin_password) then
  addLog("ADMIN AUTHENTICATED")
  return true
 end

 center(9,"ACCESS DENIED")
 sleep(2)
 return false
end

local function blockMenu()
 while true do
  clearScreen()
  center(2,"BLOCK CONFIGURATION")
  center(3,"SELECT SIDE")

  for i,side in ipairs(sides) do
   line(4+i,"["..i.."] "..names[side].."  "..tostring(cfg[side]))
  end

  line(12,"[ESC] BACK")

  local event,key=os.pullEventRaw()

  if event=="terminate" then
   if authenticate() then
    return "exit"
   end
   home()

  elseif event=="key" then
   if key==keys.escape then
    return
   end

   local index=key-keys.one+1

   if index>=1 and index<=6 then
    local side=sides[index]

    clearScreen()
    center(3,names[side].." BLOCK")
    center(5,"CURRENT: "..tostring(cfg[side]))
    center(7,"ENTER BLOCK ID")
    term.setCursorPos(1,8)

    local value=read()

    if value and value~="" then
     cfg[side]=value

     if saveConfig() then
      addLog(names[side].." BLOCK UPDATED")
      center(10,"CONFIGURATION SAVED")
     else
      addLog("CONFIG SAVE FAILED")
      center(10,"SAVE FAILED")
     end

     sleep(1)
    end
   end
  end
 end
end

local function passwordMenu()
 clearScreen()
 center(3,"PASSWORD SETTINGS")
 center(5,"CURRENT PASSWORD")
 term.setCursorPos(1,6)

 local old=read()

 if old~=decode(cfg.admin_password) then
  center(9,"CURRENT PASSWORD INVALID")
  sleep(2)
  return
 end

 clearScreen()
 center(3,"PASSWORD SETTINGS")
 center(5,"NEW PASSWORD")
 term.setCursorPos(1,6)

 local newPassword=read()

 if not newPassword or newPassword=="" then
  center(9,"PASSWORD CANNOT BE EMPTY")
  sleep(2)
  return
 end

 clearScreen()
 center(3,"PASSWORD SETTINGS")
 center(5,"CONFIRM NEW PASSWORD")
 term.setCursorPos(1,6)

 local confirm=read()

 if newPassword~=confirm then
  center(9,"PASSWORDS DO NOT MATCH")
  sleep(2)
  return
 end

 cfg.admin_password=encode(newPassword)

 if saveConfig() then
  addLog("ADMIN PASSWORD UPDATED")
  center(9,"PASSWORD UPDATED")
 else
  center(9,"SAVE FAILED")
 end

 sleep(2)
end

local function adminMenu()
 if not authenticate() then
  home()
  return
 end

 while true do
  clearScreen()
  center(2,"ADMINISTRATION")
  center(3,"SYSTEM MANAGEMENT")

  line(6,"[1] BLOCK CONFIGURATION")
  line(7,"[2] PASSWORD SETTINGS")
  line(8,"[3] RESTART COMPUTER")
  line(9,"[4] SHUTDOWN COMPUTER")
  line(10,"[5] EXIT CONTROLLER")
  line(12,"[ESC] BACK")

  local event,key=os.pullEventRaw()

  if event=="terminate" then
   if authenticate() then
    return "exit"
   end

  elseif event=="key" then
   if key==keys.one then
    local result=blockMenu()
    if result=="exit" then
     return "exit"
    end

   elseif key==keys.two then
    passwordMenu()

   elseif key==keys.three then
    clearScreen()
    center(7,"RESTARTING COMPUTER...")
    sleep(1)
    os.reboot()

   elseif key==keys.four then
    clearScreen()
    center(7,"SHUTTING DOWN COMPUTER...")
    sleep(1)
    os.shutdown()

   elseif key==keys.five then
    clearScreen()
    center(7,"CONTROLLER EXIT AUTHORIZED")
    sleep(1)
    return "exit"

   elseif key==keys.escape then
    return
   end
  end
 end
end

local function terminateRequest()
 clearScreen()
 center(3,"TERMINATION REQUEST")
 center(5,"ADMINISTRATOR PASSWORD REQUIRED")
 term.setCursorPos(1,7)

 local password=read("*")

 if password==decode(cfg.admin_password) then
  addLog("CONTROLLER TERMINATED")
  return true
 end

 center(9,"ACCESS DENIED")
 sleep(2)
 return false
end

local function placeBlock(side)
 local block=cfg[side]

 if type(block)~="string" or block=="" then
  addLog(names[side].." INVALID BLOCK")
  return
 end

 if block=="minecraft:air" then
  addLog(names[side].." PLACEMENT SKIPPED")
  return
 end

 local ok=pcall(commands.setblock,"~","~-1","~",block)

 if ok then
  addLog(names[side].." PLACED")
 else
  addLog(names[side].." PLACEMENT FAILED")
 end
end

local function scanRedstone()
 for _,side in ipairs(sides) do
  if redstone.getAnalogInput(side)>0 then
   placeBlock(side)

   while redstone.getAnalogInput(side)>0 do
    local event,key=os.pullEventRaw()

    if event=="terminate" then
     if terminateRequest() then
      return true
     end
     home()

    elseif event=="key" and key==keys.m then
     local result=adminMenu()
     if result=="exit" then
      return true
     end
     home()
    end
   end
  end
 end

 return false
end

addLog("CONTROLLER ONLINE")
home()

while true do
 local timer=os.startTimer(0.05)
 local event,id=os.pullEventRaw()

 if event=="terminate" then
  if terminateRequest() then
   return
  end
  home()

 elseif event=="key" and id==keys.m then
  local result=adminMenu()
  if result=="exit" then
   return
  end
  home()

 elseif event=="timer" and id==timer then
  if scanRedstone() then
   return
  end
 end
end
