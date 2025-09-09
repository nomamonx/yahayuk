-- =========================
-- Part 1: Setup & Tabs
-- =========================

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local JobId = game.JobId
local PlaceId = game.PlaceId

-- Basic config
local Config = {
    WebhookURL = nil,
    SendWebhook = false,
    WebhookUseEmbed = true,
    ScanInterval = 2.5,
    AutoHop = true,
    AutoLeave = true,
    IgnoreFriends = true,
    VerboseLogging = false,
    NotifyInGame = true,
    DetectionCooldown = 5,
    SummitDetectMethod = "position",
    SummitPositionY = 1000,
    SummitPositionHold = 1.2,
}

-- Logging & helper
local LogHistory = {}
local function Log(...)
    local msg = table.concat({...}, " ")
    table.insert(LogHistory, {time=os.date("%H:%M:%S"), text=msg})
    if Config.VerboseLogging then print("[Log]", msg) end
end

local function CopyToClipboard(txt)
    pcall(function() setclipboard(txt) end)
end

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "VIP: MT Chalid",
    LoadingTitle = "Sedang Loading",
    LoadingSubtitle = "By Acong Gacor",
})

-- Tabs
local TeleTab = Window:CreateTab("Teleport", 4483362458)
local TabDetector = Window:CreateTab("Detektor")
local TabSettings = Window:CreateTab("Settings")
local TabAdvanced = Window:CreateTab("Advanced")

-- Small helpers to match Rayfield API
local function CreateLabel(tab, text) if tab and tab.CreateLabel then return tab:CreateLabel(text) end return { Set = function() end } end
local function CreateToggle(tab, opts) if tab and tab.CreateToggle then return tab:CreateToggle(opts) end end
local function CreateButton(tab, opts) if tab and tab.CreateButton then return tab:CreateButton(opts) end end
local function CreateTextBox(tab, opts) if tab and tab.CreateTextBox then return tab:CreateTextBox(opts) end end
local function CreateParagraph(tab, opts) if tab and tab.CreateParagraph then return tab:CreateParagraph(opts) end end
local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield:Notify({ Title = title, Content = content, Duration = 5 }) else warn(title, content) end end

-- UI Elements - Detector Tab
local AdminLabel = CreateLabel(TabDetector, "Admin Terdeteksi: -")
local StatusLabel = CreateLabel(TabDetector, "Status: Idle")
local PlayersLabel = CreateLabel(TabDetector, "Players: 0")

-- UI Elements - Summit Tab
local SummitLabel = CreateLabel(TabSettings, "Summit: 0 | Last: 00m:00s")

-- End Part 1
Log("Part 1 loaded: Setup & Tabs")
-- =========================
-- Part 2: Webhook & Settings + Summit Stats
-- =========================

-- =========================
-- Summit Stats
-- =========================
local summitStats = { count = 0, lastTime = 0, lastRespawn = tick() }

-- Reset Summit Button
local btnResetSummit = CreateButton(TabSettings, {
    Name = "♻️ Reset Summit Stats",
    Callback = function()
        summitStats.count = 0
        summitStats.lastTime = 0
        summitStats.lastRespawn = tick()
        pcall(function() SummitLabel:Set("Summit: 0 | Last: 00m:00s") end)
        Notify("Summit", "Stats summit direset.")
    end
})

-- =========================
-- Webhook Settings
-- =========================
CreateParagraph(TabSettings, {
    Title = "Webhook",
    Content = "Atur webhook untuk menerima notifikasi. Gunakan 'Test Webhook' untuk cek."
})

local inputWebhook = CreateTextBox(TabSettings, {
    Name = "Webhook URL",
    PlaceholderText = Config.WebhookURL or "https://discord.com/api/webhooks/...",
    Text = Config.WebhookURL or "",
    Callback = function(txt)
        Config.WebhookURL = txt or Config.WebhookURL
        Notify("Webhook", "URL webhook disimpan: "..tostring(Config.WebhookURL))
    end
})

local toggleSendWebhookUI = CreateToggle(TabSettings, {
    Name = "Kirim Notif ke Discord",
    CurrentValue = Config.SendWebhook,
    Callback = function(v) Config.SendWebhook = v end
})

local toggleWebhookEmbedUI = CreateToggle(TabSettings, {
    Name = "Gunakan Embed di Webhook",
    CurrentValue = Config.WebhookUseEmbed,
    Callback = function(v) Config.WebhookUseEmbed = v end
})

