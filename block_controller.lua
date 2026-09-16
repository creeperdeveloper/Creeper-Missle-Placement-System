local c=dofile("/config.lua")

local s={"left","right","front","back","top","bottom"}
local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function d(x)
    x=x:gsub("[^"..b.."=]","")
    local r={}
    for i=1,#x,4 do
        local a=b:find(x:sub(i,i),1,true)
        local z=b:find(x:sub(i+1,i+1),1,true)
        local q=b:find(x:sub(i+2,i+2),1,true)
        local w=b:find(x:sub(i+3,i+3),1,true)

        if a and z then
            local n=(a-1)*262144+(z-1)*4096
            if q then n=n+(q-1)*64 end
            if w then n=n+(w-1) end

            r[#r+1]=string.char(math.floor(n/65536)%256)

            if q then
                r[#r+1]=string.char(math.floor(n/256)%256)
            end

            if w then
                r[#r+1]=string.char(n%256)
            end
        end
    end
    return table.concat(r)
end

local function x()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

local function l(y,t)
    local w=term.getSize()
    term.setCursorPos(1,y)
    term.clearLine()
    if #t>w then t=t:sub(1,w) end
    term.write(t)
end

local function h()
    l(1,"CREEPER MISSILE PLACEMENT SYSTEM")
    l(2,"BLOCK CONTROLLER")
    l(3,"")
end

local function ready()
    x()
    h()
    l(4,"STATUS: RUNNING")
    l(5,"REDSTONE: WAITING")
    l(11,"Press M for management")
end

local function place(q)
    local block=c[q]
    local v=redstone.getAnalogInput(q)

    l(4,"STATUS: RUNNING")
    l(5,"REDSTONE: "..q)
    l(6,"SIGNAL: "..v)
    l(7,"BLOCK: "..tostring(block))

    if type(block)~="string" or block=="" then
        l(8,"PLACEMENT: INVALID BLOCK")
        return
    end

    if block=="minecraft:air" then
        l(8,"PLACEMENT: SKIPPED")
        return
    end

    local ok,e=pcall(commands.setblock,"~","~-1","~",block)

    if ok then
        l(8,"PLACEMENT: SUCCESS")
    else
        l(8,"PLACEMENT: FAILED")
        l(9,tostring(e))
    end
end

local function auth()
    x()
    h()
    l(4,"ADMINISTRATOR AUTHENTICATION")
    l(6,"PASSWORD:")
    term.setCursorPos(1,7)

    return read("*")==d(c.admin_password)
end

local function menu()
    if not auth() then
        l(9,"ACCESS DENIED")
        sleep(2)
        ready()
        return
    end

    while true do
        x()
        h()
        l(4,"ADMINISTRATION")
        l(6,"[1] RESTART COMPUTER")
        l(7,"[2] SHUTDOWN COMPUTER")
        l(8,"[3] EXIT CONTROLLER")
        l(10,"[ESC] BACK")

        local e,k=os.pullEventRaw()

        if e=="key" then
            if k==keys.one then
                x()
                print("RESTARTING COMPUTER...")
                sleep(1)
                os.reboot()
                return

            elseif k==keys.two then
                x()
                print("SHUTTING DOWN COMPUTER...")
                sleep(1)
                os.shutdown()
                return

            elseif k==keys.three then
                x()
                h()
                l(4,"STATUS: STOPPED")
                l(5,"CONTROLLER TERMINATED")
                l(7,"Returning to CraftOS...")
                sleep(1)
                return "exit"

            elseif k==keys.escape then
                ready()
                return
            end
        end
    end
end

local function terminate()
    x()
    h()
    l(4,"TERMINATION REQUEST")
    l(5,"ADMINISTRATOR PASSWORD REQUIRED")
    l(7,"PASSWORD:")
    term.setCursorPos(1,8)

    if read("*")==d(c.admin_password) then
        x()
        h()
        l(4,"STATUS: STOPPED")
        l(5,"ADMINISTRATOR AUTHORIZED")
        l(7,"Returning to CraftOS...")
        sleep(1)
        return true
    end

    l(10,"ACCESS DENIED")
    sleep(2)
    ready()
    return false
end

ready()

while true do
    local e,a=os.pullEventRaw()

    if e=="terminate" then
        terminate()

    elseif e=="key" and a==keys.m then
        if menu()=="exit" then
            return
        end

    elseif e=="redstone" then
        for _,q in ipairs(s) do
            if redstone.getAnalogInput(q)>0 then
                place(q)

                while redstone.getAnalogInput(q)>0 do
                    local e2,a2=os.pullEventRaw()

                    if e2=="terminate" then
                        terminate()
                    elseif e2=="key" and a2==keys.m then
                        if menu()=="exit" then
                            return
                        end
                    end
                end

                ready()
            end
        end
    end
end
