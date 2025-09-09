--=====================================================
-- 🛡️ DETECTOR FINAL (Part 1/2)
-- Fitur:
-- - Deteksi Admin (ESP + Auto Leave + Auto Hop)
-- - Summit Counter (notif webhook embed)
-- - Status Player, Lama Main, Jumlah Summit
-- - Webhook keren dengan emoji & sensor nama
--=====================================================

-- 🟢 Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- 🟢 Config
local WebhookURL = "https://discord.com/api/webhooks/XXXX/XXXX" -- GANTI LINKMU
local StartTime = tick()
local SummitCount = 0
local DetectedAdmins = {}
local PlayerName = LocalPlayer.Name
local HiddenName = "||" .. PlayerName .. "||"

-- 🟢 Admin Blacklist
local Blacklist = {
    "YAHAVUKazigen","Dim","eugyne","VBZ","HeruAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

-- 🟢 Helper : Format Waktu
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02dh:%02dm:%02ds", h, m, s)
end

-- 🟢 Helper : Kirim Webhook Embed
local function SendWebhookEmbed(title, desc, color, fields)
    local data = {
        username = "🛡️ Detector Bot",
        avatar_url = "https://i.imgur.com/WxXHKvK.png",
        embeds = {{
            title = title,
            description = desc,
            color = color,
            fields = fields or {},
            footer = {
                text = "🕒 " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }

    local success, err = pcall(function()
        HttpService:PostAsync(
            WebhookURL,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if not success then
        warn("❌ Gagal kirim webhook:", err)
    end
end

-- 🟢 Contoh Kirim Webhook Awal
SendWebhookEmbed(
    "✅ Detector Aktif",
    "Player: " .. HiddenName .. "\nServer PlaceId: **" .. PlaceId .. "**",
    65280, -- hijau
    {
        { name = "⏳ Waktu Mulai", value = os.date("%H:%M:%S"), inline = true },
        { name = "👥 Jumlah Player", value = tostring(#Players:GetPlayers()), inline = true }
    }
)

-- 🟢 Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detector",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Final Build 🚀",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DetektorSummit",
        FileName = "Config"
    },
    
    KeySystem = false
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
-- Tab utama
local DetectionTab = Window:CreateTab("🔍 Detection", 4483362458)
DetectionTab:CreateParagraph({Title="🛡️ Status", Content="Detector aktif, siap jalan..."})

--===========================================================
-- FULL Admin & Summit Detector (siap-tempel dan jalan langsung)
-- By: ChatGPT (modifikasi lengkap untuk kebutuhanmu)
-- WARNING: webhook digabung permanen di bawah (ganti jika mau)
-- Features:
--  - Deteksi admin via blacklist, nama/rank keyword, GUI text
--  - Webhook embed ke Discord (dengan info copyable nama admin)
--  - AutoHop (cari server lain & teleport), AutoLeave (kick)
--  - Summit counter (leaderstat or Y threshold)
--  - Rayfield UI controls (toggle, interval, webhook test, info)
--  - Safe HTTP method selection (syn.request/http_request/request/game:HttpPost)
--===========================================================

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Config (hard-coded webhook PERMANEN di sini) =====
local Config = {
    AutoHop = true,            -- Auto hop ke server lain saat admin terdeteksi
    AutoLeave = false,         -- Auto kick (jika ingin kick instead of hop)
    SendWebhook = true,        -- Kirim semua notif ke Discord
    ScanInterval = 2.5,        -- interval scan admin (detik)
    SummitDetectMethod = "leaderstat", -- "leaderstat" or "position"
    SummitPositionY = 1000,    -- jika pakai position, threshold Y untuk anggap "summit"
    SummitPositionHold = 1.2,  -- harus bertahan di atas threshold (detik)
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/rjde-YwMH6pOi9Dk7LzQhlbCg1RGhYvouHgwrz_dYJi8amlIQLImuHnRXlLot-1mFfUU", -- <--- GANTI bila perlu
    WebhookUsername = "🛡️ Detector Bot",
    WebhookAvatar = "https://i.imgur.com/WxXHKvK.png",
    AdminCooldown = 6,         -- cooldown antar deteksi supaya ga spam
    ServerSearchPages = 6,     -- pages to check when searching for servers
}

-- ===== Blacklist (sesuai permintaan) =====
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

-- Rank keywords (untuk cek GUI text uppercase)
local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- ===== Utilities =====
local function lower(s) return (type(s) == "string" and string.lower(s) or "") end
local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02dm:%02ds", m, s)
end

-- ===== HTTP POST wrapper (safe, multi-method) =====
local function HttpPost(url, body)
    local bodyJson = (type(body) == "string") and body or HttpService:JSONEncode(body)
    -- try executor-specific request functions
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = bodyJson }) end)
        if ok then return true, res end
    end
    if (type(http_request) == "function") then
        local ok, res = pcall(function() return http_request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = bodyJson }) end)
        if ok then return true, res end
    end
    if (type(request) == "function") then
        local ok, res = pcall(function() return request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = bodyJson }) end)
        if ok then return true, res end
    end
    if http and http.request then
        local ok, res = pcall(function() return http.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = bodyJson }) end)
        if ok then return true, res end
    end
    -- fallback to game:HttpPost (may error in modern env)
    local ok, res = pcall(function() return game:HttpPost(url, bodyJson, Enum.HttpContentType.ApplicationJson) end)
    if ok then return true, res end
    return false, "no-http-method"
