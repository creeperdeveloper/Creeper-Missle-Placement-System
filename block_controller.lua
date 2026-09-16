local c=dofile("/config.lua")
local s={"left","right","front","back","top","bottom"}
local n={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local B="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local L={}

local function de(x)
 x=x:gsub("[^"..B.."=]","")
 local r={}
 for i=1,#x,4 do
  local a=B:find(x:sub(i,i),1,true)
  local b=B:find(x:sub(i+1,i+1),1,true)
  local d=B:find(x:sub(i+2,i+2),1,true)
  local e=B:find(x:sub(i+3,i+3),1,true)
  if a and b then
   local q=(a-1)*262144+(b-1)*4096
   if d then q=q+(d-1)*64 end
   if e then q=q+(e-1)end
   r[#r+1]=string.char(math.floor(q/65536)%256)
   if d then r[#r+1]=string.char(math.floor(q/256)%256)end
   if e then r[#r+1]=string.char(q%256)end
  end
 end
 return table.concat(r)
end

local function en(x)
 local r={}
 for i=1,#x,3 do
  local a=x:byte(i)or 0
  local b=x:byte(i+1)
  local d=x:byte(i+2)
  local q=a*65536+(b or 0)*256+(d or 0)
  local z=math.floor(q/262144)%64+1
  local w=math.floor(q/4096)%64+1
  local e=math.floor(q/64)%64+1
  local f=q%64+1
  r[#r+1]=B:sub(z,z)..B:sub(w,w)..(b and B:sub(e,e)or"=")..(d and B:sub(f,f)or"=")
 end
 return table.concat(r)
end

local function cl()
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 term.setCursorPos(1,1)
end

local function ln(y,t)
 local w=term.getSize()
 term.setCursorPos(1,y)
 term.clearLine()
 if #t>w then t=t:sub(1,w)end
 term.write(t)
end

local function ct(y,t)
 local w=term.getSize()
 term.setCursorPos(math.max(1,math.floor((w-#t)/2)+1),y)
 term.write(t)
end

local function log(t)
 table.insert(L,1,os.date("%H:%M:%S").."  "..t)
 while #L>5 do table.remove(L)end
end

local function home()
 cl()
 local _,h=term.getSize()
 ct(math.floor(h/2)-3,"SYSTEM LOCKED")
 ct(math.floor(h/2)-1,"SYSTEM LOG")

 local y=math.floor(h/2)+1
 if #L==0 then
  ct(y,"SYSTEM READY")
 else
  for i=1,math.min(#L,5)do
   ct(y+i-1,L[i])
  end
 end

 term.setCursorPos(2,h)
 term.write("Press M to Open Admin Menu")
end

local function save()
 local h=fs.open("/config.lua","w")
 if not h then return false end

 local function q(x)
  return x:gsub("\\","\\\\"):gsub("\"","\\\"")
 end

 h.write("return{")
 h.write("left=\""..q(c.left).."\",")
 h.write("right=\""..q(c.right).."\",")
 h.write("front=\""..q(c.front).."\",")
 h.write("back=\""..q(c.back).."\",")
 h.write("top=\""..q(c.top).."\",")
 h.write("bottom=\""..q(c.bottom).."\",")
 h.write("admin_password=\""..q(c.admin_password).."\"")
 h.write("}")
 h.close()
 return true
end

local function auth()
 cl()
 ct(3,"ADMINISTRATOR AUTHENTICATION")
 ct(5,"PASSWORD")
 term.setCursorPos(1,7)
 local p=read("*")

 if p==de(c.admin_password)then
  return true
 end

 ct(9,"ACCESS DENIED")
 sleep(2)
 return false
end

local function blockMenu()
 while true do
  cl()
  ct(2,"BLOCK CONFIGURATION")
  ct(3,"Select a side to configure")
  local y=5

  for i,q in ipairs(s)do
   ln(y+i-1,"["..i.."] "..n[q].."  "..c[q])
  end

  ln(y+7,"[ESC] BACK")

  local e,k=os.pullEventRaw()

  if e=="key"then
   if k==keys.escape then return end

   local z=k-keys.one+1

   if z>=1 and z<=6 then
    local q=s[z]

    cl()
    ct(3,n[q].." BLOCK")
    ct(5,"Current: "..c[q])
    ct(7,"Enter Block ID:")
    term.setCursorPos(1,8)

    local v=read()

    if v and v~=""then
     c[q]=v

     if save()then
      log(n[q].." BLOCK UPDATED")
     else
      log("CONFIG SAVE FAILED")
     end

     sleep(1)
    end
   end
  end
 end
end

local function passwordMenu()
 cl()
 ct(3,"PASSWORD SETTINGS")
 ct(5,"Enter current password")
 term.setCursorPos(1,6)
 local old=read("*")

 if old~=de(c.admin_password)then
  ct(8,"CURRENT PASSWORD INVALID")
  sleep(2)
  return
 end

 cl()
 ct(3,"PASSWORD SETTINGS")
 ct(5,"Enter new password")
 term.setCursorPos(1,6)
 local new=read("*")

 if not new or new==""then
  ct(8,"PASSWORD CANNOT BE EMPTY")
  sleep(2)
  return
 end

 cl()
 ct(3,"PASSWORD SETTINGS")
 ct(5,"Confirm new password")
 term.setCursorPos(1,6)
 local confirm=read("*")

 if new~=confirm then
  ct(8,"PASSWORDS DO NOT MATCH")
  sleep(2)
  return
 end

 c.admin_password=en(new)

 if save()then
  log("ADMIN PASSWORD UPDATED")
  ct(8,"PASSWORD UPDATED")
 else
  ct(8,"SAVE FAILED")
 end

 sleep(2)
end

local function admin()
 if not auth()then
  home()
  return
 end

 while true do
  cl()
  ct(2,"ADMINISTRATION")
  ct(3,"SYSTEM MANAGEMENT")

  ln(6,"[1] BLOCK CONFIGURATION")
  ln(7,"[2] PASSWORD SETTINGS")
  ln(8,"[3] RESTART COMPUTER")
  ln(9,"[4] SHUTDOWN COMPUTER")
  ln(10,"[5] EXIT CONTROLLER")
  ln(12,"[ESC] BACK")

  local e,k=os.pullEventRaw()

  if e=="key"then
   if k==keys.one then
    blockMenu()

   elseif k==keys.two then
    passwordMenu()

   elseif k==keys.three then
    cl()
    ct(7,"RESTARTING COMPUTER...")
    sleep(1)
    os.reboot()
    return

   elseif k==keys.four then
    cl()
    ct(7,"SHUTTING DOWN COMPUTER...")
    sleep(1)
    os.shutdown()
    return

   elseif k==keys.five then
    cl()
    ct(7,"CONTROLLER EXIT AUTHORIZED")
    sleep(1)
    return"exit"

   elseif k==keys.escape then
    home()
    return
   end
  end
 end
end

local function terminate()
 cl()
 ct(3,"TERMINATION REQUEST")
 ct(5,"ADMINISTRATOR PASSWORD REQUIRED")
 term.setCursorPos(1,7)

 local p=read("*")

 if p==de(c.admin_password)then
  log("CONTROLLER TERMINATED")
  return true
 end

 ct(9,"ACCESS DENIED")
 sleep(2)
 home()
 return false
end

local function place(q)
 local v=redstone.getAnalogInput(q)
 local x=c[q]

 if type(x)~="string"or x==""then
  log(n[q].." INVALID BLOCK")
  return
 end

 if x=="minecraft:air"then
  log(n[q].." PLACEMENT SKIPPED")
  return
 end

 local ok,e=pcall(commands.setblock,"~","~-1","~",x)

 if ok then
  log(n[q].." PLACED "..x)
 else
  log(n[q].." PLACEMENT FAILED")
 end
end

log("CONTROLLER ONLINE")
home()

while true do
 local e,a=os.pullEventRaw()

 if e=="terminate"then
  if terminate()then return end

 elseif e=="key"and a==keys.m then
  if admin()=="exit"then return end
  home()

 elseif e=="redstone"then
  for _,q in ipairs(s)do
   if redstone.getAnalogInput(q)>0 then
    place(q)

    while redstone.getAnalogInput(q)>0 do
     local z,k=os.pullEventRaw()

     if z=="terminate"then
      if terminate()then return end
     elseif z=="key"and k==keys.m then
      if admin()=="exit"then return end
     end
    end

    home()
   end
  end
 end
end
