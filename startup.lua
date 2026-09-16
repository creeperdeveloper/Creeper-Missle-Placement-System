local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"
local BRANCH = "main"

local LOCAL_VERSION = "/block_controller.version"

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

local function locked()
    clear()

    local _, height = term.getSize()

    center(
        "SYSTEM LOCKED",
        math.floor(height / 2)
    )
end

local function errorScreen(title, message)
    clear()

    local _, height = term.getSize()

    center(title, math.floor(height / 2) - 2)
    center(message, math.floor(height / 2))
    center("Press any key to continue.", math.floor(height / 2) + 2)

    os.pullEvent("key")
end

local function isCommandComputer()
    return type(commands) == "table"
        and type(commands.exec) == "function"
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

local function download(remote)
    local cacheBuster = tostring(os.epoch("utc"))

    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. remote
        .. "?v="
        .. cacheBuster

    local response = http.get(url)

    if not response then
        return nil
    end

    local content = response.readAll()
    response.close()

    if not content or #content == 0 then
        return nil
    end

    return content
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

local function update()
    clear()

    local _, height = term.getSize()

    center(
        "UPDATE REQUIRED",
        math.floor(height / 2) - 2
    )

    center(
        "Downloading latest system...",
        math.floor(height / 2)
    )

    sleep(1)

    local downloaded = {}

    for _, file in ipairs(FILES) do
        local content = download(file.remote)

        if not content then
            errorScreen(
                "UPDATE FAILED",
                "Could not download " .. file.remote
            )

            return false
        end

        downloaded[#downloaded + 1] = {
            path = file.localPath,
            content = content
        }
    end

    clear()

    center(
        "UPDATE REQUIRED",
        math.floor(height / 2) - 2
    )

    center(
        "Installing update...",
        math.floor(height / 2)
    )

    sleep(1)

    for _, file in ipairs(downloaded) do
        local temporary = file.path .. ".update"

        if not writeFile(temporary, file.content) then
            for _, cleanup in ipairs(downloaded) do
                local cleanupPath = cleanup.path .. ".update"

                if fs.exists(cleanupPath) then
                    fs.delete(cleanupPath)
                end
            end

            errorScreen(
                "UPDATE FAILED",
                "Could not write system files."
            )

            return false
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
        math.floor(height / 2) - 2
    )

    center(
        "Restarting system...",
        math.floor(height / 2)
    )

    sleep(2)

    os.reboot()

    return true
end

local function runController()
    if not fs.exists("/block_controller.lua") then
        errorScreen(
            "SYSTEM ERROR",
            "Controller is missing."
        )

        return
    end

    if not fs.exists("/config.lua") then
        errorScreen(
            "SYSTEM ERROR",
            "Configuration is missing."
        )

        return
    end

    local ok, errorMessage = pcall(function()
        dofile("/block_controller.lua")
    end)

    if not ok then
        errorScreen(
            "SYSTEM ERROR",
            tostring(errorMessage)
        )
    end
end

local function checkForUpdate()
    local localVersion = readFile(LOCAL_VERSION)

    local remoteContent = download("version.txt")

    if not remoteContent then
        return false, "GitHub version unavailable"
    end

    local remoteVersion = remoteContent:gsub("%s+", "")

    if not localVersion then
        return true, remoteVersion
    end

    if localVersion ~= remoteVersion then
        return true, remoteVersion
    end

    return false, remoteVersion
end

local function main()
    locked()

    if not isCommandComputer() then
        errorScreen(
            "SYSTEM LOCKED",
            "Command Computer required."
        )

        return
    end

    if not http then
        runController()
        return
    end

    local success, needsUpdateOrError, remoteVersion =
        pcall(checkForUpdate)

    if not success then
        runController()
        return
    end

    if needsUpdateOrError == true then
        update()
        return
    end

    runController()
end

main()
