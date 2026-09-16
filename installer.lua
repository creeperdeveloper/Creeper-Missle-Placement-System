local r="creeperdeveloper/Creeper-Missle-Placement-System"
local b="main"
local f={{"startup.lua","/startup.lua"},{"block_controller.lua","/block_controller.lua"},{"config.lua","/config.lua"},{"version.txt","/block_controller.version"}}

local function u(x)return"https://raw.githubusercontent.com/"..r.."/"..b.."/"..x.."?t="..os.epoch("utc")end
local function c()term.setBackgroundColor(colors.white)term.setTextColor(colors.black)term.clear()term.setCursorPos(1,1)end
local function m(x,y)local w=term.getSize()term.setCursorPos(math.max(1,math.floor((w-#x)/2)+1),y)term.write(x)end
local function s(a,z)c()local _,h=term.getSize()local y=math.floor(h/2)m(a,y-2)m(z,y+1)end
local function w(p,x)local h=fs.open(p,"w")if not h then return false end h.write(x)h.close()return true end

s("SYSTEM INSTALLER","Initializing...")
sleep(1)

if not http then s("INSTALLATION FAILED","HTTP API unavailable")sleep(4)return end

for i,v in ipairs(f)do
    s("SYSTEM INSTALLER","Downloading "..v[1].." ["..i.."/"..#f.."]")
    local o,q=pcall(http.get,u(v[1]))
    if not o or not q then s("INSTALLATION FAILED","Unable to download "..v[1])sleep(4)return end
    local x=q.readAll()q.close()
    if not x or x=="" then s("INSTALLATION FAILED","Empty file: "..v[1])sleep(4)return end

    if v[1]=="config.lua" and fs.exists("/config.lua") then
    else
        if not w(v[2],x)then s("INSTALLATION FAILED","Unable to write "..v[2])sleep(4)return end
    end

    sleep(.2)
end

if fs.exists("/installer.lua")then fs.delete("/installer.lua")end
s("INSTALLATION COMPLETE","Rebooting...")
sleep(2)
os.reboot()
