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

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(text, y)
    local width = term.getSize()
    local x = math.floor((width - #text) / 2) + 1

    if x < 1 then
        x = 1
    end

    term.setCursorPos(x, y)
    term.write(text)
end

local function isCommandComputer()
    return type(commands) == "table"
        and type(commands.setblock) == "function"
end

local function readFile(path)
    if not fs.exists(path) then
        return nil
    end

    local file = fs.open(path, "r")

    if not file then
        return nil
    end

    local content = file.readAll()
    file.close()

    if not content then
        return nil
    end

    return content:gsub("%s+", "")
end

local function writeFile(path, content)
    local file = fs.open(path, "w")

    if not file then
        return false
    end

    file.write(content)
    file.close()

    return true
end

local function download(remote)
    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. remote
        .. "?v="
        .. tostring(os.epoch("utc"))

    local ok, response = pcall(http.get, url)

    if not ok or not response then
        return nil
    end

    local content = response.readAll()
    response.close()

    if not content or #content == 0 then
        return nil
    end

    return content
end

local function showError(title, message)
    clear()

    local _, height = term.getSize()

    center(title, math.floor(height / 2) - 2)
    center(message, math.floor(height / 2))
    center("Press any key to reboot.", math.floor(height / 2) + 2)

    os.pullEvent("key")
    os.reboot()
end

local function updateSystem()
    clear()

    local _, height = term.getSize()

    center("SYSTEM UPDATE", math.floor(height / 2) - 3)
    center("Downloading latest system...", math.floor(height / 2) - 1)

    local downloaded = {}

    for i, file in ipairs(FILES) do
        local content = download(file.remote)

        if not content then
            showError(
                "UPDATE FAILED",
                "Failed: " .. file.remote
            )
        end

        downloaded[i] = {
            path = file.localPath,
            content = content
        }

        clear()

        center("SYSTEM UPDATE", math.floor(height / 2) - 3)
        center(
            "Downloading " .. file.remote,
            math.floor(height / 2) - 1
        )

        center(
            tostring(i) .. " / " .. tostring(#FILES),
            math.floor(height / 2) + 1
        )

        sleep(0.3)
    end

    clear()

    center(
        "SYSTEM UPDATE",
        math.floor(height / 2) - 3
    )

    center(
        "Installing update...",
        math.floor(height / 2) - 1
    )

    for _, file in ipairs(downloaded) do
        local temporary = file.path .. ".update"

        if not writeFile(temporary, file.content) then
            showError(
                "UPDATE FAILED",
                "Failed to write " .. file.path
            )
        end
    end

    for _, file in ipairs(downloaded) do
        local temporary = file.path .. ".update"

        if fs.exists(file.path) then
            fs.delete(file.path)
        end

        fs.move(temporary, file.path)
    end

    clear()

    center(
        "UPDATE COMPLETE",
        math.floor(height / 2) - 1
    )

    center(
        "Restarting system...",
        math.floor(height / 2) + 1
    )

    sleep(2)

    os.reboot()
end

local function checkUpdate()
    if not http then
        return false
    end

    local remoteVersion = download("version.txt")

    if not remoteVersion then
        return false
    end

    remoteVersion = remoteVersion:gsub("%s+", "")

    local localVersion = readFile(VERSION_FILE)

    if not localVersion then
        return true
    end

    return localVersion ~= remoteVersion
end

local function runController()
    clear()

    if not fs.exists("/block_controller.lua") then
        showError(
            "SYSTEM ERROR",
            "block_controller.lua not found."
        )
    end

    if not fs.exists("/config.lua") then
        showError(
            "SYSTEM ERROR",
            "config.lua not found."
        )
    end

    local ok, errorMessage = pcall(function()
        dofile("/block_controller.lua")
    end)

    if not ok then
        clear()

        local _, height = term.getSize()

        center(
            "SYSTEM ERROR",
            math.floor(height / 2) - 2
        )

        center(
            tostring(errorMessage),
            math.floor(height / 2)
        )

        center(
            "Press any key to reboot.",
            math.floor(height / 2) + 2
        )

        os.pullEvent("key")
        os.reboot()
    end
end

local function main()
    clear()

    if not isCommandComputer() then
        center(
            "SYSTEM LOCKED",
            math.floor(select(2, term.getSize()) / 2)
        )

        while true do
            os.pullEventRaw()
        end
    end

    if http then
        local needsUpdate = checkUpdate()

        if needsUpdate then
            updateSystem()
            return
        end
    end

    runController()
end

main()