end

-- ===== Webhook helpers (embed + plain) =====
local function SendWebhook(content)
    if not Config.SendWebhook then return false, "disabled" end
    local url = Config.WebhookURL
    if not url or url == "" then return false, "no webhook" end

    local payload = {
        username = Config.WebhookUsername,
        avatar_url = Config.WebhookAvatar,
        content = nil,
        embeds = {
            {
                title = "🔔 Detector Notification",
                description = content,
                color = 14177041,
                footer = {
                    text = "Detector • " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }
    }

    local ok, res = HttpPost(url, payload)
    if not ok then
        warn("SendWebhook failed:", res)
        return false, res
    end
    return true
end

local function SendWebhookEmbedDetailed(title, description, fields, color)
    if not Config.SendWebhook then return false, "disabled" end
    local url = Config.WebhookURL
    if not url or url == "" then return false, "no webhook" end

    local embed = {
        title = title,
        description = description,
        color = color or 65280,
        fields = fields or {},
        footer = { text = "Detector • " .. os.date("%Y-%m-%d %H:%M:%S") }
    }

    local payload = {
        username = Config.WebhookUsername,
        avatar_url = Config.WebhookAvatar,
        embeds = { embed }
    }

    local ok, res = HttpPost(url, payload)
    if not ok then
        warn("SendWebhookEmbed failed:", res)
        return false, res
    end
    return true
end

-- ===== Rayfield window (create new window) =====
local ok, Rayfield = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
if not ok or not Rayfield then
    warn("Rayfield gagal dimuat. Pastikan URL accesible di envmu.")
    -- continue without UI (still functional)
end

local Window
local DetTab
local AdminLabel, SummitLabel, StatusLabel
if Rayfield then
    Window = Rayfield:CreateWindow({
        Name = "🛡️ Detektor",
        LoadingTitle = "Admin & Summit Detector",
        LoadingSubtitle = "Siap jalan",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DetectorConfig",
            FileName = "detector"
        }
    })

    DetTab = Window:CreateTab("Detektor")

    local function CreateLabel(text)
        if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(text) end
        return { Set = function() end }
    end
    local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end end
    local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end end
    local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end end
    local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield:Notify({ Title = title, Content = content, Duration = 5 }) else warn(title, content) end end

    AdminLabel = CreateLabel("Admin Terdeteksi: -")
    SummitLabel = CreateLabel("Summit: 0 | Last: 00m:00s")
    StatusLabel = CreateLabel("Status: Idle")

    -- UI Controls
    CreateToggle({ Name = "🌍 Auto Hop jika Admin", CurrentValue = Config.AutoHop, Callback = function(v) Config.AutoHop = v end })
    CreateToggle({ Name = "🚪 Auto Leave (Kick) jika Admin", CurrentValue = Config.AutoLeave, Callback = function(v) Config.AutoLeave = v end })
    CreateToggle({ Name = "📲 Kirim Notif ke Discord (Webhook)", CurrentValue = Config.SendWebhook, Callback = function(v) Config.SendWebhook = v end })
    CreateTextBox({ Name = "Webhook URL (permanen di script, bisa ubah)", PlaceholderText = Config.WebhookURL, Text = Config.WebhookURL or "", Callback = function(txt) Config.WebhookURL = (txt ~= "" and txt) or Config.WebhookURL end })
    CreateTextBox({ Name = "Scan Interval (detik)", PlaceholderText = tostring(Config.ScanInterval), Text = tostring(Config.ScanInterval), Callback = function(txt) local n = tonumber(txt) if n and n >= 0.5 then Config.ScanInterval = n end end })
    CreateButton({ Name = "📡 Test Webhook", Callback = function()
        local ok, err = SendWebhookEmbedDetailed("✅ Test webhook dari Detektor", "Player: **" .. tostring(LocalPlayer and LocalPlayer.Name or "Unknown") .. "**\nEnvironment test", {
            { name = "PlaceId", value = tostring(PlaceId), inline = true },
            { name = "JobId", value = tostring(JobId), inline = true }
        }, 3447003)
        if ok then if Rayfield and Rayfield.Notify then Rayfield.Notify({ Title = "Webhook", Content = "Test terkirim", Duration = 4 }) end
        else if Rayfield and Rayfield.Notify then Rayfield.Notify({ Title = "Webhook Gagal", Content = tostring(err), Duration = 6 }) end end
    end })
end

-- local Notify fallback
local function NotifyFallback(title, content)
    if Rayfield and Rayfield.Notify then Rayfield.Notify({ Title = title, Content = content, Duration = 4 }) else warn(title, content) end
end

-- ===== Detection helpers =====
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

-- check GUI text above head: only consider strings that are ALL CAPS / digits / spaces
local function guiAdminDetect(player)
    if not player.Character then return false, nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false, nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
                    -- consider only uppercase+digits+spaces (and small chance punctuation)
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

-- combine all detection methods for admin
local handlingAdmin = false
local lastAdminDetectTime = 0
local adminCooldown = Config.AdminCooldown or 6

-- ===== Server hop (find other server) =====
local function serverHopAttempt()
    local maxPages = Config.ServerSearchPages or 6
    local pageCursor = nil
    local found = nil
    for page=1,maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then break end
        local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or not json or type(json.data) ~= "table" then break end
        for _,srv in ipairs(json.data) do
            if type(srv) == "table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id) ~= tostring(JobId) and srv.playing < srv.maxPlayers then
                    found = srv.id
                    break
                end
            end
        end
        if found then break end
        pageCursor = json.nextPageCursor
        if not pageCursor then break end
    end
    if found then
        -- teleport
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, found, LocalPlayer)
        end)
        return ok, err or found
    end
    return false, "no-server-found"
