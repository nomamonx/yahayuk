--[[
FULL Admin & Summit Detector + Teleport + Config Save
By: ChatGPT (modifikasi lengkap)
Versi: 1.0.0
Catatan: Pastikan executor-mu support HttpGet/HttpPost atau syn.request
]]

-- =========================
-- Part 0: Rayfield & Safety
-- =========================

local success, RayfieldOrErr = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not RayfieldOrErr then
    warn("Rayfield gagal dimuat. Pastikan executor mendukung HttpGet.")
    if typeof(RayfieldOrErr) == "string" then
        warn("Error detail:", RayfieldOrErr)
    end
    return
end

local Rayfield = RayfieldOrErr

-- =========================
-- Part 1: Services & Default Config
-- =========================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Default config (editable via UI)
local Config = {
    AutoHop = true,
    AutoLeave = false,
    SendWebhook = true,
    ScanInterval = 2.5,
    SummitDetectMethod = "both", -- "leaderstat" / "position" / "both"
    SummitPositionY = 1000,
    SummitPositionHold = 1.2,
    WebhookURL = "",
    WebhookUseEmbed = true,
    DetectionCooldown = 6,
    IgnoreFriends = true,
    VerboseLogging = true,
    NotifyInGame = true
}

-- =========================
-- Part 1b: Blacklist & Admin Keywords
-- =========================

local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

local RankKeywords = {
    "ADMIN","OWNER","DEVELOPER","STAFF",
    "YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"
}

-- =========================
-- Part 1c: Utilities & Logging
-- =========================

local LastDetection = {}
local SummitStatus = {}

local function Notify(title, content, duration)
    if Config.NotifyInGame and Rayfield.Notify then
        Rayfield.Notify({
            Title = title,
            Content = content,
            Duration = duration or 4
        })
    end
    if Config.VerboseLogging then
        print("[Detector] "..title..": "..content)
    end
end

local function IsOnCooldown(playerName)
    local last = LastDetection[playerName]
    if not last then return false end
    return (os.clock() - last) < Config.DetectionCooldown
end

local function SetCooldown(playerName)
    LastDetection[playerName] = os.clock()
end

