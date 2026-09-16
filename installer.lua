local REPOSITORY = "creeperdeveloper/Creeper-Missle-Placement-System"

local BRANCH = "main"

local files = {
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

    term.setCursorPos(x, y)
    term.write(text)
end

local function screen(title, message)
    clear()

    local _, height = term.getSize()

    center(title, math.floor(height / 2) - 1)
    center(message, math.floor(height / 2) + 1)
end

local function progress(current, total)
    local width, height = term.getSize()

    local barWidth = math.min(width - 10, 30)
    local filled = math.floor(barWidth * current / total)

    local bar = string.rep("#", filled) .. string.rep("-", barWidth - filled)

    term.setCursorPos(math.floor((width - barWidth) / 2) + 1, height - 3)
    term.write("[" .. bar .. "]")

    center(tostring(current) .. " / " .. tostring(total), height - 1)
end

local function download(url)
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

local function isCommandComputer()
    return type(commands) == "table"
        and type(commands.exec) == "function"
end

local function fail(message)
    clear()

    local _, height = term.getSize()

    center("INSTALLATION FAILED", math.floor(height / 2) - 2)
    center(message, math.floor(height / 2))
    center("Press any key to restart.", math.floor(height / 2) + 2)

    os.pullEvent("key")

    os.reboot()
end

clear()

if not isCommandComputer() then
    fail("Command Computer required.")
end

if not http then
    fail("HTTP API is disabled.")
end

local testURL = "https://raw.githubusercontent.com"

local ok = pcall(function()
    return http.checkURL(testURL)
end)

if not ok then
    fail("GitHub access is unavailable.")
end

if REPOSITORY == "YOUR_GITHUB_USERNAME/YOUR_REPOSITORY" then
    fail("GitHub repository is not configured.")
end

screen("SYSTEM INSTALLER", "Preparing installation...")
sleep(1)

local downloaded = {}

for i, file in ipairs(files) do
    clear()

    local _, height = term.getSize()

    center("SYSTEM INSTALLER", 3)
    center("Downloading system files", 5)
    center(file.remote, 7)

    local url =
        "https://raw.githubusercontent.com/"
        .. REPOSITORY
        .. "/"
        .. BRANCH
        .. "/"
        .. file.remote

    local content = download(url)

    if not content then
        fail("Download failed: " .. file.remote)
    end

    downloaded[i] = {
        path = file.localPath,
        content = content
    }

    progress(i, #files)

    sleep(0.4)
end

clear()

center("SYSTEM INSTALLER", 3)
center("Installing components", 5)

for _, file in ipairs(downloaded) do
    local temporary = file.path .. ".install"

    if not writeFile(temporary, file.content) then
        fail("Write failed.")
    end
end

for _, file in ipairs(downloaded) do
    local temporary = file.path .. ".install"

    if fs.exists(file.path) then
        fs.delete(file.path)
    end

    fs.move(temporary, file.path)
end

clear()

center("INSTALLATION COMPLETE", 8)
center("Restarting system...", 10)

sleep(2)

if fs.exists("/installer.lua") then
    fs.delete("/installer.lua")
end

os.reboot()
