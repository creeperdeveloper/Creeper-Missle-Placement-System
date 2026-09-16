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

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(text, y)
    local width = term.getSize()

    term.setCursorPos(
        math.max(1, math.floor((width - #text) / 2) + 1),
        y
    )

    term.write(text)
end

local function screen(title, status)
    clear()

    local _, height = term.getSize()
    local centerY = math.floor(height / 2)

    center(title, centerY - 2)
    center(status, centerY + 1)
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
    if not http then
        return nil
    end

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
        screen(
            "SYSTEM UPDATE",
            "Downloading " .. file.remote .. " [" .. i .. "/" .. #FILES .. "]"
        )

        if not download(file) then
            screen(
                "UPDATE FAILED",
                "Unable to download " .. file.remote
            )

            sleep(4)
            return false
        end

        sleep(0.2)
    end

    screen(
        "UPDATE COMPLETE",
        "Version " .. remoteVersion
    )

    sleep(2)

    os.reboot()

    return true
end

clear()

screen(
    "CREEPER MISSILE PLACEMENT SYSTEM",
    "Starting..."
)

sleep(1)

if type(commands) ~= "table" then
    screen(
        "SYSTEM ERROR",
        "Command Computer required"
    )

    sleep(4)
    return
end

if type(commands.setblock) ~= "function" then
    screen(
        "SYSTEM ERROR",
        "commands.setblock unavailable"
    )

    sleep(4)
    return
end

if not fs.exists("/block_controller.lua") then
    screen(
        "SYSTEM ERROR",
        "block_controller.lua not found"
    )

    sleep(4)
    return
end

if not fs.exists("/config.lua") then
    screen(
        "SYSTEM ERROR",
        "config.lua not found"
    )

    sleep(4)
    return
end

if http then
    local localVersion = readLocalVersion()
    local remoteVersion = getRemoteVersion()

    if remoteVersion and remoteVersion ~= localVersion then
        if not updateSystem(remoteVersion) then
            return
        end

        return
    end
end

screen(
    "CREEPER MISSILE PLACEMENT SYSTEM",
    "Starting controller..."
)

sleep(1)

local success, result = pcall(
    shell.run,
    "/block_controller.lua"
)

if not success then
    screen(
        "CONTROLLER ERROR",
        tostring(result)
    )

    sleep(5)
end
