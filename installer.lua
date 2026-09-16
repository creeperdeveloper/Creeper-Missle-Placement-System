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

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(text, y)
    local width, height = term.getSize()

    local x = math.floor((width - #text) / 2) + 1

    term.setCursorPos(x, y)
    term.write(text)
end

local function show(message)
    clear()

    local _, height = term.getSize()

    center("SYSTEM INSTALLER", math.floor(height / 2) - 2)
    center(message, math.floor(height / 2))
end

local function errorScreen(message)
    clear()

    local _, height = term.getSize()

    center("INSTALLATION ERROR", math.floor(height / 2) - 2)
    center(message, math.floor(height / 2))
    center("Press any key to exit", math.floor(height / 2) + 2)

    os.pullEvent("key")
end

local function isCommandComputer()
    return commands ~= nil
end

local function download(remote, localPath)
    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. remote

    local response, err = http.get(url)

    if not response then
        return false, tostring(err or "HTTP request failed")
    end

    local content = response.readAll()

    response.close()

    if not content or #content == 0 then
        return false, "Downloaded file is empty."
    end

    local file = fs.open(localPath, "w")

    if not file then
        return false, "Cannot write " .. localPath
    end

    file.write(content)
    file.close()

    return true
end

local function install()
    if not isCommandComputer() then
        errorScreen(
            "This system requires a Command Computer."
        )
        return
    end

    if not http then
        errorScreen(
            "HTTP API is disabled."
        )
        return
    end

    if not http.checkURL(
        "https://raw.githubusercontent.com"
    ) then
        errorScreen(
            "GitHub HTTP access is disabled."
        )
        return
    end

    if REPOSITORY:find(
        "YOUR_GITHUB_USERNAME",
        1,
        true
    ) then
        errorScreen(
            "Configure the GitHub repository first."
        )
        return
    end

    clear()

    local _, height = term.getSize()

    center(
        "SYSTEM INSTALLER",
        math.floor(height / 2) - 4
    )

    center(
        "Preparing installation...",
        math.floor(height / 2) - 2
    )

    sleep(1)

    for _, item in ipairs(FILES) do
        show(
            "Downloading " ..
            item.remote
        )

        local ok, err =
            download(
                item.remote,
                item.localPath
            )

        if not ok then
            errorScreen(
                item.remote ..
                ": " ..
                err
            )

            return
        end

        sleep(0.3)
    end

    show("Verifying installation...")

    sleep(1)

    for _, item in ipairs(FILES) do
        if not fs.exists(item.localPath) then
            errorScreen(
                "Missing file: " ..
                item.localPath
            )

            return
        end
    end

    fs.delete("/installer.lua")

    show("Installation complete.")

    sleep(2)

    os.reboot()
end

install()
