-- =========================
-- Rayfield Loader (safe)
-- =========================
local success, RayfieldOrErr = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not RayfieldOrErr then
    warn("Rayfield gagal dimuat. Pastikan URL dapat diakses atau executor mendukung HttpGet.")
    if typeof(RayfieldOrErr) == "string" then warn("Detail error:", RayfieldOrErr) end
    return
end
local Rayfield = RayfieldOrErr

-- =========================
-- Services
-- =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- =========================
-- Default Config
-- =========================
local Config = {
    AutoHop = true,            -- Auto hop ke server lain saat admin terdeteksi
    AutoLeave = false,         -- Auto kick jika tidak hop
    SendWebhook = true,        -- Kirim notif ke Discord
    ScanInterval = 2.5,        -- Interval scan (detik)
    SummitDetectMethod = "leaderstat", -- "leaderstat"/"position"/"both"
    SummitPositionY = 1000,    -- Threshold Y jika pakai position
    SummitPositionHold = 1.2,  -- Waktu bertahan di atas threshold
    WebhookURL = "",           -- URL default
    WebhookUseEmbed = true,    -- Embed payload
    DetectionCooldown = 6,     -- Waktu minimal antar deteksi
    IgnoreFriends = true,      -- Ignore friends
    VerboseLogging = true,     -- Banyak log
    NotifyInGame = true,       -- Rayfield notify
}

-- =========================
-- Blacklist & Rank Keywords
-- =========================
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}
local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- =========================
-- Logging & Utilities
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
        for i=1,500 do table.remove(LogHistory,1) end
    end
    if Config.VerboseLogging then
        pcall(function() print("[Detektor] "..os.date("%H:%M:%S").." - "..line) end)
    end
end

local function safeCall(fn,...)
    local ok,res = pcall(fn,...)
    if not ok then Log("safeCall error:",res) return nil,res end
    return res
end

local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec/60)
    local s = sec % 60
    return string.format("%02dm:%02ds", m,s)
end

local function CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
            if Config.NotifyInGame then
                Rayfield:Notify({Title="Clipboard", Content="Teks disalin ke clipboard.", Duration=3})
            end
        end
    end)
end

-- =========================
-- Webhook Sender (Safe)
-- =========================
local function BuildWebhookPayload(title,description,extra)
    extra = extra or {}
    if Config.WebhookUseEmbed then
        local embed = {
            title=title,
            description=description,
            color=extra.color or 16753920,
            timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
            fields=extra.fields or {},
            footer={text=_VERSION}
        }
        return HttpService:JSONEncode({embeds={embed}})
    else
        return HttpService:JSONEncode({content=("**%s**\n%s"):format(title,description)})
    end
end

