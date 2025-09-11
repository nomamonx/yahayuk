
local success, RayfieldOrErr = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not RayfieldOrErr then
    warn("Rayfield gagal dimuat. Pastikan URL dapat diakses atau executor-mu mendukung HttpGet.")
    if typeof(RayfieldOrErr) == "string" then
        warn("Error detail:", RayfieldOrErr)
    end
    return
end

local Rayfield = RayfieldOrErr

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Default Config (editable via UI) =====
local Config = {
    AutoHop = true,            -- Auto hop ke server lain saat admin terdeteksi
    AutoLeave = false,         -- Auto kick (jika ingin kick instead of hop)
    SendWebhook = true,        -- Kirim semua notif ke Discord
    ScanInterval = 2.5,        -- interval scan admin (detik)
    SummitDetectMethod = "leaderstat", -- "leaderstat" or "position" or "both"
    SummitPositionY = 1000,    -- jika pakai position, threshold Y untuk anggap "summit"
    SummitPositionHold = 1.2,  -- harus bertahan di atas threshold (detik)
    WebhookURL = "", -- default placeholder
    WebhookUseEmbed = true,    -- use embed payload when possible
    DetectionCooldown = 6,     -- minimal waktu antar deteksi
    IgnoreFriends = false,      -- ignore friends
    VerboseLogging = true,     -- banyak log
    NotifyInGame = true,       -- Rayfield notify

}

-- ===== Blacklist & Keywords =====
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- =========================
-- Part 1b: Utilities & Logging
-- =========================

local _VERSION = "Detektor By Acong"
local StartTick = tick()
local LogHistory = {}

local function Log(...)
    local args = {...}
    local line = ""
    for i=1,#args do
        line = line .. tostring(args[i])
        if i < #args then line = line .. "\t" end
    end
    table.insert(LogHistory, {time = os.date("%Y-%m-%d %H:%M:%S"), text = line})
    if #LogHistory > 1000 then
        -- keep log reasonably bounded
        for i=1,500 do table.remove(LogHistory, 1) end
    end
    if Config.VerboseLogging then
        pcall(function() print("[Detektor] "..os.date("%H:%M:%S").." - "..line) end)
    end
end

local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        Log("safeCall error:", res)
        return nil, res
    end
    return res
end

local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02dm:%02ds", m, s)
end

local function CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
            if Config.NotifyInGame then Rayfield:Notify({ Title = "Clipboard", Content = "Teks disalin ke clipboard.", Duration = 3 }) end
        end
    end)
end

-- =========================
-- Part 1c: Safe Webhook Sender (multi-method)
-- =========================

local function BuildWebhookPayload(title, description, extra)
    extra = extra or {}
    if Config.WebhookUseEmbed then
        local embed = {
            title = title,
            description = description,
            color = extra.color or 16753920,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            fields = extra.fields or {},
            footer = { text = _VERSION }
        }
        return HttpService:JSONEncode({ embeds = { embed } })
    else
        return HttpService:JSONEncode({ content = ("**%s**\n%s"):format(title, description) })
    end
end

