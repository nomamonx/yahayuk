local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Private: MT Yahayyuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
})
-- Tab Informasi
-- ========================
local InfoTab = Window:CreateTab("Informasi", 6034509994)
InfoTab:CreateSection("Informasi")

InfoTab:CreateParagraph({
    Title = "Jammoko Baca",
    Content = "Ini adalah script teleport Yang kubuat asal asal akwokaowk.",
})
Rayfield:Notify({
   Title = "Script Dimuat",
   Content = "TELASO berhasil!!!",
   Duration = 6.5,
   Image = 4483362458,
})

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

-- ========================
-- Tab Pengaturan
-- ========================
local SettingsTab = Window:CreateTab("Pengaturan", 6034509993)

SettingsTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

SettingsTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 300},
   Increment = 10,
   Suffix = "Jump",
   CurrentValue = 50,
   Flag = "JumpSlider",
   Callback = function(Value)
       game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
   end,
})

SettingsTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
       local UserInputService = game:GetService("UserInputService")
       if Value then
           InfJumpConnection = UserInputService.JumpRequest:Connect(function()
               game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
           end)
       else
           if InfJumpConnection then
               InfJumpConnection:Disconnect()
               InfJumpConnection = nil
           end
       end
   end,
})

-- =======================================
-- 🔒 Admin / Owner / Dev Detector Script
-- Versi Lengkap (Rayfield UI)
-- =======================================


-- Buat Tab Deteksi
local DetectionTab = Window:CreateTab("🕵️ Deteksi Admin")

-- Service
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId

-- ========================
-- Config System
-- ========================
local ConfigFile = "AdminDetectorConfig.json"

local function SaveConfig(config)
    writefile(ConfigFile, HttpService:JSONEncode(config))
end

local function LoadConfig()
    if isfile(ConfigFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFile))
        end)
        if success and data then
            return data
        end
    end
    return {}
end

local Config = LoadConfig()

local function SetConfig(key, value)
    Config[key] = value
    SaveConfig(Config)
end

-- ========================
-- Label Status
-- ========================
local AdminLabel = DetectionTab:CreateLabel("Admin Terdeteksi: -")
local SummitLabel = DetectionTab:CreateLabel("Top Puncak: -")

DetectionTab:CreateSection("⚠️ Fitur Deteksi Admin")

-- ========================
-- Daftar Nama Hitam
-- ========================
local BlacklistNames = {
    "YAHAVUKazigen", "Dim", "eugyne", "VBZ",
    "HeruAjaDeh", "FENRIRDONGKAK", "RAVINSKIE",
    "NotHuman", "MDFixDads", "MDFuturFewWan",
    "YAHAVUisDanzzy"
}

-- ========================
-- Fungsi Cek Admin / Owner / Dev
-- ========================
local function IsDangerous(player)
    -- Cek daftar nama
    for _, bad in ipairs(BlacklistNames) do
        if string.lower(player.Name) == string.lower(bad)
        or string.lower(player.DisplayName) == string.lower(bad) then
            return true
        end
    end
    -- Cek tulisan di atas kepala
    if player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") then
                    for _, label in ipairs(gui:GetChildren()) do
                        if label:IsA("TextLabel") then
                            local text = string.upper(label.Text or "")
                            if string.find(text, "ADMIN") 
                            or string.find(text, "OWNER") 
                            or string.find(text, "DEVELOPER") then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ========================