-- Tombol test webhook
local btnTestWebhook = CreateButton(TabSettings, {
    Name = "📡 Test Webhook",
    Callback = function()
        if not Config.WebhookURL or Config.WebhookURL == "" then
            Notify("Webhook Gagal", "⚠️ Belum ada URL webhook yang diset.")
            return
        end
        local ok, err = pcall(function()
            -- fungsi kirim webhook dummy
            -- bisa diganti dengan SendWebhook yang kamu punya
            print("Test webhook dikirim ke "..Config.WebhookURL)
        end)
        if ok then
            Notify("Webhook", "Test terkirim!")
        else
            Notify("Webhook Gagal", tostring(err))
        end
    end
})

-- Tombol hapus webhook
local btnClearWebhook = CreateButton(TabSettings, {
    Name = "🗑️ Hapus Webhook",
    Callback = function()
        Config.WebhookURL = nil
        inputWebhook:Set("")  -- kosongkan input di UI
        Notify("Webhook", "URL webhook telah dihapus.")
    end
})

-- =========================
-- Detection Settings
-- =========================
CreateParagraph(TabSettings, {
    Title = "Detection",
    Content = "Atur interval scan, behavior auto-hop/leave, dan opsi ignore friend."
})

local inputScanInterval = CreateTextBox(TabSettings, {
    Name = "Scan Interval (detik)",
    PlaceholderText = tostring(Config.ScanInterval),
    Text = tostring(Config.ScanInterval),
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n >= 0.2 then Config.ScanInterval = n end
    end
})

local toggleAutoHopUI = CreateToggle(TabSettings, {
    Name = "Auto Hop Jika Admin",
    CurrentValue = Config.AutoHop,
    Callback = function(v) Config.AutoHop = v end
})

local toggleAutoLeaveUI = CreateToggle(TabSettings, {
    Name = "Auto Leave (kick) Jika Admin",
    CurrentValue = Config.AutoLeave,
    Callback = function(v) Config.AutoLeave = v end
})

local toggleIgnoreFriendsUI = CreateToggle(TabSettings, {
    Name = "Ignore Friends",
    CurrentValue = Config.IgnoreFriends,
    Callback = function(v) Config.IgnoreFriends = v end
})

-- End Part 2
Log("Part 2 loaded: Webhook & Settings + Summit Stats")
-- =========================
-- Part 3: Teleport Manual & Otomatis
-- =========================

-- Variabel delay default (khusus auto teleport)
local AutoTeleportDelay = 2
local isAutoTeleporting = false
local autoTeleportTask = nil

-- Teleport points
local teleportPoints = {
    Spawn = CFrame.new(-932, 170, 881),
    CP1 = CFrame.new(-418, 250, 766),
    CP2 = CFrame.new(-347, 389, 522),
    CP3 = CFrame.new(288, 430, 506),
    CP4 = CFrame.new(334, 491, 349),
    CP5 = CFrame.new(210, 315, -148),
    Puncak = CFrame.new(-587, 906, -511),
}

-- =========================
-- Manual Teleport Buttons
-- =========================
TeleTab:CreateSection("Teleport Manual")
TeleTab:CreateButton({ Name = "🚩 Spawn", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Spawn
end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 1", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP1
end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 2", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP2
end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 3", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP3
end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 4", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP4
end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 5", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP5
end })
TeleTab:CreateButton({ Name = "📍 Teleport Puncak", Callback = function()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Puncak
end })

-- =========================
-- Auto Teleport Section
-- =========================
TeleTab:CreateSection("Teleport Otomatis")
TeleTab:CreateToggle({
    Name = "⚡ Auto Teleport",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(Value)
        isAutoTeleporting = Value
        if Value then
            autoTeleportTask = task.spawn(function()
                local player = game.Players.LocalPlayer
                local autoTeleportPoints = { teleportPoints.CP1, teleportPoints.CP2, teleportPoints.CP3, teleportPoints.CP4, teleportPoints.CP5, teleportPoints.Puncak }
                while isAutoTeleporting do
                    for i, cf in ipairs(autoTeleportPoints) do
                        if not isAutoTeleporting then break end
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = cf
                            Rayfield:Notify({
                                Title = "Auto Teleport",
                                Content = "Teleport ke CP " .. i,
                                Duration = 2,
                            })
                        end
                        task.wait(AutoTeleportDelay)
                    end
                    -- Respawn character after finishing points
                    if not isAutoTeleporting then break end
                    Rayfield:Notify({ Title = "Respawn", Content = "Respawn karakter...", Duration = 2 })
                    if player.Character then
                        player.Character:BreakJoints()
                    end
                    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    task.wait(1.5)
                end
            end)
        else
            if autoTeleportTask then
                task.cancel(autoTeleportTask)
                autoTeleportTask = nil
            end
            Rayfield:Notify({ Title = "Auto Teleport", Content = "Auto teleport dihentikan!", Duration = 3 })
        end
    end,
})