end

local function BuildAdminWebhookMessage(player, reason)
    local name = tostring(player and player.Name or "Unknown")
    local display = tostring(player and player.DisplayName or "")
    local pcount = #Players:GetPlayers()
    local status = (player and player.Parent) and "Online" or "Offline"
    local copyable = "```" .. name .. "```" -- so webhook message contains raw name block to copy

    local desc = string.format(
        "**Admin Detected**\n- Name: **%s**\n- Display: **%s**\n- Reason: %s\n- Status: %s\n- Players in server: %d\n\nCopy name untuk tindakan: %s",
        name, display, tostring(reason or "-"), status, pcount, copyable
    )
    return desc, name
end

local function handleAdminDetected(player, reason)
    if handlingAdmin then return end
    local now = tick()
    if now - lastAdminDetectTime < adminCooldown then return end
    handlingAdmin = true
    lastAdminDetectTime = now

    local desc, adminName = BuildAdminWebhookMessage(player, reason)

    -- update UI
    pcall(function() if AdminLabel then AdminLabel:Set("Admin Terdeteksi: " .. tostring(adminName) .. " (" .. tostring(reason) .. ")") end end)
    pcall(function() if StatusLabel then StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(adminName)) end end)

    -- send webhook embed (includes copyable name)
    pcall(function() SendWebhookEmbedDetailed("⚠️ Admin Detected: " .. tostring(adminName), desc, {
        { name = "PlaceId", value = tostring(PlaceId), inline = true },
        { name = "JobId", value = tostring(JobId), inline = true },
        { name = "ActionButtons", value = "[Teleport to place](" .. "https://www.roblox.com/games/"..tostring(PlaceId) ..")", inline = true },
    }, 16744448) end)

    -- in-game notify
    pcall(function() NotifyFallback("⚠️ Admin Terdeteksi", tostring(adminName) .. " (" .. tostring(reason) .. ")") end)

    -- action: hop or leave
    if Config.AutoHop then
        task.spawn(function()
            task.wait(0.6)
            local ok, res = pcall(serverHopAttempt)
            if ok and res then
                -- nothing: Teleport already initiated in serverHopAttempt
            else
                -- jika gagal hop, fallback: kick jika AutoLeave
                if Config.AutoLeave then
                    pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(adminName)) end)
                end
            end
        end)
    elseif Config.AutoLeave then
        task.spawn(function()
            task.wait(0.6)
            pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(adminName)) end)
        end)
    end

    -- small cooldown before allowing new handling
    task.delay(8, function() handlingAdmin = false end)
end

-- single-player check wrapper
local function CheckPlayerForAdmin(player)
    if not player then return false end
    -- ignore LocalPlayer (safety)
    if player == LocalPlayer then return false end

    local ok, reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then
        handleAdminDetected(player, reason)
        return true
    end
    local ok2, reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then
        handleAdminDetected(player, reason2)
        return true
    end
    local ok3, reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then
        handleAdminDetected(player, reason3)
        return true
    end
    return false
end

-- ===== Summit tracking (self) =====
local mySummitCount = 0
local myLastRespawn = tick()
local myLastSummitTime = 0

