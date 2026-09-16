local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"
local BRANCH = "main"

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

local function fail(message)
    screen("INSTALLATION FAILED", message)
    sleep(4)
end

screen(
    "SYSTEM INSTALLER",
    "Initializing..."
)

sleep(1)

if not http then
    fail("HTTP API unavailable")
    return
end

for i, file in ipairs(FILES) do
    screen(
        "SYSTEM INSTALLER",
        "Downloading " .. file.remote .. " [" .. i .. "/" .. #FILES .. "]"
    )

    local success, response = pcall(
        http.get,
        getUrl(file.remote)
    )

    if not success or not response then
        fail("Unable to download " .. file.remote)
        return
    end

    local content = response.readAll()
    response.close()

    if not content or content == "" then
        fail("Empty file: " .. file.remote)
        return
    end

    local handle = fs.open(file.localPath, "w")

    if not handle then
        fail("Unable to write " .. file.localPath)
        return
    end

    handle.write(content)
    handle.close()

    sleep(0.25)
end

screen(
    "INSTALLATION COMPLETE",
    "System files installed"
)

sleep(2)

if fs.exists("/installer.lua") then
    fs.delete("/installer.lua")
end

screen(
    "SYSTEM READY",
    "Rebooting..."
)

sleep(2)

os.reboot()