-- =========================
-- Delay Slider
-- =========================
TeleTab:CreateSection("Atur Delay Auto Teleport")
TeleTab:CreateSlider({
    Name = "⏳ Delay Auto Teleport (detik)",
    Range = {0, 20},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = AutoTeleportDelay,
    Flag = "ATDelay",
    Callback = function(Value)
        AutoTeleportDelay = Value
    end,
})

-- End Part 3
Log("Part 3 loaded: Teleport Manual & Otomatis")
-- =========================
-- Part 4: Detection & Admin Handling (enhanced)
-- =========================

-- runtime state & caches
local summitStats = { count = 0, lastTime = 0, lastRespawn = tick() }
local lastAdminDetect = 0
local handlingAdmin = false
local bannedServersCache = {} -- server.id -> true when hop failed

-- =========================
-- Helper Functions
-- =========================
local function lower(s)
    return (type(s) == "string" and string.lower(s) or "")
end

local function isBlacklisted(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _, b in ipairs(BlacklistNames) do
        if uname == lower(b) or dname == lower(b) or string.find(uname, lower(b), 1, true) or string.find(dname, lower(b), 1, true) then
            return true, "BlacklistName:" .. tostring(b)
        end
    end
    return false, nil
end

local function hasRankKeywordInName(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _, kw in ipairs(RankKeywords) do
        local lk = lower(kw)
        if string.find(uname, lk, 1, true) or string.find(dname, lk, 1, true) then
            return true, "NameContains:" .. kw
        end
    end
    return false, nil
end

local function guiAdminDetect(player)
    if not player.Character then return false, nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false, nil end
    for _, gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
                    if text:match("^[A-Z0-9%s%p]+$") then
                        for _, kw in ipairs(RankKeywords) do
                            if text:find(kw) then
                                return true, "GuiText:" .. text
                            end
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

local function IsFriend(player)
    if not Config.IgnoreFriends then return false end
    local ok, res = pcall(function() return player and player:IsFriendsWith(LocalPlayer.UserId) end)
    return ok and res
end

-- =========================
-- Server Hop Enhanced
-- =========================
function serverHopAttemptEnhanced()
    local maxPages = 8
    local pageCursor = nil
    local found = nil
    local triedServers = 0

    for page = 1, maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end

        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then
            Log("serverHopAttemptEnhanced: HttpGet failed at page", page)
            break
        end

        local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(json) ~= "table" then
            Log("serverHopAttemptEnhanced: JSON decode failed")
            break
        end

        for _, srv in ipairs(json.data or {}) do
            triedServers = triedServers + 1
            if type(srv) == "table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id) ~= tostring(JobId) and (srv.playing < srv.maxPlayers) and (not bannedServersCache[srv.id]) then
                    found = srv.id
                    break
                end
            end
        end
        if found then break end
        pageCursor = json.nextPageCursor
        if not pageCursor then break end
        task.wait(0.1)
    end

    if found then
        Log("Found server to hop:", found)
        local success, err = pcall(function()
            task.spawn(function()
                task.wait(0.1)
                TeleportService:TeleportToPlaceInstance(PlaceId, found)
            end)
        end)
        if not success then
            Log("Teleport failed:", err)
            Notify("Hop Gagal", "Teleport gagal: " .. tostring(err))
        end
        return true
    else
        Log("No suitable server found after checking "..triedServers.." servers.")
        Notify("Hop Gagal", "Tidak ada server yang bisa di-hop (semua penuh atau tidak valid).")
        return false
    end
end

-- alias legacy
serverHopAttempt = serverHopAttemptEnhanced

-- =========================
-- Escape & Admin Handling
-- =========================
local function performEscapeAction(playerName, reason)
    if Config.AutoHop then
        local ok = pcall(function() return serverHopAttempt() end)
        if ok then
            SendWebhook("Admin Detected - Attempting Hop", ("Detected **%s** (%s). Attempting server hop."):format(playerName, reason), { color = 16766720 })
            return true
        else
            Log("AutoHop attempt failed for", playerName)
            if Config.AutoLeave then pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end) end
        end
    elseif Config.AutoLeave then
        pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end)
    end
    return false
end

