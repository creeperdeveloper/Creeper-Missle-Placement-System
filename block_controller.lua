local c=dofile("/config.lua")
local S={"left","right","front","back","top","bottom"}
local N={left="LEFT",right="RIGHT",front="FRONT",back="BACK",top="TOP",bottom="BOTTOM"}
local B="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local L={}
local X=false

local function D(x)
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
   if e then q=q+(e-1) end
   r[#r+1]=string.char(math.floor(q/65536)%256)
   if d then r[#r+1]=string.char(math.floor(q/256)%256) end
   if e then r[#r+1]=string.char(q%256) end
  end
 end
 return table.concat(r)
end

local function E(x)
 local r={}
 for i=1,#x,3 do
  local a=x:byte(i) or 0
  local b=x:byte(i+1)
  local d=x:byte(i+2)
  local q=a*65536+(b or 0)*256+(d or 0)
  local z=math.floor(q/262144)%64+1
  local w=math.floor(q/4096)%64+1
  local e=math.floor(q/64)%64+1
  local f=q%64+1
  r[#r+1]=B:sub(z,z)..B:sub(w,w)..(b and B:sub(e,e) or "=")..(d and B:sub(f,f) or "=")
 end
 return table.concat(r)
end

local function C()
 term.setBackgroundColor(colors.white)
 term.setTextColor(colors.black)
 term.clear()
 term.setCursorPos(1,1)
end

local function W(y,t)
 local w=term.getSize()
 term.setCursorPos(1,y)
 term.clearLine()
 if #t>w then t=t:sub(1,w) end
 term.write(t)
end

local function T(y,t)
 local w=term.getSize()
 if #t>w then t=t:sub(1,w) end
 term.setCursorPos(math.max(1,math.floor((w-#t)/2)+1),y)
 term.write(t)
end

local function G(t)
 table.insert(L,1,os.date("%H:%M:%S").."  "..t)
 while #L>6 do table.remove(L) end
end

local function H()
 C()
 local _,h=term.getSize()
 local y=math.max(2,math.floor(h/2)-3)
 T(y,"SYSTEM LOCKED")
 T(y+2,"SYSTEM LOG")
 if #L==0 then
  T(y+4,"SYSTEM READY")
 else
  for i=1,math.min(#L,6) do
   T(y+3+i,L[i])
  end
 end
 W(h,"Press M to Open Admin Menu")
end

local function Q(x)
 return tostring(x):gsub("\\","\\\\"):gsub("\"","\\\"")
end

local function V()
 local h=fs.open("/config.lua","w")
 if not h then return false end
 h.write("return{")
 h.write("left=\""..Q(c.left).."\",")
 h.write("right=\""..Q(c.right).."\",")
 h.write("front=\""..Q(c.front).."\",")
 h.write("back=\""..Q(c.back).."\",")
 h.write("top=\""..Q(c.top).."\",")
 h.write("bottom=\""..Q(c.bottom).."\",")
 h.write("admin_password=\""..Q(c.admin_password).."\"")
 h.write("}")
 h.close()
 return true
end

local function Z()
 C()
 local _,h=term.getSize()
 T(3,"ADMINISTRATOR AUTHENTICATION")
 T(5,"PASSWORD")
 term.setCursorPos(1,7)
 local p=read("*")
 if p==D(c.admin_password) then
  G("ADMIN AUTHENTICATED")
  return true
 end
 T(9,"ACCESS DENIED")
 sleep(2)
 return false
end

local function K()
 while true do
  C()
  local _,h=term.getSize()
  T(2,"BLOCK CONFIGURATION")
  T(3,"SELECT SIDE")
  local y=5
  for i,s in ipairs(S) do
   W(y+i-1,"["..i.."] "..N[s].."  "..tostring(c[s]))
  end
  W(y+7,"[ESC] BACK")
  local e,k=os.pullEventRaw()

  if e=="terminate" then
   if Z() then return "exit" end
  elseif e=="key" then
   if k==keys.escape then return end
   local n=k-keys.one+1
   if n>=1 and n<=6 then
    local s=S[n]
    C()
    T(3,N[s].." BLOCK")
    T(5,"CURRENT: "..tostring(c[s]))
    T(7,"ENTER BLOCK ID")
    term.setCursorPos(1,8)
    local v=read()
    if v and v~="" then
     c[s]=v
     if V() then
      G(N[s].." BLOCK UPDATED")
      T(10,"CONFIGURATION SAVED")
     else
      G("CONFIG SAVE FAILED")
      T(10,"SAVE FAILED")
     end
     sleep(1)
    end
   end
  end
 end
end

local function P()
 while true do
  C()
  T(3,"PASSWORD SETTINGS")
  T(5,"CURRENT PASSWORD")
  term.setCursorPos(1,6)
  local o=read("*")

  if o~=D(c.admin_password) then
   T(9,"CURRENT PASSWORD INVALID")
   sleep(2)
   return
  end

  C()
  T(3,"PASSWORD SETTINGS")
  T(5,"NEW PASSWORD")
  term.setCursorPos(1,6)
  local n=read()

  if not n or n=="" then
   T(9,"PASSWORD CANNOT BE EMPTY")
   sleep(2)
   return
  end

  C()
  T(3,"PASSWORD SETTINGS")
  T(5,"CONFIRM NEW PASSWORD")
  term.setCursorPos(1,6)
  local r=read()

  if n~=r then
   T(9,"PASSWORDS DO NOT MATCH")
   sleep(2)
   return
  end

  c.admin_password=E(n)

  if V() then
   G("ADMIN PASSWORD UPDATED")
   T(9,"PASSWORD UPDATED")
  else
   T(9,"SAVE FAILED")
  end

  sleep(2)
  return
 end
end

local function A()
 if not Z() then
  H()
  return
 end

 while true do
  C()
  T(2,"ADMINISTRATION")
  T(3,"SYSTEM MANAGEMENT")
  W(6,"[1] BLOCK CONFIGURATION")
  W(7,"[2] PASSWORD SETTINGS")
  W(8,"[3] RESTART COMPUTER")
  W(9,"[4] SHUTDOWN COMPUTER")
  W(10,"[5] EXIT CONTROLLER")
  W(12,"[ESC] BACK")

  local e,k=os.pullEventRaw()

  if e=="terminate" then
   if Z() then return "exit" end

  elseif e=="key" then
   if k==keys.one then
    local r=K()
    if r=="exit" then return "exit" end

   elseif k==keys.two then
    P()

   elseif k==keys.three then
    C()
    T(7,"RESTARTING COMPUTER...")
    sleep(1)
    os.reboot()
    return

   elseif k==keys.four then
    C()
    T(7,"SHUTTING DOWN COMPUTER...")
    sleep(1)
    os.shutdown()
    return

   elseif k==keys.five then
    C()
    T(7,"CONTROLLER EXIT AUTHORIZED")
    sleep(1)
    return "exit"

   elseif k==keys.escape then
    H()
    return
   end
  end
 end
end

local function R()
 C()
 T(3,"TERMINATION REQUEST")
 T(5,"ADMINISTRATOR PASSWORD REQUIRED")
 term.setCursorPos(1,7)
 local p=read("*")

 if p==D(c.admin_password) then
  G("CONTROLLER TERMINATED")
  return true
 end

 T(9,"ACCESS DENIED")
 sleep(2)
 H()
 return false
end

local function Y(s)
 local b=c[s]

 if type(b)~="string" or b=="" then
  G(N[s].." INVALID BLOCK")
  return
 end

 if b=="minecraft:air" then
  G(N[s].." PLACEMENT SKIPPED")
  return
 end

 local ok=pcall(commands.setblock,"~","~-1","~",b)

 if ok then
  G(N[s].." PLACED")
 else
  G(N[s].." PLACEMENT FAILED")
 end
end

G("CONTROLLER ONLINE")
H()

while true do
 local e,a=os.pullEventRaw()

 if e=="terminate" then
  if R() then return end
  H()

 elseif e=="key" and a==keys.m then
  local r=A()
  if r=="exit" then return end
  H()

 elseif e=="redstone" then
  for _,s in ipairs(S) do
   if redstone.getAnalogInput(s)>0 then
    Y(s)

    while redstone.getAnalogInput(s)>0 do
     local q,k=os.pullEventRaw()

     if q=="terminate" then
      if R() then return end
      H()

     elseif q=="key" and k==keys.m then
      local r=A()
      if r=="exit" then return end
      H()
     end
    end
   end
  end
 end
end