-- reset respawn time on CharacterAdded
if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function()
        myLastRespawn = tick()
        pcall(function() if SummitLabel then SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime)) end end)
    end)
end

local function OnSummitReached(extra)
    local now = tick()
    local timeTaken = math.floor(now - myLastRespawn)
    myLastSummitTime = timeTaken
    mySummitCount = mySummitCount + 1
    pcall(function() if SummitLabel then SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime)) end end)

    local msg = ("✅ Summit Reached!\nPlayer: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s\n%s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        mySummitCount,
        myLastSummitTime,
        FormatTimeSec(myLastSummitTime),
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S"),
        extra or ""
    )
    pcall(function() SendWebhookEmbedDetailed("🏔️ Summit Reached", msg, {
        { name = "Summit Count", value = tostring(mySummitCount), inline = true },
        { name = "LastTime", value = FormatTimeSec(myLastSummitTime), inline = true }
    }, 3066993) end)
    NotifyFallback("🏔️ Summit", "Summit tercapai! Waktu: " .. tostring(FormatTimeSec(myLastSummitTime)))
    myLastRespawn = tick()
end

-- Leaderstat watcher (monitor leaderstats.Summit)
local leaderstatWatching = false
local function TryStartLeaderstatWatcher()
    if leaderstatWatching then return end
    leaderstatWatching = true
    task.spawn(function()
        while true do
            if not LocalPlayer or not LocalPlayer.Parent then break end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Summit") and typeof(ls.Summit.Value) == "number" then
                local lastVal = ls.Summit.Value
                ls.Summit.Changed:Connect(function(newVal)
                    pcall(function()
                        if type(newVal) == "number" and newVal > lastVal then
                            lastVal = newVal
                            OnSummitReached("Detected via leaderstat change")
                        else
                            lastVal = newVal
                        end
                    end)
                end)
                break
            end
            task.wait(1)
        end
    end)
end

-- Position-based detection fallback
local positionHoldTimer = 0
local function TryStartPositionWatcher()
    task.spawn(function()
        while true do
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                if hrp.Position.Y >= (Config.SummitPositionY or 1000) then
                    positionHoldTimer = positionHoldTimer + 0.5
                    if positionHoldTimer >= (Config.SummitPositionHold or 1.2) then
                        OnSummitReached("Detected via position Y threshold")
                        positionHoldTimer = 0
                        task.wait(3) -- small cooldown after detection
                    end
                else
                    positionHoldTimer = 0
                end
            end
            task.wait(0.5)
        end
    end)
end

-- start chosen summit detection method(s)
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcher()
else
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
end

-- ===== Main scanner loop =====
task.spawn(function()
    while true do
        local players = Players:GetPlayers()
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdmin(pl) end)
            end
        end
        pcall(function() if StatusLabel then StatusLabel:Set("Status: Running | Players: " .. tostring(#players)) end end)
        task.wait(Config.ScanInterval or 2.5)
    end
end)

-- ===== Initial UI / Webhook notification =====
pcall(function()
    if AdminLabel then AdminLabel:Set("Admin Terdeteksi: -") end
    if SummitLabel then SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime)) end
    if StatusLabel then StatusLabel:Set("Status: Idle") end
end)

pcall(function()
    SendWebhookEmbedDetailed("🟢 Detector Aktif", "Admin & Summit Detector berjalan. Webhook permanen disimpan di script.", {
        { name = "Player", value = tostring(LocalPlayer and LocalPlayer.Name or "Unknown"), inline = true },
        { name = "PlaceId", value = tostring(PlaceId), inline = true },
        { name = "ScanInterval", value = tostring(Config.ScanInterval), inline = true }
    }, 3066993)
end)

NotifyFallback("Detektor Aktif", "Admin & Summit Detector berjalan. Webhook permanen disimpan di script.")

-- ========================
-- Tab Teleport
-- ========================
local TeleTab = Window:CreateTab("Teleport", 4483362458)

-- Variabel delay default (khusus auto teleport)
local AutoTeleportDelay = 2


local teleportPoints = {
    Spawn = CFrame.new(-932, 170, 881),
    CP1 = CFrame.new(-418, 250, 766),
    CP2 = CFrame.new(-347, 389, 522),
    CP3 = CFrame.new(288, 430, 506),
    CP4 = CFrame.new(334, 491, 349),
    CP5 = CFrame.new(210, 315, -148),
    Puncak = CFrame.new(-587, 906, -511),
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
    teleportPoints.Puncak,
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
    Name = "⚡ Auto Teleport )",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(Value)
        isAutoTeleporting = Value
        if Value then
            autoTeleportTask = task.spawn(function()
                local player = game.Players.LocalPlayer
                while isAutoTeleporting do
                    -- Teleport dari CP1 sampai Puncak
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
                        waited += 0.5
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