local function handleAdminDetectedEnhanced(player, reason)
    if handlingAdmin then return end
    local now = tick()
    if now - lastAdminDetect < Config.DetectionCooldown then
        Log("handleAdminDetectedEnhanced: on cooldown")
        return
    end
    handlingAdmin = true
    lastAdminDetect = now

    local pname = (player and player.Name) or "Unknown"
    local pdisplay = (player and player.DisplayName) or pname
    local status = (player and player:IsDescendantOf(game)) and "Online" or "Offline"
    local msg = ("⚠️ Admin Detected: **%s** (%s)\nReason: %s\nStatus: %s\nPlaceId: %d\nTime: %s"):format(
        tostring(pname), tostring(pdisplay), tostring(reason or "-"), status, PlaceId, os.date("%Y-%m-%d %H:%M:%S")
    )

    pcall(function() AdminLabel:Set("Admin Terdeteksi: " .. tostring(pname) .. " (" .. tostring(reason) .. ")") end)
    pcall(function() StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(pname)) end)
    Log("Detected admin:", pname, reason)

    -- send webhook
    pcall(function()
        SendWebhook(("⚠️ Admin Detected — %s"):format(pname), msg, {
            color = 15158332,
            fields = {
                { name = "Player", value = pname, inline = true },
                { name = "Display", value = pdisplay, inline = true },
                { name = "Reason", value = tostring(reason), inline = false },
                { name = "ServerId", value = tostring(JobId), inline = true },
                { name = "PlaceId", value = tostring(PlaceId), inline = true },
            }
        })
    end)

    if Config.NotifyInGame then Notify("⚠️ Admin Terdeteksi", tostring(pname) .. " (" .. tostring(reason) .. ")") end
    pcall(function() CopyToClipboard(pname) end)
    task.spawn(function()
        task.wait(0.6)
        performEscapeAction(pname, reason)
    end)

    task.delay(8, function() handlingAdmin = false end)
end

-- =========================
-- Check Single Player
-- =========================
function CheckPlayerForAdminEnhanced(player)
    if not player or player == LocalPlayer then return false end
    if Config.IgnoreFriends and IsFriend(player) then
        if Config.VerboseLogging then Log("Ignored friend:", player.Name) end
        return false
    end

    local ok, reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then
        handleAdminDetectedEnhanced(player, reason)
        return true
    end

    local ok2, reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then
        handleAdminDetectedEnhanced(player, reason2)
        return true
    end

    local ok3, reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then
        handleAdminDetectedEnhanced(player, reason3)
        return true
    end

    -- unusual Humanoid props
    pcall(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            local ws, jp = hum.WalkSpeed or 16, hum.JumpPower or 0
            if ws > 60 or jp > 220 then
                handleAdminDetectedEnhanced(player, ("UnusualMovement(ws=%s,jp=%s)"):format(ws, jp))
            end
        end
    end)

    return false
end

-- End Part 4
Log("Part 4 loaded: Detection & Admin Handling (enhanced)")
-- =========================
-- Part 5: Summit Detection & Position Watcher (enhanced)
-- =========================

-- runtime summit stats
summitStats = summitStats or { count = 0, lastTime = 0, lastRespawn = tick() }

-- format time helper
function FormatTimeSec(sec)
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%02dm:%02ds", m, s)
end

-- =========================
-- Summit Reached Handler
-- =========================
local function OnSummitReachedEnhanced()
    local now = tick()
    local timeTaken = math.floor(now - summitStats.lastRespawn)
    summitStats.lastTime = timeTaken
    summitStats.count = summitStats.count + 1
    summitStats.lastRespawn = now

    pcall(function() SummitLabel:Set("Summit: "..summitStats.count.." | Last: " .. FormatTimeSec(summitStats.lastTime)) end)

    local desc = ("Player: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        summitStats.count,
        summitStats.lastTime,
        FormatTimeSec(summitStats.lastTime),
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )
    pcall(function() SendWebhook("✅ Summit Reached", desc, { color = 3066993 }) end)
    if Config.NotifyInGame then Notify("🏔️ Summit", "Summit tercapai! Waktu: " .. tostring(FormatTimeSec(summitStats.lastTime))) end
    Log("Summit reached:", summitStats.count, "time:", summitStats.lastTime)
end

-- =========================
-- Leaderstat Watcher
-- =========================
local leaderstatWatching = false

function TryStartLeaderstatWatcherEnhanced()
    if leaderstatWatching then return end
    leaderstatWatching = true
    task.spawn(function()
        while true do
            if not LocalPlayer or not LocalPlayer.Parent then break end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Summit") then
                local lastVal = ls.Summit.Value
                ls.Summit.Changed:Connect(function(newVal)
                    pcall(function()
                        if type(newVal) == "number" and newVal > lastVal then
                            lastVal = newVal
                            OnSummitReachedEnhanced()
                        else
                            lastVal = newVal
                        end
                    end)
                end)
                Log("Leaderstat watcher hooked.")
                break
            end
            task.wait(1)
        end
    end)