-- Auto Leave
-- ========================
local AutoLeaveLoop
DetectionTab:CreateToggle({
    Name = "🚪 Auto Leave",
    CurrentValue = Config.AutoLeave or false,
    Flag = "AutoLeaveDangerToggle",
    Callback = function(Value)
        SetConfig("AutoLeave", Value)
        if Value then
            AutoLeaveLoop = task.spawn(function()
                while true do
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and IsDangerous(player) then
                            Rayfield:Notify({
                                Title = "Keluar Server!",
                                Content = "Bahaya terdeteksi: " .. player.Name,
                                Duration = 5,
                            })
                            task.wait(1)
                            LocalPlayer:Kick("Keluar otomatis, terdeteksi " .. player.Name)
                            return
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            if AutoLeaveLoop then
                task.cancel(AutoLeaveLoop)
                AutoLeaveLoop = nil
            end
        end
    end,
})

-- ========================
-- Auto Hop
-- ========================
local AutoHopLoop
local function FindServer()
    local servers = {}
    local cursor = nil
    local success, result
    repeat
        success, result = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet(
                    "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"..(cursor and "&cursor="..cursor or "")
                )
            )
        end)
        if success and result and result.data then
            for _, srv in ipairs(result.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    table.insert(servers, srv)
                end
            end
            cursor = result.nextPageCursor
        else
            break
        end
    until not cursor
    if #servers > 0 then
        return servers[math.random(1, #servers)].id
    end
    return nil
end

DetectionTab:CreateToggle({
    Name = "🌐 Auto Hop Server",
    CurrentValue = Config.AutoHop or false,
    Flag = "AutoHopAdminToggle",
    Callback = function(Value)
        SetConfig("AutoHop", Value)
        if Value then
            AutoHopLoop = task.spawn(function()
                while true do
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and IsDangerous(player) then
                            Rayfield:Notify({
                                Title = "🌐 Server Hop!",
                                Content = "Bahaya terdeteksi: " .. player.Name .. " → Hop server...",
                                Duration = 5,
                            })
                            task.wait(2)
                            local serverId = FindServer()
                            if serverId then
                                TeleportService:TeleportToPlaceInstance(PlaceId, serverId, LocalPlayer)
                            else
                                LocalPlayer:Kick("Admin terdeteksi tapi tidak ada server kosong ditemukan.")
                            end
                            return
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            if AutoHopLoop then
                task.cancel(AutoHopLoop)
                AutoHopLoop = nil
            end
        end
    end,
})

-- ========================
-- Notif Admin Masuk
-- ========================
local AutoNotifyLoop
DetectionTab:CreateToggle({
    Name = "📤 Notif Admin Masuk",
    CurrentValue = Config.AutoNotify or false,
    Flag = "NotifyAdminJoinToggle",
    Callback = function(Value)
        SetConfig("AutoNotify", Value)
        if Value then
            AutoNotifyLoop = Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function()
                    task.wait(2)
                    if IsDangerous(player) then
                        Rayfield:Notify({
                            Title = "⚠️ Admin Masuk!",
                            Content = player.Name .. " adalah Admin/Owner/Dev!",
                            Duration = 8,
                        })
                    end
                end)
            end)
        else
            if AutoNotifyLoop then
                AutoNotifyLoop:Disconnect()
                AutoNotifyLoop = nil
            end
        end
    end,
})

-- ========================
-- Cek Admin List
-- ========================
local CheckLoop
DetectionTab:CreateToggle({
    Name = "👀 Cek Admin di Server",
    CurrentValue = Config.CheckAdmin or false,
    Flag = "CheckAdminToggle",
    Callback = function(Value)
        SetConfig("CheckAdmin", Value)
        if Value then
            CheckLoop = task.spawn(function()
                while true do
                    local detected = {}
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and IsDangerous(player) then
                            table.insert(detected, player.DisplayName .. " ("..player.Name..")")
                        end
                    end
                    if #detected > 0 then
                        AdminLabel:Set("Admin Terdeteksi: " .. table.concat(detected, ", "))
                    else
                        AdminLabel:Set("Admin Terdeteksi: -")
                    end
                    task.wait(5)
                end
            end)
        else
            if CheckLoop then
                task.cancel(CheckLoop)
                CheckLoop = nil
            end
            AdminLabel:Set("Admin Terdeteksi: -")
        end
    end,
})

-- ========================
-- Tombol Reset Config
-- ========================
DetectionTab:CreateButton({
    Name = "♻️ Reset Pengaturan",
    Callback = function()
        if isfile(ConfigFile) then
            delfile(ConfigFile)
        end
        Config = {}
        AdminLabel:Set("Admin Terdeteksi: -")
        Rayfield:Notify({
            Title = "Config Direset",
            Content = "Pengaturan kembali ke default. Silakan atur ulang toggle.",
            Duration = 6,
        })
    end,
})

-- (sisa kode pengaturan dan deteksi admin tetap sama, tidak aku ulang di sini)
