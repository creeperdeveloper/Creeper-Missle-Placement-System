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
    term.clear()
    term.setCursorPos(1, 1)
end

local function status(message)
    clear()

    print("BLOCK CONTROLLER INSTALLER")
    print("--------------------------")
    print()
    print(message)
end

local function fail(message)
    clear()

    print("INSTALLATION FAILED")
    print("-------------------")
    print()
    print(message)
    print()
    print("Press any key to exit.")

    os.pullEvent("key")
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
        return false, "The downloaded file is empty."
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
    if not http then
        fail(
            "HTTP API is disabled.\n\n" ..
            "Enable HTTP in CC:Tweaked settings."
        )

        return
    end

    if not http.checkURL("https://raw.githubusercontent.com") then
        fail(
            "GitHub is not allowed by the HTTP API."
        )

        return
    end

    if REPOSITORY:find("YOUR_GITHUB_USERNAME", 1, true) then
        fail(
            "Edit REPOSITORY in installer.lua first."
        )

        return
    end

    status("Preparing installation...")

    sleep(0.5)

    for _, item in ipairs(FILES) do
        status(
            "Downloading " ..
            item.remote ..
            "..."
        )

        local ok, err =
            download(
                item.remote,
                item.localPath
            )

        if not ok then
            fail(
                "Failed to download:\n\n" ..
                item.remote ..
                "\n\n" ..
                err
            )

            return
        end

        sleep(0.2)
    end

    status("Verifying installation...")

    sleep(0.5)

    for _, item in ipairs(FILES) do
        if not fs.exists(item.localPath) then
            fail(
                "Missing installed file:\n" ..
                item.localPath
            )

            return
        end
    end

    fs.delete("/installer.lua")

    status("Installation complete.")

    print()
    print("Installed files:")
    print()

    for _, item in ipairs(FILES) do
        print(
            "  [OK] " ..
            item.localPath
        )
    end

    print()
    print("The computer will reboot in 3 seconds.")

    sleep(3)

    os.reboot()
end

install()
