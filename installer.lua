local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"

local BRANCH = "main"

local VERSION = "1.0.0"

local FILES = {
    {
        remote = "startup.lua",
        localPath = "/startup.lua",
        name = "System Startup",
        size = "CORE"
    },
    {
        remote = "block_controller.lua",
        localPath = "/block_controller.lua",
        name = "Block Controller",
        size = "CORE"
    },
    {
        remote = "config.lua",
        localPath = "/config.lua",
        name = "Configuration",
        size = "CONFIG"
    },
    {
        remote = "version.txt",
        localPath = "/block_controller.version",
        name = "Version Information",
        size = "META"
    }
}

local WIDTH, HEIGHT = term.getSize()

local downloaded = 0
local currentFile = ""
local currentStatus = "Preparing installation..."

local function center(text, y)
    local x = math.floor((WIDTH - #text) / 2) + 1

    if x < 1 then
        x = 1
    end

    term.setCursorPos(x, y)
    term.write(text)
end

local function fillLine(y, char)
    term.setCursorPos(1, y)
    term.write(string.rep(char, WIDTH))
end

local function box(x1, y1, x2, y2)
    term.setCursorPos(x1, y1)
    term.write("+" .. string.rep("-", x2 - x1 - 1) .. "+")

    for y = y1 + 1, y2 - 1 do
        term.setCursorPos(x1, y)
        term.write("|")

        term.setCursorPos(x2, y)
        term.write("|")
    end

    term.setCursorPos(x1, y2)
    term.write("+" .. string.rep("-", x2 - x1 - 1) .. "+")
end

local function progressBar(current, total, width)
    if total <= 0 then
        return string.rep(".", width)
    end

    local filled = math.floor((current / total) * width)

    if filled > width then
        filled = width
    end

    return string.rep("#", filled)
        .. string.rep("-", width - filled)
end

local function drawHeader()
    term.clear()

    fillLine(1, "=")

    center("BLOCK CONTROLLER", 2)
    center("System Installation", 3)

    fillLine(4, "=")
end

local function drawInstaller()
    drawHeader()

    term.setCursorPos(3, 6)
    term.write("Installing Block Controller")

    term.setCursorPos(3, 7)
    term.write("Version " .. VERSION)

    box(3, 9, WIDTH - 2, 14)

    term.setCursorPos(5, 10)
    term.write("STATUS")

    term.setCursorPos(5, 11)
    term.write(currentStatus)

    term.setCursorPos(5, 12)

    local barWidth = WIDTH - 10
    local bar = progressBar(
        downloaded,
        #FILES,
        barWidth
    )

    term.write("[" .. bar .. "]")

    term.setCursorPos(5, 13)
    term.write(
        tostring(downloaded)
        .. " / "
        .. tostring(#FILES)
        .. " components"
    )

    term.setCursorPos(3, 16)
    term.write("COMPONENTS")

    local y = 17

    for i, file in ipairs(FILES) do
        if y <= HEIGHT - 3 then
            term.setCursorPos(4, y)

            if i <= downloaded then
                term.write("[OK] ")
            elseif file.remote == currentFile then
                term.write("[..] ")
            else
                term.write("[--] ")
            end

            term.write(file.name)

            local right = file.size

            local rightX =
                WIDTH - #right - 3

            if rightX > 25 then
                term.setCursorPos(rightX, y)
                term.write(right)
            end

            y = y + 1
        end
    end

    fillLine(HEIGHT - 1, "-")

    term.setCursorPos(3, HEIGHT)
    term.write("BLOCK CONTROLLER INSTALLER")

    term.setCursorPos(
        WIDTH - 13,
        HEIGHT
    )

    term.write("SYSTEM SETUP")
end

local function drawWelcome()
    term.clear()

    fillLine(1, "=")

    center("BLOCK CONTROLLER", 2)
    center("Installation Wizard", 3)

    fillLine(4, "=")

    term.setCursorPos(4, 7)
    term.write("Welcome")

    term.setCursorPos(4, 9)
    term.write(
        "This computer will be configured"
    )

    term.setCursorPos(4, 10)
    term.write(
        "as a dedicated Block Controller."
    )

    term.setCursorPos(4, 12)
    term.write(
        "The installer will download:"
    )

    term.setCursorPos(6, 14)
    term.write("[*] System Startup")

    term.setCursorPos(6, 15)
    term.write("[*] Block Controller")

    term.setCursorPos(6, 16)
    term.write("[*] Configuration")

    term.setCursorPos(6, 17)
    term.write("[*] Version Information")

    term.setCursorPos(4, 20)
    term.write(
        "After installation, the computer"
    )

    term.setCursorPos(4, 21)
    term.write(
        "will automatically restart."
    )

    fillLine(HEIGHT - 2, "-")

    center(
        "Starting installation...",
        HEIGHT - 1
    )

    sleep(2)
end

local function drawComplete()
    term.clear()

    fillLine(1, "=")

    center("BLOCK CONTROLLER", 2)
    center("Installation Complete", 3)

    fillLine(4, "=")

    term.setCursorPos(4, 7)
    term.write("Installation successful.")

    term.setCursorPos(4, 9)
    term.write("All system components are ready.")

    box(4, 11, WIDTH - 3, 17)

    term.setCursorPos(6, 12)
    term.write("[OK] System Startup")

    term.setCursorPos(6, 13)
    term.write("[OK] Block Controller")

    term.setCursorPos(6, 14)
    term.write("[OK] Configuration")

    term.setCursorPos(6, 15)
    term.write("[OK] Version Information")

    term.setCursorPos(6, 16)
    term.write("[OK] Startup Configuration")

    term.setCursorPos(4, 19)
    term.write("System will restart automatically.")

    center(
        "Restarting...",
        HEIGHT - 2
    )

    fillLine(HEIGHT, "=")
end

local function drawError(message)
    term.clear()

    fillLine(1, "=")

    center("BLOCK CONTROLLER", 2)
    center("Installation Error", 3)

    fillLine(4, "=")

    term.setCursorPos(4, 7)
    term.write("The installation could not continue.")

    term.setCursorPos(4, 9)
    term.write("ERROR:")

    local maxWidth = WIDTH - 8

    local text = tostring(message)

    local line = ""
    local y = 10

    for word in text:gmatch("%S+") do
        if #line + #word + 1 > maxWidth then
            term.setCursorPos(4, y)
            term.write(line)

            y = y + 1
            line = word
        else
            if line == "" then
                line = word
            else
                line = line .. " " .. word
            end
        end
    end

    if line ~= "" then
        term.setCursorPos(4, y)
        term.write(line)
    end

    term.setCursorPos(4, y + 3)
    term.write("Check your GitHub repository.")

    term.setCursorPos(4, y + 4)
    term.write("Check that HTTP access is enabled.")

    fillLine(HEIGHT - 2, "-")

    center(
        "Press any key to exit",
        HEIGHT - 1
    )

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

    local response, err =
        http.get(url)

    if not response then
        return false,
            tostring(
                err or
                "HTTP request failed"
            )
    end

    local content =
        response.readAll()

    response.close()

    if not content or #content == 0 then
        return false,
            "The downloaded file is empty."
    end

    local file =
        fs.open(localPath, "w")

    if not file then
        return false,
            "Cannot write " ..
            localPath
    end

    file.write(content)
    file.close()

    return true
end

local function validate()
    if not http then
        return false,
            "HTTP API is disabled."
    end

    if not http.checkURL(
        "https://raw.githubusercontent.com"
    ) then
        return false,
            "GitHub is not allowed by HTTP API."
    end

    if REPOSITORY:find(
        "YOUR_GITHUB_USERNAME",
        1,
        true
    ) then
        return false,
            "REPOSITORY has not been configured."
    end

    return true
end

local function install()
    local valid, errorMessage =
        validate()

    if not valid then
        drawError(errorMessage)
        return
    end

    drawWelcome()

    for i, file in ipairs(FILES) do
        currentFile = file.remote

        currentStatus =
            "Downloading " ..
            file.remote

        drawInstaller()

        local ok, err =
            download(
                file.remote,
                file.localPath
            )

        if not ok then
            drawError(
                file.remote ..
                ": " ..
                err
            )

            return
        end

        downloaded = i

        currentStatus =
            "Installed " ..
            file.name

        drawInstaller()

        sleep(0.35)
    end

    currentStatus =
        "Verifying installation..."

    drawInstaller()

    sleep(1)

    for _, file in ipairs(FILES) do
        if not fs.exists(
            file.localPath
        ) then
            drawError(
                "Missing installed file: " ..
                file.localPath
            )

            return
        end
    end

    currentStatus =
        "Configuring startup..."

    drawInstaller()

    sleep(1)

    if not fs.exists(
        "/startup.lua"
    ) then
        drawError(
            "startup.lua was not installed."
        )

        return
    end

    fs.delete("/installer.lua")

    drawComplete()

    sleep(3)

    os.reboot()
end

install()