local function SendWebhookRaw(url, body)
    local ok, err
    if syn and syn.request then
        ok, err = pcall(function() syn.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif http_request then
        ok, err = pcall(function() http_request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif request then
        ok, err = pcall(function() request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif http and http.request then
        ok, err = pcall(function() http.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    else
        ok, err = pcall(function() game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson) end)
    end
    if not ok then
        Log("SendWebhookRaw failed:", tostring(err))
        return false, tostring(err)
    end
    return true
end

local function SendWebhook(title, description, extra)
    if not Config.SendWebhook then
        Log("SendWebhook disabled")
        return false, "disabled"
    end
    local url = Config.WebhookURL
    if not url or url == "" or url:find("PUT_YOUR_WEBHOOK") then
        Log("SendWebhook: webhook not set or placeholder")
        return false, "no webhook"
    end
    local body = BuildWebhookPayload(title, description, extra)
    return SendWebhookRaw(url, body)
end


-- =========================
-- Part 2: Window + UI (single window, multiple tabs)
-- =========================

local Window = Rayfield:CreateWindow({
    Name = "🛡️ VIP :MT Yahayuk",
    LoadingTitle = "Fitur Admin Deteksi",
    LoadingSubtitle = "Sedang Loading...🚀",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "yahayukSummit",
        FileName = "Config"
    },
})
-- // Ambil HWID
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- // Load database dari GitHub
local success, AllowedHWIDs = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nomamonx/gunung/refs/heads/main/hwid1.lua"))()
end)

if not success or type(AllowedHWIDs) ~= "table" then
    AllowedHWIDs = {}
end

-- // Cek HWID
local isVIP = AllowedHWIDs[hwid] == true

-- // Tab HWID SELALU ADA
local HWIDTab = Window:CreateTab("HWID", 4483362458)

if isVIP then
    HWIDTab:CreateParagraph({
        Title = "✅ HWID Terdaftar",
        Content = "HWID kamu sudah terdaftar.\n\n" .. hwid
    })

    HWIDTab:CreateButton({
        Name = "Reset HWID",
        Callback = function()
            setclipboard(hwid)
            Rayfield:Notify({
                Title = "Reset HWID",
                Content = "HWID kamu sudah disalin.\nHubungi owner untuk reset di database.",
                Duration = 6
            })
        end,
    })


-- Tabs dengan ikon menarik
local TeleTab = Window:CreateTab("Teleport ", 4483362458)       -- ikon globe
local TabDetector = Window:CreateTab("Detektor ", 4483362458) -- ikon detektif
local TabSettings = Window:CreateTab("Settings ", 4483362458)     -- ikon gear


-- Small helper wrappers to match Rayfield API
local function CreateLabel(tab, text) if tab and tab.CreateLabel then return tab:CreateLabel(text) end return { Set = function() end } end
local function CreateToggle(tab, opts) if tab and tab.CreateToggle then return tab:CreateToggle(opts) end end
local function CreateButton(tab, opts) if tab and tab.CreateButton then return tab:CreateButton(opts) end end
local function CreateTextBox(tab, opts) if tab and tab.CreateTextBox then return tab:CreateTextBox(opts) end end
local function CreateParagraph(tab, opts) if tab and tab.CreateParagraph then return tab:CreateParagraph(opts) end end
local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield:Notify({ Title = title, Content = content, Duration = 5 }) else warn(title, content) end end

-- UI Elements - Detector Tab
local AdminLabel = CreateLabel(TabDetector, "🛡️ Admin Terdeteksi: -")
local StatusLabel = CreateLabel(TabDetector, "📊 Status: Idle")
local PlayersLabel = CreateLabel(TabDetector, "👥 Players: 0")
local SummitLabel = CreateLabel(TabDetector, "🏔️ Summit: 0 | Total Global: 0 | Last: -")


TabDetector:CreateSection("Scan Player")
local btnManualScan = CreateButton(TabDetector, { Name = "🔎 Manual Scan Sekarang", Callback = function()
    Log("Manual scan started")
    for _,pl in ipairs(Players:GetPlayers()) do
        pcall(function() CheckPlayerForAdminEnhanced(pl) end)
    end
    Notify("Manual Scan", "Selesai memindai pemain.")
end })


TabDetector:CreateSection("Log Script")
local btnShowLog = CreateButton(TabDetector, { Name = "📜 Copy Recent Log", Callback = function()
    local text = ""
    for i = math.max(1, #LogHistory - 80), #LogHistory do
        local e = LogHistory[i]
        if e then text = text .. "["..e.time.."] "..e.text.."\n" end
    end
    CopyToClipboard(text)
    Notify("Log disalin", "Recent log disalin ke clipboard.")
end })

TabDetector:CreateSection("Hop Server")
local btnManualHop = CreateButton(TabDetector, { Name = "🛫 Manual Hop ke Server Lain", Callback = function()
    local ok = pcall(function() serverHopAttemptEnhanced() end)
    Notify("Manual Hop", ok and "Percobaan hop dijalankan." or "Gagal menjalankan hops.")
end })


-- UI Elements - Settings Tab
CreateParagraph(TabSettings, { Title = "Webhook", Content = "Atur webhook untuk menerima notifikasi. Gunakan 'Test Webhook' untuk cek." })
local inputWebhook = CreateTextBox(TabSettings, { Name = "Webhook URL", PlaceholderText = Config.WebhookURL, Text = Config.WebhookURL or "", Callback = function(txt) Config.WebhookURL = txt or Config.WebhookURL end })
local toggleSendWebhookUI = CreateToggle(TabSettings, { Name = "Kirim Notif ke Discord", CurrentValue = Config.SendWebhook, Callback = function(v) Config.SendWebhook = v end })
local toggleWebhookEmbedUI = CreateToggle(TabSettings, { Name = "Gunakan Embed di Webhook", CurrentValue = Config.WebhookUseEmbed, Callback = function(v) Config.WebhookUseEmbed = v end })


TabSettings:CreateSection("Menu Webhook")
local inputWebhook = TabSettings:CreateInput({
    Name = "Masukkan Webhook",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookURL",
    Callback = function(Text)
        if Text and Text ~= "" then
            Config.WebhookURL = Text
            Notify("Webhook", "URL webhook disimpan: "..Text)
        else
            Config.WebhookURL = nil
            Notify("Webhook", "URL webhook dihapus.")
        end
    end,
})

TabSettings:CreateSection("Fitur Hapus Dan Tes")
local btnClearWebhook = TabSettings:CreateButton({
    Name = "🗑️ Hapus Webhook",
    Callback = function()
        Config.WebhookURL = nil
        inputWebhook:Set("")  -- kosongkan input di UI
        Notify("Webhook", "URL webhook telah dihapus.")
    end
})
-- Tombol test webhook langsung pakai URL yang diinput
local btnTestWebhook = TabSettings:CreateButton({
    Name = "📡 Test Webhook",
    Callback = function()
        if not Config.WebhookURL or Config.WebhookURL == "" then
            Notify("Webhook Gagal", "⚠️ Belum ada URL webhook yang diset.")
            return
        end
        local ok, err = SendWebhook("✅ Test @everyone", "Ini pesan test dari Kamu. URL sudah disimpan.")
        if ok then
            Notify("Webhook", "Test terkirim!")
        else
            Notify("Webhook Gagal", tostring(err))
        end
    end
})


TabSettings:CreateSection("Auto Hop Admin")
local inputScanInterval = CreateTextBox(TabSettings, { Name = "Scan Interval (detik)", PlaceholderText = tostring(Config.ScanInterval), Text = tostring(Config.ScanInterval), Callback = function(txt) local n = tonumber(txt) if n and n >= 0.2 then Config.ScanInterval = n end end })
local toggleAutoHopUI = CreateToggle(TabSettings, { Name = "Auto Hop Jika Admin", CurrentValue = Config.AutoHop, Callback = function(v) Config.AutoHop = v end })
local toggleAutoLeaveUI = CreateToggle(TabSettings, { Name = "Auto Leave (kick) Jika Admin", CurrentValue = Config.AutoLeave, Callback = function(v) Config.AutoLeave = v end })
local toggleIgnoreFriendsUI = CreateToggle(TabSettings, { Name = "Ignore Friends", CurrentValue = Config.IgnoreFriends, Callback = function(v) Config.IgnoreFriends = v end })

-- UI Elements - HWID Tab

-- Variabel delay default (khusus auto teleport)
-- Variabel delay default
local AutoTeleportDelay = 2
local PeakRespawnDelay = 0

-- ===== Global Summit Save =====
local GlobalStats = {
    TotalSummits = 0
}

-- Load dari config (kalau ada)
if isfile("DetektorSummit/Config.json") then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile("DetektorSummit/Config.json"))
    end)
    if ok and data and data.TotalSummits then
        GlobalStats.TotalSummits = data.TotalSummits
    end