end

-- =========================
-- Position Watcher
-- =========================
local positionHoldTimer = 0

function TryStartPositionWatcherEnhanced()
    task.spawn(function()
        while true do
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                if hrp.Position.Y >= (Config.SummitPositionY or 1000) then
                    positionHoldTimer = positionHoldTimer + 0.5
                    if positionHoldTimer >= (Config.SummitPositionHold or 1.2) then
                        OnSummitReachedEnhanced()
                        positionHoldTimer = 0
                        task.wait(3)
                    end
                else
                    positionHoldTimer = 0
                end
            end
            task.wait(0.5)
        end
    end)
end

-- =========================
-- Initialize Summit Detection
-- =========================
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcherEnhanced()
else
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
end

Log("Part 5 loaded: Summit Detection & Position Watcher (enhanced)")
-- =========================
-- Part 6: Main Scanner & PlayerAdded Handler
-- =========================

-- runtime state
local scanRunning = true

-- =========================
-- Start Main Scanner
-- =========================
local function StartMainScanner()
    -- player added event
    Players.PlayerAdded:Connect(function(pl)
        task.spawn(function()
            task.wait(0.45) -- delay supaya character siap
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end)
    end)

    -- main loop
    task.spawn(function()
        while scanRunning do
            local players = Players:GetPlayers()
            -- update UI player count
            pcall(function() PlayersLabel:Set("Players: "..tostring(#players)) end)

            for _,pl in ipairs(players) do
                if pl ~= LocalPlayer then
                    pcall(function() CheckPlayerForAdminEnhanced(pl) end)
                end
            end

            -- update status label
            pcall(function() StatusLabel:Set("Status: Running | Players: " .. tostring(#players)) end)

            -- wait interval
            task.wait(math.max(0.2, Config.ScanInterval or 2.5))
        end
    end)
end

-- =========================
-- Initialize Main Scanner
-- =========================
StartMainScanner()

Log("Part 6 loaded: Main Scanner & PlayerAdded Handler initialized")
-- =========================
-- Part 7: Init & Final Startup
-- =========================

-- start watchers based on config
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcherEnhanced()
else
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
end

-- Start main scanner
StartMainScanner()

-- notify ready
Notify("Detektor Aktif", "Admin & Summit Detector berjalan. Periksa tab HWID bila perlu.")
Log("Detektor initialized. Version:", _VERSION, "StartTick:", StartTick)

-- Load last configuration if ada
Rayfield:LoadConfiguration()

-- =========================
-- Final touches
-- =========================

-- auto-save config setiap interval tertentu
task.spawn(function()
    while true do
        task.wait(Config.AutoSaveInterval or 60)
        pcall(function() Rayfield:SaveConfiguration() end)
        Log("Configuration auto-saved")
    end
end)

-- keep-alive watcher
task.spawn(function()
    while true do
        task.wait(5)
        if not LocalPlayer or not LocalPlayer.Parent then
            Log("LocalPlayer lost, attempting re-init")
            task.wait(1)
        end
    end
end)

-- sanity check for UI
task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            if not AdminLabel or not StatusLabel or not PlayersLabel then
                Log("UI missing, re-creating labels")
                AdminLabel = CreateLabel(TabDetector, "Admin Terdeteksi: -")
                StatusLabel = CreateLabel(TabDetector, "Status: Idle")
                PlayersLabel = CreateLabel(TabDetector, "Players: 0")
            end
        end)
    end
end)

Log("Part 7 loaded: Init & Final Startup complete")
-- =========================
-- Part 7: End / Cleanup
-- =========================

-- Simpan konfigurasi terakhir sebelum keluar
pcall(function() Rayfield:SaveConfiguration() end)
Log("Configuration saved before exit")

-- Hentikan semua loop/task
isAutoTeleporting = false
leaderstatWatching = false
positionHoldTimer = 0
handlingAdmin = false
autoTeleportTask = nil
Log("All loops/tasks stopped")

-- Clear references UI / variabel
AdminLabel = nil
StatusLabel = nil
PlayersLabel = nil
SummitLabel = nil
LocalPlayer = nil
teleportPoints = nil
autoTeleportPoints = nil
Log("Variables cleared")

-- Notifikasi penutupan
Notify("Script Ditutup", "Admin & Summit Detector telah dimatikan dengan aman.")

-- Optional: teleport ke spawn atau kick player
-- pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Spawn end)
-- pcall(function() LocalPlayer:Kick("Script ditutup") end)

-- Akhiri script secara bersih
Log("=== End of Script ===")
