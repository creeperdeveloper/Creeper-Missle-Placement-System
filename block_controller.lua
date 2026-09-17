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
  local a=s:byte(i) or 0
  local b=s:byte(i+1)
  local c=s:byte(i+2)
  local n=a*65536+(b or 0)*256+(c or 0)
  r=r..t:sub(math.floor(n/262144)%64+1,math.floor(n/262144)%64+1)
  r=r..t:sub(math.floor(n/4096)%64+1,math.floor(n/4096)%64+1)
  if b then
   r=r..t:sub(math.floor(n/64)%64+1,math.floor(n/64)%64+1)
  else
   r=r.."="
  end
  if c then
   r=r..t:sub(n%64+1,n%64+1)
  else
   r=r.."="
  end
  i=i+3
 end
 return r
end

local function addLog(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..s)
 while #logs>3 do
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
 local x=math.floor((w-#s)/2)+1
 if x<1 then x=1 end
 term.setCursorPos(x,y)
 write(s)
end

local function input(mask)
 local w,h=term.getSize()
 local text=""
 local sx,sy=term.getCursorPos()

 term.setCursorPos(sx,sy)
 write(string.rep(" ",math.max(0,w-sx+1)))
 term.setCursorPos(sx,sy)

 while true do
  local event,a=os.pullEventRaw()

  if event=="char" then
   text=text..a
   if mask then
    write("*")
   else
    write(a)
   end

  elseif event=="paste" then
   text=text..a
   if mask then
    write(string.rep("*",#a))
   else
    write(a)
   end

  elseif event=="key" then
   if a==keys.enter then
    return text
   elseif a==keys.backspace then
    if #text>0 then
     text=text:sub(1,#text-1)
     term.setCursorPos(sx,sy)
     write(string.rep(" ",math.max(0,w-sx+1)))
     term.setCursorPos(sx,sy)

     if mask then
      write(string.rep("*",#text))
     else
      write(text)
     end

     term.setCursorPos(sx+#text,sy)
    end
   end

  elseif event=="terminate" then
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
 if d=="north" then return vector.new(0,0,-1) end
 if d=="south" then return vector.new(0,0,1) end
 if d=="east" then return vector.new(1,0,0) end
 if d=="west" then return vector.new(-1,0,0) end
 if d=="up" then return vector.new(0,1,0) end
 if d=="down" then return vector.new(0,-1,0) end
 return vector.new(0,0,-1)
end

local function vectorFacing(v)
 local x=v.x or 0
 local y=v.y or 0
 local z=v.z or 0

 local ax=math.abs(x)
 local ay=math.abs(y)
 local az=math.abs(z)

 if ay>=ax and ay>=az then
  if y>=0 then return"up" else return"down" end
 end

 if ax>=az then
  if x>=0 then return"east" else return"west" end
 end

 if z>=0 then return"south" else return"north" end
end

local function getFacing()
 local lf=localFacing()

 if type(sublevel)=="table" and type(sublevel.isInPlotGrid)=="function" then
  local ok,inLevel=pcall(sublev
