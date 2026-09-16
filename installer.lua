local R="creeperdeveloper/Creeper-Missle-Placement-System"
local B="main"

local F={
    {"startup.lua","/startup.lua"},
    {"block_controller.lua","/block_controller.lua"},
    {"config.lua","/config.lua"},
    {"version.txt","/block_controller.version"}
}

local function u(f)
    return "https://raw.githubusercontent.com/"..R.."/"..B.."/"..f.."?t="..os.epoch("utc")
end

local function c()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

local function m(t,y)
    local w=term.getSize()
    term.setCursorPos(math.max(1,math.floor((w-#t)/2)+1),y)
    term.write(t)
end

local function s(a,b)
    c()
    local _,h=term.getSize()
    local y=math.floor(h/2)
    m(a,y-2)
    m(b,y+1)
end

s("SYSTEM INSTALLER","Initializing...")
sleep(1)

if not http then
    s("INSTALLATION FAILED","HTTP API unavailable")
    sleep(4)
    return
end

for i,v in ipairs(F) do
    s("SYSTEM INSTALLER","Downloading "..v[1].." ["..i.."/"..#F.."]")

    local ok,r=pcall(http.get,u(v[1]))

    if not ok or not r then
        s("INSTALLATION FAILED","Unable to download "..v[1])
        sleep(4)
        return
    end

    local z=r.readAll()
    r.close()

    if not z or z=="" then
        s("INSTALLATION FAILED","Empty file: "..v[1])
        sleep(4)
        return
    end

    local h=fs.open(v[2],"w")

    if not h then
        s("INSTALLATION FAILED","Unable to write "..v[2])
        sleep(4)
        return
    end

    h.write(z)
    h.close()
    sleep(.25)
end

if fs.exists("/installer.lua") then
    fs.delete("/installer.lua")
end

s("INSTALLATION COMPLETE","Rebooting...")
sleep(2)
os.reboot()
