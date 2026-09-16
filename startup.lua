local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"
local BRANCH = "main"

local VERSION_FILE = "/block_controller.version"

local FILES = {
    {
        remote = "startup.lua",
        localPath = "/startup.lua"
    },
    {
        remote = "block_controller.lua",
        localPath = "/block_controller.lua"
    },
    {
        remote = "config.lua",
        localPath = "/config.lua"
    },
    {
        remote = "version.txt",
        localPath = "/block_controller.version"
    }
}

local function center(text, y)
    local width = term.getSize()

    term.setCursorPos(
        math.max(1, math.floor((width - #text) / 2) + 1),
        y
    )

    term.write(text)
end

local function lockedScreen(message)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local _, height = term.getSize()

    center(message, math.floor(height / 2))

    while true do
        os.pullEventRaw()
    end
end

local function systemScreen(title, status)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()

    local _, height = term.getSize()

    center(title, math.floor(height / 2) - 2)
    center(status, math.floor(height / 2) + 1)
end

local function getUrl(file)
    return "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. file
        .. "?t="
        .. tostring(os.epoch("utc"))
end

local function readLocalVersion()
    if not fs.exists(VERSION_FILE) then
        return nil
    end

    local handle = fs.open(VERSION_FILE, "r")

    if not handle then
        return nil
    end

    local version = handle.readAll()
    handle.close()

    if not version then
        return nil
    end

    version = version:gsub("^%s+", "")
    version = version:gsub("%s+$", "")

    if version == "" then
        return nil
    end

    return version
end

local function getRemoteVersion()
    local success, response = pcall(
        http.get,
        getUrl("version.txt")
    )

    if not success or not response then
        return nil
    end

    local version = response.readAll()
    response.close()

    if not version then
        return nil
    end

    version = version:gsub("^%s+", "")
    version = version:gsub("%s+$", "")

    if version == "" then
        return nil
    end

    return version
end

local function download(file)
    local success, response = pcall(
        http.get,
        getUrl(file.remote)
    )

    if not success or not response then
        return false
    end

    local content = response.readAll()
    response.close()

    if not content or content == "" then
        return false
    end

    local handle = fs.open(file.localPath, "w")

    if not handle then
        return false
    end

    handle.write(content)
    handle.close()

    return true
end

local function updateSystem(remoteVersion)
    for i, file in ipairs(FILES) do
        systemScreen(
            "SYSTEM UPDATE",
            "Downloading " .. file.remote .. "  [" .. i .. "/" .. #FILES .. "]"
        )

        if not download(file) then
            systemScreen(
                "UPDATE FAILED",
                "Unable to download " .. file.remote
            )

            sleep(4)
            return false
        end

        sleep(0.25)
    end

    systemScreen(
        "UPDATE COMPLETE",
        "Installed version " .. remoteVersion
    )

    sleep(2)

    os.reboot()
end

if type(commands) ~= "table"
    or type(commands.setblock) ~= "function" then

    lockedScreen("SYSTEM LOCKED")
end

if not fs.exists("/config.lua") then
    lockedScreen("CONFIG NOT FOUND")
end

if not fs.exists("/block_controller.lua") then
    lockedScreen("CONTROLLER NOT FOUND")
end

if http then
    local localVersion = readLocalVersion()
    local remoteVersion = getRemoteVersion()

    if remoteVersion
        and remoteVersion ~= localVersion then

        updateSystem(remoteVersion)
    end
end

local config = dofile("/config.lua")

local sides = {
    "left",
    "right",
    "front",
    "back",
    "top",
    "bottom"
}

term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()

while true do
    for _, side in ipairs(sides) do
        if redstone.getAnalogInput(side) > 0 then
            local block = config[side]

            if type(block) == "string"
                and block ~= ""
                and block ~= "minecraft:air" then

                commands.setblock(
                    "~",
                    "~-1",
                    "~",
                    block
                )

                while redstone.getAnalogInput(side) > 0 do
                    sleep(0.05)
                end
            end
        end
    end

    sleep(0.05)
end
