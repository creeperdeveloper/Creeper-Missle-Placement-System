local r="creeperdeveloper/Creeper-Missle-Placement-System"
local b="main"
local v="/block_controller.version"
local f={{"startup.lua","/startup.lua"},{"block_controller.lua","/block_controller.lua"},{"version.txt","/block_controller.version"}}

local function u(x)return"https://raw.githubusercontent.com/"..r.."/"..b.."/"..x.."?t="..os.epoch("utc")end
local function c()term.setBackgroundColor(colors.white)term.setTextColor(colors.black)term.clear()term.setCursorPos(1,1)end
local function m(x,y)local w=term.getSize()term.setCursorPos(math.max(1,math.floor((w-#x)/2)+1),y)term.write(x)end

local function rv()
    if not fs.exists(v)then return nil end
    local h=fs.open(v,"r")if not h then return nil end
    local x=h.readAll()h.close()
    if not x then return nil end
    return x:gsub("^%s+",""):gsub("%s+$","")
end

local function gv()
    if not http then return nil end
    local o,q=pcall(http.get,u("version.txt"))
    if not o or not q then return nil end
    local x=q.readAll()q.close()
    if not x then return nil end
    return x:gsub("^%s+",""):gsub("%s+$","")
end

local function dl(x,p)
    local o,q=pcall(http.get,u(x))
    if not o or not q then return false end
    local z=q.readAll()q.close()
    if not z or z==""then return false end
    local h=fs.open(p,"w")
    if not h then return false end
    h.write(z)h.close()
    return true
end

c()
m("CREEPER MISSILE PLACEMENT SYSTEM",math.floor(term.getSize()/2)-3)
m("BOOTING...",math.floor(term.getSize()/2))
sleep(.7)

if type(commands)~="table"or type(commands.setblock)~="function"then
    c()
    m("SYSTEM ERROR",math.floor(term.getSize()/2)-1)
    m("COMMAND COMPUTER REQUIRED",math.floor(term.getSize()/2)+1)
    sleep(4)
    return
end

if not fs.exists("/block_controller.lua")then
    c()
    m("SYSTEM ERROR",math.floor(term.getSize()/2)-1)
    m("CONTROLLER NOT FOUND",math.floor(term.getSize()/2)+1)
    sleep(4)
    return
end

if not fs.exists("/config.lua")then
    c()
    m("SYSTEM ERROR",math.floor(term.getSize()/2)-1)
    m("CONFIG NOT FOUND",math.floor(term.getSize()/2)+1)
    sleep(4)
    return
end

if http then
    local a=rv()
    local z=gv()

    if z and z~=a then
        c()
        m("SYSTEM UPDATE",math.floor(term.getSize()/2)-2)
        m("UPDATING TO "..z,math.floor(term.getSize()/2))

        for _,q in ipairs(f)do
            if not dl(q[1],q[2])then
                c()
                m("UPDATE FAILED",math.floor(term.getSize()/2)-1)
                m(q[1],math.floor(term.getSize()/2)+1)
                sleep(4)
                return
            end
        end

        sleep(1)
        os.reboot()
        return
    end
end

local e=setmetatable({},{__index=_ENV})
local o,q=os.run(e,"/block_controller.lua")

if not o then
    c()
    m("CONTROLLER ERROR",math.floor(term.getSize()/2)-1)
    m(tostring(q),math.floor(term.getSize()/2)+1)
    sleep(5)
end