end

-- runtime state
local summitStats = { count = 0, lastTime = 0, lastRespawn = tick() }
-- ======= Helper =======
local function FormatTimeSec(sec)
    return string.format("%02d:%02d", math.floor(sec/60), math.floor(sec%60))
end

-- Saat summit tercapai
local function OnSummitReachedEnhanced()
    local now = tick()
    local duration = now - (summitStats.lastRespawn or now)
summitStats.count = summitStats.count + 1
GlobalStats.TotalSummits = GlobalStats.TotalSummits + 1
    summitStats.lastTime = duration
    summitStats.lastRespawn = now

    -- update UI + notify
    local msg = "Summit #" .. summitStats.count ..
        " | Total Global: " .. GlobalStats.TotalSummits ..
        " | Waktu: " .. FormatTimeSec(duration)

    Rayfield:Notify({
        Title = "⛰️ Summit Tercapai!",
        Content = msg,
        Duration = 5,
    })

    -- simpan ke file
    pcall(function()
        writefile("DetektorSummit/Config.json", HttpService:JSONEncode(GlobalStats))
    end)
end

local teleportPoints = {
    Spawn = CFrame.new(-932, 170, 881),
    CP1 = CFrame.new(-420, 249, 770),
    CP2 = CFrame.new(-347, 389, 522),
    CP3 = CFrame.new(288, 430, 506),
    CP4 = CFrame.new(334, 491, 349),
    CP5 = CFrame.new(210, 315, -148),
    Puncak = CFrame.new(-604, 905, -494),
}

