local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"

local BRANCH = "main"

local CURRENT_VERSION_FILE =
    "/block_controller.version"

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(text, y)
    local width, height = term.getSize()

    local x =
        math.floor((width - #text) / 2) + 1

    term.setCursorPos(x, y)
    term.write(text)
end

local function lockedScreen()
    clear()

    local _, height = term.getSize()

    center(
        "SYSTEM LOCKED",
        math.floor(height / 2)
    )
end

local function messageScreen(title, message)
    clear()

    local _, height = term.getSize()

    center(
        title,
        math.floor(height / 2) - 2
    )

    center(
        message,
        math.floor(height / 2)
    )
end

local function isCommandComputer()
    return commands ~= nil
end

local function getLocalVersion()
    if not fs.exists(
        CURRENT_VERSION_FILE
    ) then
        return nil
    end

    local file =
        fs.open(
            CURRENT_VERSION_FILE,
            "r"
        )

    if not file then
        return nil
    end

    local version =
        file.readAll()

    file.close()

    if not version then
        return nil
    end

    return version:gsub("%s+", "")
end

local function getRemoteVersion()
    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/version.txt"

    local response =
        http.get(url)

    if not response then
        return nil
    end

    local version =
        response.readAll()

    response.close()

    if not version then
        return nil
    end

    return version:gsub("%s+", "")
end

local function download(remote, localPath)
    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. remote

    local response =
        http.get(url)

    if not response then
        return false
    end

    local content =
        response.readAll()

    response.close()

    if not content or #content == 0 then
        return false
    end

    local file =
        fs.open(
            localPath,
            "w"
        )

    if not file then
        return false
    end

    file.write(content)
    file.close()

    return true
end

local function update()
    messageScreen(
        "UPDATE REQUIRED",
        "Installing latest system..."
    )

    sleep(1)

    local files = {
        {
            "startup.lua",
            "/startup.lua"
        },
        {
            "block_controller.lua",
            "/block_controller.lua"
        },
        {
            "config.lua",
            "/config.lua"
        },
        {
            "version.txt",
            "/block_controller.version"
        }
    }

    for _, file in ipairs(files) do
        local ok =
            download(
                file[1],
                file[2]
            )

        if not ok then
            messageScreen(
                "UPDATE FAILED",
                "System update could not complete."
            )

            sleep(3)

            return false
        end
    end

    messageScreen(
        "UPDATE COMPLETE",
        "Restarting system..."
    )

    sleep(2)

    os.reboot()

    return true
end

local function startController()
    while true do
        if not fs.exists(
            "/block_controller.lua"
        ) then

            messageScreen(
                "SYSTEM ERROR",
                "Controller is missing."
            )

            while true do
                os.pullEventRaw()
            end
        end

        local ok =
            pcall(function()
                shell.run(
                    "/block_controller.lua"
                )
            end)

        if not ok then
            sleep(1)
        end

        lockedScreen()
    end
end

local function main()
    if not isCommandComputer() then
        messageScreen(
            "SYSTEM LOCKED",
            "Command Computer required."
        )

        while true do
            os.pullEventRaw()
        end
    end

    lockedScreen()

    if not http then
        startController()
        return
    end

    if not http.checkURL(
        "https://raw.githubusercontent.com"
    ) then
        startController()
        return
    end

    local localVersion =
        getLocalVersion()

    local remoteVersion =
        getRemoteVersion()

    if remoteVersion
        and localVersion ~= remoteVersion
    then
        update()
        return
    end

    startController()
end

main()