local function SendWebhookMessage(title, content)
    if Config.SendWebhook and Config.WebhookURL ~= "" then
        pcall(function()
            local data = {
                content = "**"..title.."**\n"..content
            }
            if Config.WebhookUseEmbed then
                data = {embeds={{title=title, description=content, color=16711680}}}
            end
            syn.request({
                Url = Config.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end

-- =========================
-- Part 2: Detection Functions
-- =========================

local function CheckAdmin(player)
    if IsOnCooldown(player.Name) then return end
    local nameUpper = string.upper(player.Name)
    local detected = nil

    for _, keyword in ipairs(RankKeywords) do
        if string.find(nameUpper, keyword) then
            detected = keyword
            break
        end
    end

    for _, blName in ipairs(BlacklistNames) do
        if nameUpper == string.upper(blName) then
            detected = "❌ Blacklist"
            break
        end
    end

    if detected then
        Notify("⚠️ Ditemukan "..detected, "Nama: "..player.Name, 5)
        SendWebhookMessage(detected.." Terdeteksi!", player.Name)
        SetCooldown(player.Name)

        if Config.AutoHop then
            pcall(function()
                TeleportService:Teleport(PlaceId, LocalPlayer)
            end)
        elseif Config.AutoLeave then
            LocalPlayer:Kick("Admin detected, leaving game...")
        end
    end
end

local function CheckSummit(player)
    if Config.SummitDetectMethod == "position" or Config.SummitDetectMethod == "both" then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y >= Config.SummitPositionY then
            if not SummitStatus[player.Name] then
                SummitStatus[player.Name] = os.clock()
            else
                if (os.clock() - SummitStatus[player.Name]) >= Config.SummitPositionHold then
                    Notify("🏔️ Summit Tercapai!", player.Name.." sudah mencapai puncak!", 4)
                    SendWebhookMessage("Summit!", player.Name.." mencapai puncak.")
                    SummitStatus[player.Name] = os.clock() + 999 -- prevent spam
                end
            end
        else
            SummitStatus[player.Name] = nil
        end
    end
end

-- =========================
-- Part 2b: Scan Loop
-- =========================

local lastScan = 0
RunService.Heartbeat:Connect(function(deltaTime)
    lastScan += deltaTime
    if lastScan < Config.ScanInterval then return end
    lastScan = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not (Config.IgnoreFriends and plr:IsFriendsWith(LocalPlayer.UserId)) then
                CheckAdmin(plr)
                if Config.SummitDetectMethod ~= "leaderstat" then
                    CheckSummit(plr)
                end
            end
        end
    end
end)
-- =========================
-- Part 3a: GUI - Teleport Tab
-- =========================

local Window = Rayfield:CreateWindow({
    Name = "🛡️ VIP Detector & Summit",
    LoadingTitle = "Memuat Fitur...",
    LoadingSubtitle = "Silakan tunggu 🚀",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DetektorSummit",
        FileName = "Config"
    }
})

local TeleTab = Window:CreateTab("Teleport", 4483362458)
local TabSummit = Window:CreateTab("Summit", 4483362458)
local TabSettings = Window:CreateTab("Settings", 4483362458)
local TabAdvanced = Window:CreateTab("Advanced", 4483362458)

-- teleport points
-- =========================
-- Variabel delay default
-- =========================
local AutoTeleportDelay = 2
local isAutoTeleporting = false
local autoTeleportTask = nil

-- =========================
-- Teleport Points
-- =========================
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
-- Helper: Respawn Character
-- =========================
local function respawnCharacter()
    local player = game.Players.LocalPlayer
    if player.Character then
        player.Character:BreakJoints()
    end
    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0
end

-- =========================
-- Teleport Manual
-- =========================
TeleTab:CreateSection("Teleport Manual")
for name, cf in pairs(teleportPoints) do
    TeleTab:CreateButton({
        Name = "📍 Teleport "..name,
        Callback = function()
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = cf
        end
    })
end

-- =========================
-- Teleport Otomatis
-- =========================
TeleTab:CreateSection("Teleport Otomatis")
TeleTab:CreateToggle({
    Name = "⚡ Auto Teleport",
    CurrentValue = Rayfield.Flags.AutoTP and Rayfield.Flags.AutoTP.CurrentValue or false,
    Flag = "AutoTP",
    Callback = function(Value)
        isAutoTeleporting = Value
        Rayfield:SaveConfiguration() -- auto save saat toggle berubah
        if Value then
            autoTeleportTask = task.spawn(function()
                local player = game.Players.LocalPlayer
                local autoPoints = {teleportPoints.CP1, teleportPoints.CP2, teleportPoints.CP3, teleportPoints.CP4, teleportPoints.CP5, teleportPoints.Puncak}
                while isAutoTeleporting do
                    for i, cf in ipairs(autoPoints) do
                        if not isAutoTeleporting then break end
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = cf
                        end
                        task.wait(AutoTeleportDelay)
                    end
                    respawnCharacter()
                end
            end)
        else
            if autoTeleportTask then
                task.cancel(autoTeleportTask)
                autoTeleportTask = nil
            end
        end
    end
})

-- =========================
-- Delay Slider
-- =========================
TeleTab:CreateSection("Atur Delay Auto Teleport")
TeleTab:CreateSlider({
    Name = "⏳ Delay (detik)",
    Range = {0,20},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = Rayfield.Flags.ATDelay and Rayfield.Flags.ATDelay.CurrentValue or AutoTeleportDelay,
    Flag = "ATDelay",
    Callback = function(Value)
        AutoTeleportDelay = Value
        Rayfield:SaveConfiguration() -- auto save saat slider berubah
    end
})
-- =========================
-- Part 3b: Summit & Settings
-- =========================

-- ===== Summit Tracker =====
local SummitData = {
    TotalSummits = 0,
    LastDetected = 0,
    DetectedPlayers = {},
}

local function notifySummit(playerName)
    SummitData.TotalSummits += 1
    SummitData.LastDetected = tick()
    table.insert(SummitData.DetectedPlayers, playerName)
    if Config.NotifyInGame then
        Rayfield:Notify({
            Title = "🏔️ Summit Detected",
            Content = "Player "..playerName.." reached the summit!\nTotal Summits: "..SummitData.TotalSummits,
            Duration = 4,
        })
    end
    if Config.SendWebhook and Config.WebhookURL ~= "" then
        local payload = {}
        if Config.WebhookUseEmbed then
            payload = HttpService:JSONEncode({
                embeds = {{
                    title = "🏔️ Summit Alert",
                    description = playerName.." just reached the summit!\nTotal Summits: "..SummitData.TotalSummits,
                    color = 3447003
                }}
            })
        else
            payload = HttpService:JSONEncode({content = playerName.." reached the summit! Total: "..SummitData.TotalSummits})
        end
        pcall(function()
            syn and syn.request and syn.request({Url=Config.WebhookURL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=payload})
        end)
    end
end

local function checkSummit(player)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local y = hrp.Position.Y
    if y >= Config.SummitPositionY then
        if (tick() - (player._lastSummit or 0)) >= Config.SummitPositionHold then
            player._lastSummit = tick()
            notifySummit(player.Name)
        end
    end
end

-- loop deteksi
task.spawn(function()
    while true do
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if Config.SummitDetectMethod == "position" or Config.SummitDetectMethod == "both" then
                    checkSummit(plr)
                end
                if Config.SummitDetectMethod == "leaderstat" or Config.SummitDetectMethod == "both" then
                    local ls = plr:FindFirstChild("leaderstats")
                    if ls and ls:FindFirstChild("Summit") and ls.Summit.Value >= 1 then
                        if (tick() - (plr._lastSummit or 0)) >= Config.SummitPositionHold then
                            plr._lastSummit = tick()
                            notifySummit(plr.Name)
                        end
                    end
                end
            end
        end
        task.wait(Config.ScanInterval)
    end
end)

-- ===== Settings Tab =====
local TabSettings = Window:CreateTab("Settings")
TabSettings:CreateSection("Auto & Notifications")
TabSettings:CreateToggle({
    Name = "Auto Hop",
    CurrentValue = Config.AutoHop,
    Flag = "AutoHop",
    Callback = function(Value) Config.AutoHop = Value end
})
TabSettings:CreateToggle({
    Name = "Auto Leave",
    CurrentValue = Config.AutoLeave,
    Flag = "AutoLeave",
    Callback = function(Value) Config.AutoLeave = Value end
})
TabSettings:CreateToggle({
    Name = "Send Webhook",
    CurrentValue = Config.SendWebhook,
    Flag = "SendWebhook",
    Callback = function(Value) Config.SendWebhook = Value end
})
TabSettings:CreateTextBox({
    Name = "Webhook URL",
    Text = Config.WebhookURL,
    PlaceholderText = "Masukkan webhook",
    Callback = function(Value) Config.WebhookURL = Value end
})
TabSettings:CreateSlider({
    Name = "Scan Interval (detik)",
    Range = {0.5,10},
    Increment = 0.1,
    CurrentValue = Config.ScanInterval,
    Suffix = "s",
    Callback = function(Value) Config.ScanInterval = Value end
})

-- ===== Advanced Tab =====
local TabAdvanced = Window:CreateTab("Advanced")
TabAdvanced:CreateSection("Debug & Reset")
TabAdvanced:CreateButton({
    Name = "Reset Summit Counter",
    Callback = function()
        SummitData.TotalSummits = 0
        SummitData.DetectedPlayers = {}
        Rayfield:Notify({Title="Reset", Content="Summit counter direset!", Duration=3})
    end
})
TabAdvanced:CreateButton({
    Name = "Print Detected Players",
    Callback = function()
        print("Players detected at summit:")
        for i,v in ipairs(SummitData.DetectedPlayers) do
            print(i..". "..v)
        end
        Rayfield:Notify({Title="Debug", Content="Lihat console untuk daftar players", Duration=3})
    end
})
-- =========================
-- Part 4: Admin Detection & AutoHop/Leave
-- =========================

local AdminDetectedData = {
    LastDetected = 0,
    CurrentAdmins = {},
}

-- fungsi notifikasi admin
local function notifyAdmin(playerName, rank)
    AdminDetectedData.LastDetected = tick()
    AdminDetectedData.CurrentAdmins[playerName] = rank
    if Config.NotifyInGame then
        Rayfield:Notify({
            Title = "⚠️ Admin Detected",
            Content = playerName.." ("..rank..") appeared!",
            Duration = 5
        })
    end
    if Config.SendWebhook and Config.WebhookURL ~= "" then
        local payload = {}
        if Config.WebhookUseEmbed then
            payload = HttpService:JSONEncode({
                embeds = {{
                    title = "⚠️ Admin Alert",
                    description = playerName.." ("..rank..") appeared!",
                    color = 16711680
                }}
            })
        else
            payload = HttpService:JSONEncode({content = playerName.." ("..rank..") appeared!"})
        end
        pcall(function()
            syn and syn.request and syn.request({Url=Config.WebhookURL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=payload})
        end)
    end
end

-- cek apakah nama player termasuk blacklist atau rank keywords
local function getPlayerRank(player)
    local name = player.Name
    for _, blk in ipairs(BlacklistNames) do
        if name:lower() == blk:lower() then return "Blacklist" end
    end
    local rankname = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Rank")
    if rankname then
        for _, keyword in ipairs(RankKeywords) do
            if rankname.Value:upper():find(keyword:upper()) then
                return keyword
            end
        end
    end
    for _, keyword in ipairs(RankKeywords) do
        if name:upper():find(keyword:upper()) then
            return keyword
        end
    end
    return nil
end

-- loop deteksi admin
task.spawn(function()
    while true do
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if Config.IgnoreFriends and LocalPlayer:IsFriendsWith(plr.UserId) then
                    continue
                end
                local rank = getPlayerRank(plr)
                if rank and (tick() - (plr._lastDetected or 0)) >= Config.DetectionCooldown then
                    plr._lastDetected = tick()
                    notifyAdmin(plr.Name, rank)
                    -- AutoHop / AutoLeave
                    if Config.AutoHop then
                        pcall(function()
                            TeleportService:Teleport(PlaceId, LocalPlayer)
                        end)
                    elseif Config.AutoLeave then
                        pcall(function()
                            LocalPlayer:Kick("Admin detected, auto leave enabled")
                        end)
                    end
                end
            end
        end
        task.wait(Config.ScanInterval)
    end
end)

-- tambah button debug untuk lihat admin aktif
TabAdvanced:CreateButton({
    Name = "Print Current Admins",
    Callback = function()
        print("Current Admins Detected:")
        for name, rank in pairs(AdminDetectedData.CurrentAdmins) do
            print(name.." - "..rank)
        end
        Rayfield:Notify({Title="Debug", Content="Lihat console untuk daftar admin", Duration=3})
    end
})

Rayfield:LoadConfiguration()

-- =========================
-- Auto-save saat executor close
-- =========================
game:BindToClose(function()
    Rayfield:SaveConfiguration()
end)