-- Manual Teleport TANPA delay
TeleTab:CreateSection("Teleport Manual")
TeleTab:CreateButton({ Name = "🚩 Spawn", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Spawn end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 1", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP1 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 2", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP2 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 3", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP3 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 4", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP4 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 5", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP5 end })
TeleTab:CreateButton({ Name = "📍 Teleport Puncak", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Puncak end })

-- Auto Teleport
local isAutoTeleporting = false
local autoTeleportTask = nil

local autoTeleportPoints = {
    teleportPoints.CP1,
    teleportPoints.CP2,
    teleportPoints.CP3,
    teleportPoints.CP4,
    teleportPoints.CP5,
    -- Puncak dipisahkan agar bisa pakai delay khusus
}

local function respawnCharacter()
    local player = game.Players.LocalPlayer
    if player.Character then
        player.Character:BreakJoints()
    end
    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0
end

local function isAtSpawn(pos, threshold)
    local spawnPos = teleportPoints.Spawn.Position
    return (pos - spawnPos).Magnitude <= threshold
end

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
                while isAutoTeleporting do
                    -- Teleport dari CP1 sampai CP5
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
                        task.wait(AutoTeleportDelay) -- delay sesuai slider
                    end

                    -- Khusus Puncak
                    if not isAutoTeleporting then break end
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = teleportPoints.Puncak
                        Rayfield:Notify({
                            Title = "Auto Teleport",
                            Content = "🚀 Teleport ke Puncak",
                            Duration = 2,
                        })
                    end
                    -- tunggu sesuai slider khusus Puncak
                    task.wait(PeakRespawnDelay)

                    -- Respawn karakter
                    if not isAutoTeleporting then break end
                    Rayfield:Notify({
                        Title = "Respawn",
                        Content = "Respawn karakter...",
                        Duration = 2,
                    })
                    respawnCharacter()

                    -- Tunggu sampai karakter benar-benar di spawn
                    local maxWaitTime, waited = 6, 0
                    repeat
                        task.wait(0.5)
                       waited = waited + 0.5
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            if isAtSpawn(char.HumanoidRootPart.Position, 10) then
                                break
                            end
                        end
                    until waited >= maxWaitTime

                    Rayfield:Notify({
                        Title = "Loop Ulang",
                        Content = "Mulai lagi dari CP1...",
                        Duration = 2,
                    })

                    task.wait(1.5)
                end
            end)
        else
            if autoTeleportTask then
                task.cancel(autoTeleportTask)
                autoTeleportTask = nil
            end
            Rayfield:Notify({
                Title = "Auto Teleport",
                Content = "Auto teleport dihentikan!",
                Duration = 3,
            })
        end
    end,
})


TeleTab:CreateSection("Atur Delay Auto Teleport")
-- Slider untuk atur delay auto teleport
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