local function SendWebhookRaw(url,body)
    local ok,err
    if syn and syn.request then
        ok,err = pcall(function() syn.request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif http_request then
        ok,err = pcall(function() http_request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif request then
        ok,err = pcall(function() request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif http and http.request then
        ok,err = pcall(function() http.request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    else
        ok,err = pcall(function() game:HttpPost(url,body,Enum.HttpContentType.ApplicationJson) end)
    end
    if not ok then Log("SendWebhookRaw failed:",tostring(err)) return false,tostring(err) end
    return true
end

function SendWebhook(title,description,extra)
    if not Config.SendWebhook then
        Log("SendWebhook disabled")
        return false,"disabled"
    end
    local url = Config.WebhookURL
    if not url or url=="" or url:find("PUT_YOUR_WEBHOOK") then
        Log("SendWebhook: webhook not set or placeholder")
        return false,"no webhook"
    end
    local body = BuildWebhookPayload(title,description,extra)
    return SendWebhookRaw(url,body)
end
-- =========================
-- Window & Tabs
-- =========================
local Window = Rayfield:CreateWindow({
    Name = "🛡️ VIP :MT : Yahayuk",
    LoadingTitle = "Fitur Admin Deteksi",
    LoadingSubtitle = "Sedang Loading...🚀",
    ConfigurationSaving = {
        Enabled=true,
        FolderName="DetektorSummit",
        FileName="Config"
    }
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

-- // Helper kecil UI
local function CreateLabel(tab,text) if tab and tab.CreateLabel then return tab:CreateLabel(text) end return {Set=function() end} end
local function CreateToggle(tab,opts) if tab and tab.CreateToggle then return tab:CreateToggle(opts) end end
local function CreateButton(tab,opts) if tab and tab.CreateButton then return tab:CreateButton(opts) end end
local function CreateTextBox(tab,opts) if tab and tab.CreateTextBox then return tab:CreateTextBox(opts) end end
local function CreateParagraph(tab,opts) if tab and tab.CreateParagraph then return tab:CreateParagraph(opts) end end
local function Notify(title,content) if Rayfield and Rayfield.Notify then Rayfield:Notify({Title=title,Content=content,Duration=5}) else warn(title,content) end end

-- =========================
-- Tabs
-- =========================
local TeleTab = Window:CreateTab("Teleport", 4483362458)
local TabDetector = Window:CreateTab("Detektor")
local TabSummit = Window:CreateTab("Summit")
local TabSettings = Window:CreateTab("Settings")
local TabAdvanced = Window:CreateTab("Advanced")

-- Variabel delay default (khusus auto teleport)
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

-- =========================
-- Detector Tab UI
-- =========================
local AdminLabel = CreateLabel(TabDetector,"Admin Terdeteksi: -")
local StatusLabel = CreateLabel(TabDetector,"Status: Idle")
local PlayersLabel = CreateLabel(TabDetector,"Players: 0")

local btnManualScan = CreateButton(TabDetector,{
    Name="🔎 Manual Scan Sekarang",
    Callback=function()
        Log("Manual scan started")
        for _,pl in ipairs(Players:GetPlayers()) do
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end
        Notify("Manual Scan","Selesai memindai pemain.")
    end
})

local btnShowLog = CreateButton(TabDetector,{
    Name="📜 Copy Recent Log",
    Callback=function()
        local text = ""
        for i=math.max(1,#LogHistory-80),#LogHistory do
            local e = LogHistory[i]
            if e then text = text.."["..e.time.."] "..e.text.."\n" end
        end
        CopyToClipboard(text)
        Notify("Log disalin","Recent log disalin ke clipboard.")
    end
})

-- =========================
-- Summit Tab UI
-- =========================
local summitStats = {count=0,totalTime=0,lastTime=0,lastRespawn=tick()}
local SummitLabel = CreateLabel(TabSummit,"Summit: 0 | Total Time: 00m:00s | Last: 00m:00s")
local btnResetSummit = CreateButton(TabSummit,{
    Name="♻️ Reset Summit Stats",
    Callback=function()
        summitStats.count=0
        summitStats.totalTime=0
        summitStats.lastTime=0
        summitStats.lastRespawn=tick()
        pcall(function() SummitLabel:Set("Summit: 0 | Total Time: 00m:00s | Last: 00m:00s") end)
        Notify("Summit","Stats summit direset.")
    end
})

-- =========================
-- Settings Tab UI
-- =========================
CreateParagraph(TabSettings,{Title="Webhook",Content="Atur webhook untuk menerima notifikasi. Gunakan 'Test Webhook' untuk cek."})
local inputWebhook = CreateTextBox(TabSettings,{Name="Webhook URL",PlaceholderText=Config.WebhookURL,Text=Config.WebhookURL or "",Callback=function(txt) Config.WebhookURL=txt or Config.WebhookURL end})
local toggleSendWebhookUI = CreateToggle(TabSettings,{Name="Kirim Notif ke Discord",CurrentValue=Config.SendWebhook,Callback=function(v) Config.SendWebhook=v end})
local toggleWebhookEmbedUI = CreateToggle(TabSettings,{Name="Gunakan Embed di Webhook",CurrentValue=Config.WebhookUseEmbed,Callback=function(v) Config.WebhookUseEmbed=v end})

-- Input webhook
local inputWebhook2 = TabSettings:CreateInput({
    Name="Masukkan Webhook",
    PlaceholderText="https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost=false,
    Flag="WebhookURL",
    Callback=function(Text)
        if Text and Text~="" then
            Config.WebhookURL=Text
            Notify("Webhook","URL webhook disimpan: "..Text)
        else
            Config.WebhookURL=nil
            Notify("Webhook","URL webhook dihapus.")
        end
    end
})

-- Tombol hapus webhook
local btnClearWebhook = TabSettings:CreateButton({
    Name="🗑️ Hapus Webhook",
    Callback=function()
        Config.WebhookURL=nil
        inputWebhook2:Set("") -- kosongkan input
        Notify("Webhook","URL webhook telah dihapus.")
    end
})

-- Tombol test webhook
local btnTestWebhook = TabSettings:CreateButton({
    Name="📡 Test Webhook",
    Callback=function()
        if not Config.WebhookURL or Config.WebhookURL=="" then
            Notify("Webhook Gagal","⚠️ Belum ada URL webhook yang diset.")
            return
        end
        local ok,err=SendWebhook("✅ Test Webhook","Ini pesan test dari kamu. URL sudah disimpan.")
        if ok then
            Notify("Webhook","Test terkirim!")
        else
            Notify("Webhook Gagal",tostring(err))
        end
    end
})

-- Detection settings
CreateParagraph(TabSettings,{Title="Detection",Content="Atur interval scan, behavior auto-hop/leave, dan opsi ignore friend."})
local inputScanInterval = CreateTextBox(TabSettings,{Name="Scan Interval (detik)",PlaceholderText=tostring(Config.ScanInterval),Text=tostring(Config.ScanInterval),Callback=function(txt)local n=tonumber(txt) if n and n>=0.2 then Config.ScanInterval=n end end})
local toggleAutoHopUI = CreateToggle(TabSettings,{Name="Auto Hop Jika Admin",CurrentValue=Config.AutoHop,Callback=function(v) Config.AutoHop=v end})
local toggleAutoLeaveUI = CreateToggle(TabSettings,{Name="Auto Leave (kick) Jika Admin",CurrentValue=Config.AutoLeave,Callback=function(v) Config.AutoLeave=v end})
local toggleIgnoreFriendsUI = CreateToggle(TabSettings,{Name="Ignore Friends",CurrentValue=Config.IgnoreFriends,Callback=function(v) Config.IgnoreFriends=v end})
-- =========================
-- Admin Detection Core
-- =========================

local handlingAdmin = false
local lastAdminDetect = 0

-- alias untuk versi enhanced
serverHopAttempt = serverHopAttemptEnhanced

-- lakukan escape: hop atau leave
local function performEscapeAction(playerName, reason)
    if Config.AutoHop then
        local ok, err = pcall(function() return serverHopAttempt() end)
        if ok then
            SendWebhook("⚠️ Admin Detected - Attempting Hop",
                ("Detected **%s** (%s). Attempting server hop. 🛫"):format(playerName, reason),
                {color=16766720})
            return true
        else
            Log("AutoHop attempt failed for", playerName)
            Notify("AutoHop Failed","Gagal hop server untuk "..playerName.." ("..tostring(err)..")")
            if Config.AutoLeave then pcall(function() LocalPlayer:Kick("Admin terdeteksi: "..playerName) end) end
        end
    elseif Config.AutoLeave then
        pcall(function() LocalPlayer:Kick("Admin terdeteksi: "..playerName) end)
    end
    return false
end

-- handler enhanced admin detection
local function handleAdminDetectedEnhanced(player, reason)
    if handlingAdmin then return end
    local now = tick()
    if now - lastAdminDetect < Config.DetectionCooldown then
        Log("handleAdminDetectedEnhanced: cooldown")
        return
    end
    handlingAdmin = true
    lastAdminDetect = now

    local pname = (player and player.Name) or "Unknown"
    local pdisplay = (player and player.DisplayName) or pname
    local status = (player and player:IsDescendantOf(game)) and "Online" or "Offline"

    if reason then
        local msg = ("⚠️ Admin Detected: **%s** (%s)\nReason: %s\nStatus: %s\nPlaceId: %d\nTime: %s 🚨"):format(
            pname, pdisplay, reason, status, PlaceId, os.date("%Y-%m-%d %H:%M:%S")
        )

        pcall(function() AdminLabel:Set("Admin Terdeteksi: "..pname.." ("..reason..")") end)
        pcall(function() StatusLabel:Set("Status: Admin terdeteksi - "..pname) end)

        Log("Detected admin:", pname, reason)

        -- send webhook enhanced
        pcall(function()
            SendWebhook(("⚠️ Admin Detected — %s"):format(pname), msg, {
                color=15158332,
                fields={
                    {name="Player",value=pname,inline=true},
                    {name="Display",value=pdisplay,inline=true},
                    {name="Reason",value=tostring(reason),inline=false},
                    {name="ServerId",value=tostring(JobId),inline=true},
                    {name="PlaceId",value=tostring(PlaceId),inline=true}
                }
            })
        end)
    end

    if Config.NotifyInGame then
        Notify("⚠️ Admin Terdeteksi", "🛡️ "..pname.." ("..tostring(reason)..")")
    end
    pcall(function() CopyToClipboard(pname) end)
    task.spawn(function()
        task.wait(0.6)
        performEscapeAction(pname, reason)
    end)
    task.delay(8,function() handlingAdmin=false end)
end

-- =========================
-- Check player for admin traits
-- =========================
function CheckPlayerForAdminEnhanced(player)
    if not player or player==LocalPlayer then return false end
    if Config.IgnoreFriends and IsFriend(player) then
        if Config.VerboseLogging then Log("Ignored friend:",player.Name) end
        return false
    end

    -- Blacklist check
    local ok, reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then
        handleAdminDetectedEnhanced(player,reason)
        return reason
    end

    -- Rank keyword in name
    local ok2, reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then
        handleAdminDetectedEnhanced(player,reason2)
        return reason2
    end

    -- GUI overlay check
    local ok3, reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then
        handleAdminDetectedEnhanced(player,reason3)
        return reason3
    end

    -- additional heuristic: unusual humanoid movement
    pcall(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            local ws = hum.WalkSpeed or 16
            local jp = hum.JumpPower or 0
            if ws>60 or jp>220 then
                local reason4 = ("UnusualMovement(ws=%s,jp=%s)"):format(ws,jp)
                handleAdminDetectedEnhanced(player,reason4)
                return reason4
            end
        end
    end)

    return false
end

-- =========================
-- Summit Detection
-- =========================
local function UpdateSummitStatus()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local posY = LocalPlayer.Character.HumanoidRootPart.Position.Y
    if posY >= Config.SummitPositionY then
        local t0 = tick()
        task.wait(Config.SummitPositionHold)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position.Y >= Config.SummitPositionY then
            local t1 = tick()
            local dt = t1-t0
            summitStats.totalTime = summitStats.totalTime+dt
            summitStats.lastTime = dt
            summitStats.count = summitStats.count+1
            pcall(function()
                SummitLabel:Set(("Summit: %d | Total Time: %s | Last: %s 🏔️"):format(
                    summitStats.count, FormatTimeSec(summitStats.totalTime), FormatTimeSec(summitStats.lastTime)
                ))
            end)
        end
    end
end

-- =========================
-- Periodic Tasks
-- =========================
task.spawn(function()
    while task.wait(Config.ScanInterval) do
        for _,pl in ipairs(Players:GetPlayers()) do
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end
        UpdateSummitStatus()
    end
end)
-- =========================
-- Advanced Tab
-- =========================

-- Toggle Verbose Logging
local toggleVerboseLoggingUI = TabAdvanced:CreateToggle({
    Name = "Verbose Logging 🔍",
    CurrentValue = Config.VerboseLogging,
    Callback = function(v)
        Config.VerboseLogging = v
        Notify("Verbose Logging", v and "Aktif" or "Nonaktif")
    end
})

-- Toggle Notify InGame
local toggleNotifyInGameUI = TabAdvanced:CreateToggle({
    Name = "In-Game Notifications 💬",
    CurrentValue = Config.NotifyInGame,
    Callback = function(v)
        Config.NotifyInGame = v
        Notify("In-Game Notif", v and "Aktif" or "Nonaktif")
    end
})

-- AutoHop + AutoLeave
local toggleAutoHopUI2 = TabAdvanced:CreateToggle({
    Name = "Auto Hop 🛫 Jika Admin",
    CurrentValue = Config.AutoHop,
    Callback = function(v)
        Config.AutoHop = v
        Notify("Auto Hop", v and "Aktif" or "Nonaktif")
    end
})

local toggleAutoLeaveUI2 = TabAdvanced:CreateToggle({
    Name = "Auto Leave ❌ Jika Admin",
    CurrentValue = Config.AutoLeave,
    Callback = function(v)
        Config.AutoLeave = v
        Notify("Auto Leave", v and "Aktif" or "Nonaktif")
    end
})

-- Input Scan Interval
local inputScanInterval2 = TabAdvanced:CreateTextBox({
    Name = "Scan Interval (detik) ⏱️",
    PlaceholderText = tostring(Config.ScanInterval),
    Text = tostring(Config.ScanInterval),
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n>=0.2 then
            Config.ScanInterval = n
            Notify("Scan Interval", "Interval diatur ke "..n.." detik")
        end
    end
})

-- =========================
-- AutoHop Feedback Notif
-- =========================
local function NotifyAutoHop(playerName, reason, success, msg)
    local title = success and "Auto Hop Sukses 🛫" or "Auto Hop Gagal ⚠️"
    local content = ("Player: %s\nReason: %s\nMessage: %s"):format(playerName, reason, msg or "-")
    Notify(title, content)
end

-- =========================
-- Hook teleport to auto notif
-- =========================
local oldTeleport = TeleportService.TeleportToPlaceInstance
function TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    local ok, err = pcall(function()
        if player then
            oldTeleport(self, placeId, serverId, player)
        else
            oldTeleport(self, placeId, serverId)
        end
    end)
    if not ok then
        Log("TeleportToPlaceInstance error:", err)
        Notify("Teleport Gagal ⚠️", err)
    else
        Log("TeleportToPlaceInstance called:", serverId)
        Notify("Teleport 🚀", "Berhasil teleport ke server "..tostring(serverId))
    end
end

-- =========================
-- Summit Stats Storage
-- =========================
summitStats = {
    count = 0,
    lastTime = 0,
    totalTime = 0,
    lastRespawn = tick()
}

-- =========================
-- Copy Summit Stats
-- =========================
local btnCopySummit = TabSummit:CreateButton({
    Name = "📋 Copy Stats Summit",
    Callback = function()
        local text = ("Summit Count: %d\nTotal Time: %s\nLast Time: %s"):format(
            summitStats.count,
            FormatTimeSec(summitStats.totalTime),
            FormatTimeSec(summitStats.lastTime)
        )
        CopyToClipboard(text)
        Notify("Summit Stats", "Disalin ke clipboard 🏔️")
    end
})

-- =========================
-- Reset Summit Stats already in Part 3
-- =========================

-- =========================
-- Admin Detection UI Enhancements
-- =========================
local function UpdatePlayerList()
    local text = ""
    for _, pl in ipairs(Players:GetPlayers()) do
        text = text .. pl.Name .. "\n"
    end
    PlayersLabel:Set("Players: "..#Players:GetPlayers())
end

RunService.RenderStepped:Connect(UpdatePlayerList)

-- =========================
-- Full Webhook Feedback with emote
-- =========================
local function SendAdminWebhookEnhanced(playerName, reason, status)
    local desc = ("🛡️ Admin Detected: **%s**\nReason: %s\nStatus: %s\nTime: %s"):format(
        playerName, reason, status, os.date("%Y-%m-%d %H:%M:%S")
    )
    SendWebhook(("⚠️ Admin Detected — %s"):format(playerName), desc, {
        color = 15158332,
        fields = {
            {name="Player", value=playerName, inline=true},
            {name="Reason", value=reason, inline=false},
            {name="Status", value=status, inline=true}
        }
    })
end

-- =========================
-- Final Safety Loops
-- =========================
task.spawn(function()
    while task.wait(Config.ScanInterval) do
        for _, pl in ipairs(Players:GetPlayers()) do
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end
        UpdateSummitStatus()
    end
end)

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