TeleTab:CreateSlider({
    Name = "⏳ Delay Respawn di Puncak",
    Range = {0, 10},   -- bisa diatur sesuai keinginan (detik)
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 0,
    Flag = "PeakRespawnDelay",
    Callback = function(Value)
        PeakRespawnDelay = Value
    end,
})



-- =========================
-- Part 3: Detection & Actions (enhanced)
-- =========================

-- runtime state & caches
local summitStats = { count = 0, lastTime = 0, lastRespawn = tick() }
local lastAdminDetect = 0
local handlingAdmin = false
local bannedServersCache = {} -- server.id -> true when hop failed

-- small helpers
local function lower(s) return (type(s) == "string" and string.lower(s) or "") end

local function isBlacklisted(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,b in ipairs(BlacklistNames) do
        if uname == lower(b) or dname == lower(b) or string.find(uname, lower(b), 1, true) or string.find(dname, lower(b), 1, true) then
            return true, "BlacklistName:" .. tostring(b)
        end
    end
    return false, nil
end

local function hasRankKeywordInName(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,kw in ipairs(RankKeywords) do
        local lk = lower(kw)
        if string.find(uname, lk, 1, true) or string.find(dname, lk, 1, true) then
            return true, "NameContains:"..kw
        end
    end
    return false, nil
end

local function guiAdminDetect(player)
    if not player.Character then return false, nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false, nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
                    if text:match("^[A-Z0-9%s%p]+$") then
                        for _,kw in ipairs(RankKeywords) do
                            if text:find(kw) then
                                return true, "GuiText:"..text
                            end
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

-- friend check
local function IsFriend(player)
    if not Config.IgnoreFriends then return false end
    local ok, res = pcall(function() return player and player:IsFriendsWith(LocalPlayer.UserId) end)
    if ok and res then return true end
    return false
end

-- enhanced server hop attempt with safety/backoff
function serverHopAttemptEnhanced()
    local maxPages = 8
    local pageCursor = nil
    local found = nil
    local triedServers = 0

    for page=1,maxPages do
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

        for _,srv in ipairs(json.data or {}) do
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
            Notify("Hop Gagal", "Teleport gagal: "..tostring(err))
        end
        return true
    else
        Log("No suitable server found after checking "..triedServers.." servers.")
        Notify("Hop Gagal", "Tidak ada server yang bisa di-hop (semua penuh atau tidak valid).")
        return false
    end
end



-- alias for legacy name
serverHopAttempt = serverHopAttemptEnhanced

-- perform escape action (hop or leave based on config)
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

-- admin detected handler (enhanced)
local ReasonMap = {
    [true]  = "🟢 kriteria admin",
    [false] = "⚪ Tidak ada indikasi admin",
    ["join"] = "🚪 Admin baru masuk server",
    ["respawn"] = "🔄 Admin respawn",
    ["chat"] = "💬 Admin via chat",
    ["system"] = "⚙️ System flag",
    ["unknown"] = "❓ Tidak diketahui",
}

local function GetReasonText(reason)
    if ReasonMap[reason] then
        return ReasonMap[reason]
    elseif type(reason) == "number" then
        return "🔢 Code #" .. tostring(reason)
    elseif type(reason) == "string" then
        return "📌 " .. reason
    else
        return "❓ Unknown (" .. tostring(reason) .. ")"
    end
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
    local status = (player and player:IsDescendantOf(game)) and "🟢 Online" or "🔴 Offline"
    local timestamp = os.date("📅 %Y-%m-%d ⏰ %H:%M:%S")

    local reasonText = GetReasonText(reason)

    -- link join server
    local joinLink = string.format("roblox://placeId=%d&gameInstanceId=%s", PlaceId, JobId)

    local msg = string.format(
        "🚨 **ADMIN DETECTED!** 🚨\n\n👤 **Player:** %s\n📝 **Display:** %s\n⚠️ **Reason:** %s\n📡 **Status:** %s\n🆔 **PlaceId:** %d\n🌐 **ServerId:** %s\n🔗 **[Join Server](%s)**\n⏱️ **Time:** %s",
        pname, pdisplay, reasonText, status, PlaceId, tostring(JobId), joinLink, timestamp
    )

    pcall(function()
        AdminLabel:Set("🚨 Admin Terdeteksi: " .. pname .. " ⚠️")
    end)
    pcall(function()
        StatusLabel:Set("⚠️ Status: Admin — " .. pname .. " (" .. reasonText .. ")")
    end)

    Log("⚠️ Detected admin:", pname, reasonText)

    pcall(function()
        SendWebhook("🚨 Admin Detected — " .. pname, msg, {
            color = 15158332,
            fields = {
                { name = "👤 Player", value = pname, inline = true },
                { name = "📝 Display", value = pdisplay, inline = true },
                { name = "⚠️ Reason", value = reasonText, inline = false },
                { name = "🌐 ServerId", value = tostring(JobId), inline = true },
                { name = "🆔 PlaceId", value = tostring(PlaceId), inline = true },
                { name = "🔗 Join Server", value = joinLink, inline = false },
                { name = "⏱️ Time", value = timestamp, inline = false },
            }
        })
    end)

    if Config.NotifyInGame and type(Notify) == "function" then
        pcall(function()
            Notify("⚠️ Admin Terdeteksi", pname .. " (" .. reasonText .. ")")
        end)
    end

    pcall(function() CopyToClipboard(pname) end)

    task.spawn(function()
        task.wait(0.6)
        performEscapeAction(pname, reason)
    end)

    task.delay(8, function() handlingAdmin = false end)
end



-- check single player for admin traits (enhanced)
function CheckPlayerForAdminEnhanced(player)
    if not player then return false end
    if player == LocalPlayer then return false end
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

    -- additional heuristics: unusual Humanoid properties or tools
    pcall(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            local ws = hum.WalkSpeed or 16
            local jp = hum.JumpPower or 0
            if ws > 60 or jp > 220 then
                handleAdminDetectedEnhanced(player, ("UnusualMovement(ws=%s,jp=%s)"):format(ws, jp))
            end
        end
    end)

    return false
end

-- =========================
-- Part 4: Summit detection (enhanced)
-- =========================

-- Limit summit sebelum auto hop
local SummitAutoHopLimit = 100

-- Fungsi auto hop server
local function AutoHopServer()
    local ts = game:GetService("TeleportService")
    local player = game.Players.LocalPlayer
    Rayfield:Notify({
        Title = "Auto Hop",
        Content = "Limit summit tercapai! Auto hop ke server baru...",
        Duration = 5
    })
    -- cari server lain random
    local servers = {}
    local success, result = pcall(function()
        return game.HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result and result.data then
        for _,srv in ipairs(result.data) do
            if srv.playing < srv.maxPlayers then
                table.insert(servers, srv.id)
            end
        end
    end
    if #servers > 0 then
        ts:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], player)
    else
        ts:Teleport(game.PlaceId, player) -- fallback kalau gagal
    end
end

-- 🔥 Enhanced Summit + Status Notifier (with Reactions)

-- Helper Webhook + Reaction
local function SendWebhookWithReaction(title, description, color, emoji)
    local embed = {
        title = title,
        description = description,
        color = color,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    local body = HttpService:JSONEncode({ embeds = { embed } })

    local response = http_request({
        Url = Config.WebhookURL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body
    })

    -- Tambah reaction kalau ada BotToken
    pcall(function()
        if response and response.Body and Config.BotToken then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.id and data.channel_id then
                local messageId, channelId = data.id, data.channel_id
                http_request({
                    Url = string.format(
                        "https://discord.com/api/v10/channels/%s/messages/%s/reactions/%s/@me",
                        channelId, messageId, emoji
                    ),
                    Method = "PUT",
                    Headers = {
                        ["Authorization"] = "Bot " .. Config.BotToken,
                        ["Content-Type"] = "application/json"
                    }
                })
            end
        end
    end)
end

-- === Summit Reached ===
-- 🔥 Enhanced Summit + Status Notifier
-- 🔥 Enhanced Summit + Status Notifier (Manual Exit + FC + Ban/Kick + Timestamp)

local alreadyOffline = false
local lastSeen = tick()

local function GetTimestamp()
    return os.date("🕒 %d-%m-%Y %H:%M:%S")
end

local function OnSummitReachedEnhanced()
    local now = tick()
    local duration = now - (summitStats.lastRespawn or now)

    summitStats.count += 1
    GlobalStats.TotalSummits += 1
    summitStats.lastTime = duration
    summitStats.lastRespawn = now

    pcall(function()
        SummitLabel:Set(string.format(
            "Summit: %d | Total Global: %d | Last: %s",
            summitStats.count, GlobalStats.TotalSummits, FormatTimeSec(duration)
        ))
    end)

    Rayfield:Notify({
        Title = "⛰️🔥 Summit Tercapai! 🎉🏆",
        Content = string.format(
            "😎 Summit ke-%d | 🌍 Global: %d | ⏱️ %s",
            summitStats.count, GlobalStats.TotalSummits, FormatTimeSec(duration)
        ),
        Duration = 6
    })

    pcall(function()
        writefile("DetektorSummit/Config.json", HttpService:JSONEncode(GlobalStats))
    end)

    local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
    local maskedName = string.sub(playerName, 1, 2) .. string.rep("*", math.max(#playerName - 2, 0))
    local spoilerName = "||" .. playerName .. "||"
    local playerCount = #Players:GetPlayers()
    local ping = (LocalPlayer and LocalPlayer.GetNetworkPing and LocalPlayer:GetNetworkPing())
        and math.floor(LocalPlayer:GetNetworkPing() * 1000) or 0

    local desc = string.format(
        "👤 Player: %s (%s)\n🖥️ Server: %s\n👥 Orang di server: %d\n⛰️ Summit (server): %d\n🌍 Total Summit: %d\n⏱️ Waktu: %s\n📶 Ping: %d ms\n📡 Status: **ONLINE**\n%s",
        maskedName, spoilerName, tostring(JobId), playerCount,
        summitStats.count, GlobalStats.TotalSummits, FormatTimeSec(duration), ping, GetTimestamp()
    )

    SendWebhookWithReaction("✅🏔️ Summit Reached 🎉", desc, 0x2ecc71, "⛰️")

    if summitStats.count >= SummitAutoHopLimit then
        AutoHopServer()
    end
end

-- === Join Server ===
task.spawn(function()
    task.wait(3)
    local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
    local joinLink = string.format("roblox://placeId=%d&gameInstanceId=%s", game.PlaceId, tostring(JobId))
    local desc = string.format("👤 %s baru masuk!\n🔗 [Klik Join Server](%s)\n%s", playerName, joinLink, GetTimestamp())
    SendWebhookWithReaction("🎉 Player Join Server", desc, 0x3498db, "🎉")
end)

-- === Disconnect Event (Manual Exit) ===
Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer and not alreadyOffline then
        alreadyOffline = true
        local desc = string.format("👤 **%s** keluar dari game (Exit Game).\n%s", plr.Name, GetTimestamp())
        SendWebhookWithReaction("📴 Player Keluar Manual", desc, 0xe67e22, "🚪")
    end
end)

-- === Heartbeat (cek tiap 1 detik buat deteksi FC) ===
task.spawn(function()
    while task.wait(1) do
        if LocalPlayer and LocalPlayer.Parent == Players then
            lastSeen = tick()
        else
            if not alreadyOffline then
                alreadyOffline = true
                local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
                if tick() - lastSeen <= 2 then
                    local desc = string.format("💥 **%s** keluar tiba-tiba (Force Close).\n%s", playerName, GetTimestamp())
                    SendWebhookWithReaction("⚠️ Player Force Close", desc, 0xd35400, "💥")
                else
                    local desc = string.format("👤 **%s** terdeteksi disconnect (Unknown).\n%s", playerName, GetTimestamp())
                    SendWebhookWithReaction("📴 Player Offline", desc, 0xe74c3c, "❌")
                end
            end
            break
        end
    end
end)

-- === Monitor 5 menit (Ban/Kick) ===
task.spawn(function()
    while task.wait(300) do
        if alreadyOffline then break end
        local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
        if not (LocalPlayer and LocalPlayer.Parent == Players) then
            alreadyOffline = true
            local desc = string.format("⛔ Akun **%s** dikeluarkan paksa (Ban/Kick).\n%s", playerName, GetTimestamp())
            SendWebhookWithReaction("🚫 Player Banned / Kicked", desc, 0xf1c40f, "⛔")
            break
        end
    end
end)

-- ======================
-- Auto Hop Summit Limit
-- ======================
TabSettings:CreateSection("Atur Limit Summit")
TabSettings:CreateSlider({
    Name = "⛰️ Limit Summit sebelum Auto Hop",
    Range = {10, 500},   -- bisa atur minimal 10, maksimal 500
    Increment = 10,
    Suffix = " summit",
    CurrentValue = SummitAutoHopLimit,
    Flag = "SummitHopLimit",
    Callback = function(Value)
        SummitAutoHopLimit = Value
        Rayfield:Notify({
            Title = "Auto Hop Updated",
            Content = "Limit summit diubah ke "..Value,
            Duration = 3
        })
    end
})

-- buat tab Misc dulu kalau belum ada
local TabMisc = Window:CreateTab("Misc 🛠️")
TabMisc:CreateSection("Reset Summit")
local function UpdateSummitLabel()
    local text = "Summit: " .. (summitStats.count or 0) ..
                 " | Total Global: " .. (GlobalStats.TotalSummits or 0) ..
                 " | Last: " .. (summitStats.lastTime and FormatTimeSec(summitStats.lastTime) or "-")

    -- update TabDetector
    SummitLabel:Set(text)


end
-- 3️⃣ Tombol reset stats yang memanggil fungsi UpdateSummitLabel()
local ResetButton = TabMisc:CreateButton({
    Name = "🗑️ Reset Summit",
    Callback = function()
        -- hapus file Config.json lokal
        pcall(function() 
            if isfile("DetektorSummit/Config.json") then
                delfile("DetektorSummit/Config.json")
            end
        end)

        -- reset stats di memori
        summitStats = { count = 0, lastTime = nil, lastRespawn = nil }
        GlobalStats = { TotalSummits = 0 }

        -- update UI otomatis
        UpdateSummitLabel()

        -- notifikasi
        Rayfield:Notify({
            Title = "✅ Summit Direset",
            Content = "Stats lokal dan Global telah di-reset.",
            Duration = 4
        })

        print("[Info] File berhasil dihapus dan stats di-reset.")
    end
})



-- leaderstat watcher
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

-- position watcher
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
-- Part 5: Main loop & PlayerAdded
-- =========================

local function StartMainScanner()
    Players.PlayerAdded:Connect(function(pl)
        task.spawn(function()
            task.wait(0.45)
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end)
    end)

    task.spawn(function()
        while true do
            local players = Players:GetPlayers()
            pcall(function() PlayersLabel:Set("Players: "..tostring(#players)) end)
            for _,pl in ipairs(players) do
                if pl ~= LocalPlayer then
                    pcall(function() CheckPlayerForAdminEnhanced(pl) end)
                end
            end
            pcall(function() StatusLabel:Set("Status: Running | Players: " .. tostring(#players)) end)
            task.wait(math.max(0.2, Config.ScanInterval or 2.5))
        end
    end)
end

-- =========================
-- Part 6: Init & Start
-- =========================

-- Start watchers based on config
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcherEnhanced()
else
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
end

-- Start scanner
StartMainScanner()

-- notify ready
Notify("Detektor Aktif", "Admin & Summit Detector berjalan. Periksa tab HWID bila perlu.")
Log("Detektor initialized. Version:", _VERSION, "StartTick:", StartTick)

-- End of script

Rayfield:LoadConfiguration()

else
    -- Kalau HWID tidak terdaftar
    HWIDTab:CreateParagraph({
        Title = "⚠️ HWID Tidak Terdaftar",
        Content = "HWID kamu belum terdaftar.\n\n" .. hwid
    })

    HWIDTab:CreateButton({
        Name = "Salin HWID",
        Callback = function()
            setclipboard(hwid)
            Rayfield:Notify({
                Title = "Disalin",
                Content = "HWID kamu sudah disalin. Kirim ke owner untuk didaftarkan.",
                Duration = 6
            })
        end,
    })
end
