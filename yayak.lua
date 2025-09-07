-- // Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- // Buat Window utama
local Window = Rayfield:CreateWindow({
   Name = "VIP: MT Yahayuk",
   LoadingTitle = "Sedang Loading",
   LoadingSubtitle = "By Acong Gacor",
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


-- =======================================
-- 🔒 Admin / Owner / Dev Detector Script
-- Dengan Save Config + Reset
-- =======================================

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

-- Config default
local Config = LoadConfig()

local function SetConfig(key, value)
    Config[key] = value
    SaveConfig(Config)
end

-- ========================
-- UI Label
-- ========================
AdminLabel = DetectionTab:CreateLabel("Admin Terdeteksi: -")
SummitLabel = DetectionTab:CreateLabel("Top Puncak: -")

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



-- ========================
-- Tab Pengaturan
-- ========================
local SettingsTab = Window:CreateTab("Settings", 6034509993)


SettingsTab:CreateSection("Fitur Tambahan")
-- ========================
-- Wallhack Nama + Jarak (Auto Update)
-- ========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local ESPEnabled = false
local ESPObjects = {}

local function CreateNameESP(player)
    if ESPObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameESP"
    billboard.Size = UDim2.new(0, 150, 0, 25)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Text = player.DisplayName
    label.Parent = billboard

    ESPObjects[player] = {billboard = billboard, label = label}
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].billboard then
            ESPObjects[player].billboard:Destroy()
        end
        ESPObjects[player] = nil
    end
end

local function AttachBillboard(player, char)
    local obj = ESPObjects[player]
    if obj and char and char:FindFirstChild("Head") then
        obj.billboard.Adornee = char.Head
        obj.billboard.Parent = char.Head
    end
end

-- Loop utama update jarak & pasang ESP
RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            -- pastikan selalu ada ESP
            if not ESPObjects[plr] then
                CreateNameESP(plr)
            end

            local obj = ESPObjects[plr]
            local char = plr.Character
            if char and char:FindFirstChild("Head") then
                -- re-attach kalau perlu
                if obj.billboard.Parent ~= char.Head then
                    AttachBillboard(plr, char)
                end

                -- update jarak realtime
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if localHRP and hrp then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    obj.label.Text = plr.DisplayName .. " [" .. math.floor(dist) .. "m]"
                else
                    obj.label.Text = plr.DisplayName .. " [N/A]"
                end
            end
        end
    end
end)

-- Toggle ESP
local function ToggleESP(state)
    ESPEnabled = state
    if not ESPEnabled then
        for _, obj in pairs(ESPObjects) do
            if obj.billboard then obj.billboard:Destroy() end
        end
        ESPObjects = {}
    end
end

-- Toggle di SettingsTab
SettingsTab:CreateToggle({
    Name = "Wallhack",
    CurrentValue = false,
    Flag = "ESPNameDistance",
    Callback = function(Value)
        ToggleESP(Value)
    end,
})

 
-- =========================
-- TAB PENGATURAN (Lengkap)
-- =========================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- DEFAULT & STATE
-- =========================
local defaultWalkSpeed = 16
local walkSpeedEnabled = false -- default OFF
local infinityJumpEnabled = false
local currentWalkSpeedValue = 16 -- sinkron dengan slider

-- cache connections supaya bisa dikelola
local _ijJumpReqConn, _ijInputBeganConn

-- helper: ambil Humanoid aman
local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid")
end

-- helper: apply WalkSpeed sesuai toggle & slider
local function applyWalkSpeed()
    local hum = getHumanoid()
    if not hum then return end
    if walkSpeedEnabled then
        hum.WalkSpeed = currentWalkSpeedValue
    else
        hum.WalkSpeed = defaultWalkSpeed
    end
end

-- =========================
-- UI SECTION
-- =========================
SettingsTab:CreateSection("Pengaturan")

-- WalkSpeed Slider
local WalkSpeedSlider = SettingsTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = defaultWalkSpeed,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        currentWalkSpeedValue = Value
        if walkSpeedEnabled then
            applyWalkSpeed()
        end
    end,
})

-- WalkSpeed Toggle
local WalkSpeedToggle = SettingsTab:CreateToggle({
    Name = "WalkSpeed On/Off",
    CurrentValue = walkSpeedEnabled, -- default false
    Flag = "WalkSpeedToggle",
    Callback = function(Value)
        walkSpeedEnabled = Value
        applyWalkSpeed()
    end,
})

-- Re-apply saat respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.defer(applyWalkSpeed)
end)

-- Sedikit “penjaga” kalau game mencoba ganti WalkSpeed
task.spawn(function()
    while true do
        task.wait(0.25)
        if walkSpeedEnabled then
            local hum = getHumanoid()
            if hum and hum.WalkSpeed ~= currentWalkSpeedValue then
                hum.WalkSpeed = currentWalkSpeedValue
            end
        end
    end
end)

-- =========================
-- INFINITY JUMP
-- =========================
local function forceJump()
    local hum = getHumanoid()
    if not hum then return end
    local root = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")

    -- 1) standard jump flag
    hum.Jump = true

    -- 2) paksa state ke Jumping
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    -- 3) fallback: dorong ke atas
    if root then
        local v = root.AssemblyLinearVelocity
        local kickY = 50
        root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, kickY), v.Z)
    end
end

-- aktifkan listener Infinity Jump
local function bindInfinityJumpConnections()
    -- bersihkan koneksi lama
    if _ijJumpReqConn then _ijJumpReqConn:Disconnect() end
    if _ijInputBeganConn then _ijInputBeganConn:Disconnect() end

    -- Event universal jump
    _ijJumpReqConn = UserInputService.JumpRequest:Connect(function()
        if infinityJumpEnabled then
            forceJump()
        end
    end)

    -- Tambahan untuk Space / Gamepad A
    _ijInputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not infinityJumpEnabled then return end

        local kc = input.KeyCode
        if kc == Enum.KeyCode.Space or kc == Enum.KeyCode.ButtonA then
            forceJump()
        end
    end)
end

-- Toggle Infinity Jump
SettingsTab:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Flag = "InfinityJumpToggle",
    Callback = function(Value)
        infinityJumpEnabled = Value
        if not _ijJumpReqConn or not _ijInputBeganConn then
            bindInfinityJumpConnections()
        end
    end,
})

-- pastikan koneksi ter-bind saat script load
bindInfinityJumpConnections()


SettingsTab:CreateSection("Fitur Fly (Beta)")
-- ============================================
-- Fly Universal Stable (PC & Mobile)
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local flying = false
local flySpeed = 50
local flyBV, flyGyro
local flyConn

-- UI (Mobile Buttons)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyMobileUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local UpButton = Instance.new("TextButton")
UpButton.Size = UDim2.new(0, 100, 0, 50)
UpButton.Position = UDim2.new(0.82, 0, 0.65, 0)
UpButton.Text = "⬆ Naik"
UpButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
UpButton.TextColor3 = Color3.fromRGB(255,255,255)
UpButton.TextScaled = true
UpButton.Parent = ScreenGui
UpButton.Visible = false

local DownButton = Instance.new("TextButton")
DownButton.Size = UDim2.new(0, 100, 0, 50)
DownButton.Position = UDim2.new(0.82, 0, 0.75, 0)
DownButton.Text = "⬇ Turun"
DownButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
DownButton.TextColor3 = Color3.fromRGB(255,255,255)
DownButton.TextScaled = true
DownButton.Parent = ScreenGui
DownButton.Visible = false

-- Info PC
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0, 260, 0, 70)
InfoLabel.Position = UDim2.new(0.7, 0, 0.05, 0)
InfoLabel.BackgroundTransparency = 0.3
InfoLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
InfoLabel.TextColor3 = Color3.fromRGB(255,255,255)
InfoLabel.Font = Enum.Font.SourceSansBold
InfoLabel.TextSize = 18
InfoLabel.Visible = false
InfoLabel.Text = "Fly Controls:\nWASD = Gerak\nSpace = Naik\nShift = Turun"
InfoLabel.Parent = ScreenGui

local upPressed, downPressed = false, false
UpButton.MouseButton1Down:Connect(function() upPressed = true end)
UpButton.MouseButton1Up:Connect(function() upPressed = false end)
DownButton.MouseButton1Down:Connect(function() downPressed = true end)
DownButton.MouseButton1Up:Connect(function() downPressed = false end)

-- Start Fly
local function startFly()
    if flying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart")

    flying = true

    -- BodyVelocity untuk dorong karakter
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.new(0,0,0)
    flyBV.Parent = hrp

    -- BodyGyro biar ngikut arah kamera
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp

    if UserInputService.TouchEnabled then
        UpButton.Visible = true
        DownButton.Visible = true
    elseif UserInputService.KeyboardEnabled then
        InfoLabel.Visible = true
    end

    flyConn = RunService.RenderStepped:Connect(function()
        if not flying then return end
        local camCF = workspace.CurrentCamera.CFrame
        local moveDir = Vector3.new()

        -- PC
        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir += camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir -= camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir -= camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir += camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir += Vector3.new(0,1,0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir -= Vector3.new(0,1,0)
            end
        elseif UserInputService.TouchEnabled then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                moveDir += hum.MoveDirection
            end
            if upPressed then
                moveDir += Vector3.new(0,1,0)
            end
            if downPressed then
                moveDir -= Vector3.new(0,1,0)
            end
        end

        flyGyro.CFrame = camCF
        if moveDir.Magnitude > 0 then
            flyBV.Velocity = moveDir.Unit * flySpeed
        else
            flyBV.Velocity = Vector3.new(0,0,0)
        end
    end)
end

-- Stop Fly
local function stopFly()
    flying = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    UpButton.Visible = false
    DownButton.Visible = false
    InfoLabel.Visible = false
end

-- Toggle
SettingsTab:CreateToggle({
    Name = "Fly (Stable)",
    CurrentValue = false,
    Flag = "FlyToggleStable",
    Callback = function(Value)
        if Value then
            startFly()
        else
            stopFly()
        end
    end,
})

-- Speed Slider
SettingsTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = flySpeed,
    Flag = "FlySpeedSliderStable",
    Callback = function(Value)
        flySpeed = Value
    end,
})


-- ========================
-- Sensor Nama Saya (Anti Kedip)
-- ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local randomActive = false
local nameLoop = nil

local fakeNames = {
    "OrangMisterius","PlayerX","NoobBergaya","SiTembus","HantuGunung"
}

local function getRandomName()
    return fakeNames[math.random(1, #fakeNames)]
end

local function applyNoName(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    local head = char:WaitForChild("Head", 5)
    if not humanoid or not head then return end

    -- sembunyikan label default
    humanoid.NameDisplayDistance = 0
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.DisplayName = ""

    -- hapus semua Billboard bawaan
    for _, gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") and gui.Name ~= "FakeName" then
            gui:Destroy()
        end
    end

    -- bikin fake name sendiri kalau belum ada
    if not head:FindFirstChild("FakeName") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FakeName"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.new(1,1,1)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.SourceSansBold
        text.TextScaled = true
        text.Text = getRandomName()
        text.Parent = billboard
    end

    -- loop anti-kedip (hapus name tag asli setiap frame)
    if nameLoop then nameLoop:Disconnect() end
    nameLoop = RunService.RenderStepped:Connect(function()
        if not randomActive then return end
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") and gui.Name ~= "FakeName" then
                    gui:Destroy()
                end
            end
        end
    end)
end

local function resetName(char)
    if nameLoop then
        nameLoop:Disconnect()
        nameLoop = nil
    end
    local head = char:FindFirstChild("Head")
    if head and head:FindFirstChild("FakeName") then
        head.FakeName:Destroy()
    end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        humanoid.NameDisplayDistance = 100
        humanoid.DisplayName = lp.Name
    end
end

SettingsTab:CreateToggle({
   Name = "Sensor Nama",
   CurrentValue = false,
   Flag = "MyFakeNameToggle",
   Callback = function(Value)
        randomActive = Value
        if randomActive then
            if lp.Character then applyNoName(lp.Character) end
            lp.CharacterAdded:Connect(function(char)
                task.wait(1)
                if randomActive then
                    applyNoName(char)
                end
            end)
        else
            if lp.Character then resetName(lp.Character) end
        end
   end
})



-- ========================
-- FunTab: Follow + Lengan Joget + Kepala Terbalik
-- ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local FunTab = Window:CreateTab("Fun", 4483362458)
FunTab:CreateSection("Trolling")
local TargetPlayer = nil
local FollowConnection
local JogetConnection

local JogetAmplitude = 30 -- derajat
local JogetSpeed = 5 -- kecepatan

-- Dropdown pilih player
local function RefreshPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.DisplayName)
        end
    end
    return names
end

local PlayerDropdown = FunTab:CreateDropdown({
    Name = "💃🏻 Pilih Player",
    Options = RefreshPlayerList(),
    CurrentOption = {},
    Flag = "FunPlayerDropdown",
    Callback = function(option)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.DisplayName == option[1] then
                TargetPlayer = plr
                break
            end
        end
    end
})

FunTab:CreateButton({
    Name = "💃🏻 Refresh Player List",
    Callback = function()
        PlayerDropdown:Refresh(RefreshPlayerList(), true)
    end
})

-- Toggle Follow Player
local FollowEnabled = false
FunTab:CreateToggle({
    Name = "🏃 Ikuti Player",
    CurrentValue = false,
    Flag = "FollowToggle",
    Callback = function(value)
        FollowEnabled = value
        if FollowEnabled then
            FollowConnection = RunService.Heartbeat:Connect(function()
                if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(TargetPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,0.5,0))
                    end
                end
            end)
        else
            if FollowConnection then
                FollowConnection:Disconnect()
                FollowConnection = nil
            end
        end
    end
})
FunTab:CreateSection("Emote")
local JogetEnabled = false
FunTab:CreateToggle({
    Name = "🗿 Eror (Bikin Terbang)",
    CurrentValue = false,
    Flag = "JogetToggle",
    Callback = function(value)
        JogetEnabled = value
        if JogetEnabled then
            local t = 0
            JogetConnection = RunService.Heartbeat:Connect(function(dt)
                t += dt * JogetSpeed
                local char = LocalPlayer.Character
                if char then
                    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
                    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
                    if leftArm then
                        leftArm.CFrame = leftArm.CFrame * CFrame.Angles(1, 0, math.rad(math.sin(t) * JogetAmplitude))
                    end
                    if rightArm then
                        rightArm.CFrame = rightArm.CFrame * CFrame.Angles(1, 0, math.rad(-math.sin(t) * JogetAmplitude))
                    end
                end
            end)
        else
            if JogetConnection then
                JogetConnection:Disconnect()
                JogetConnection = nil
            end
        end
    end
})

-- Toggle Kepala di bawah / terbalik permanen
local InvertEnabled = false
local InvertConnection

FunTab:CreateToggle({
    Name = "🗿 Kepala Kebawah",
    CurrentValue = false,
    Flag = "InvertToggle",
    Callback = function(value)
        InvertEnabled = value

        if InvertEnabled then
            if InvertConnection then InvertConnection:Disconnect() end
            InvertConnection = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    -- Memastikan selalu terbalik
                    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(math.rad(180),10,0)
                end
            end)
        else
            if InvertConnection then
                InvertConnection:Disconnect()
                InvertConnection = nil
            end
            -- Kembalikan normal
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0,0,0)
            end
        end
    end
})


local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local sitActive = false
local constraint = {}

-- cari player terdekat
local function getNearestPlayer()
    local nearest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lp.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                nearest = plr
            end
        end
    end
    return nearest
end

-- duduk di atas player
local function sitOnPlayer(target)
    if not target or not target.Character then return end
    local myHRP = lp.Character:WaitForChild("HumanoidRootPart")
    local targetHRP = target.Character:WaitForChild("HumanoidRootPart")

    -- bersihkan constraint lama
    for _, v in pairs(myHRP:GetChildren()) do
        if v:IsA("AlignPosition") or v:IsA("AlignOrientation") or v:IsA("Attachment") then
            v:Destroy()
        end
    end

    -- bikin attachment
    local a0 = Instance.new("Attachment", myHRP)
    local a1 = Instance.new("Attachment", targetHRP)
    a0.Position = Vector3.new(0, 2, 0) -- duduk di atas kepala

    local ap = Instance.new("AlignPosition", myHRP)
    ap.MaxForce = 999999
    ap.Responsiveness = 200
    ap.Attachment0 = a0
    ap.Attachment1 = a1

    local ao = Instance.new("AlignOrientation", myHRP)
    ao.MaxTorque = 999999
    ao.Responsiveness = 200
    ao.Attachment0 = a0
    ao.Attachment1 = a1

    constraint = {ap, ao, a0, a1}
end

-- lepas duduk
local function unSit()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        for _, v in pairs(lp.Character.HumanoidRootPart:GetChildren()) do
            if v:IsA("AlignPosition") or v:IsA("AlignOrientation") or v:IsA("Attachment") then
                v:Destroy()
            end
        end
    end
    constraint = {}
end

FunTab:CreateToggle({
    Name = "🕺Mutar-Mutar)",
    CurrentValue = false,
    Flag = "SpinBodyFast",
    Callback = function(Value)
        spinActive = Value
        if spinActive then
            Rayfield:Notify({
                Title = "Aktif",
                Content = "Karakter muter kayak Kamu!",
                Duration = 3
            })

            task.spawn(function()
                local angle = 0
                while spinActive do
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        angle = angle + 50 -- kecepatan muter
                        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(angle), 0)
                    end
                    task.wait(0.01) -- semakin kecil delay, semakin cepat
                end
            end)
        else
            Rayfield:Notify({
                Title = "Nonaktif",
                Content = "Berputar berhenti.",
                Duration = 3
            })
        end
    end,
})

FunTab:CreateSection("Emote Muter")

-- Variabel
local spinning = false
local spinSpeed = 10
local conn
local targetPlayer = nil
local playerList = {}
local angle = 0

-- Update daftar player
local function updatePlayerList()
    playerList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerList, plr.Name)
        end
    end
    if #playerList == 0 then
        playerList = {"[Tidak ada player]"}
    end
    return playerList
end

-- Dropdown target
local TargetDropdown = FunTab:CreateDropdown({
    Name = "Pilih Target",
    Options = updatePlayerList(),
    CurrentOption = {"[Tidak ada player]"},
    Flag = "TargetDropdown",
    Callback = function(Option)
        local chosen = Option[1]
        targetPlayer = Players:FindFirstChild(chosen)
    end,
})

-- Tombol Refresh Player
FunTab:CreateButton({
    Name = "🔄 Refresh Player",
    Callback = function()
        local newList = updatePlayerList()
        if TargetDropdown and TargetDropdown.Refresh then
            TargetDropdown:Refresh(newList, true)
        else
            TargetDropdown:Set(newList)
        end
    end,
})

-- Toggle Spinner
FunTab:CreateToggle({
    Name = "Aktifkan Berputar (Nempel)",
    CurrentValue = false,
    Flag = "SpinnerToggle",
    Callback = function(Value)
        spinning = Value
        if spinning then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            conn = RunService.RenderStepped:Connect(function(dt)
                if not targetPlayer or not targetPlayer.Character then return end
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- Tambah sudut
                angle += math.rad(spinSpeed) * dt

                -- Ambil posisi target
                local targetCFrame = targetHRP.CFrame

                -- Nempel dengan rotasi acak seperti bola (X,Y,Z)
                hrp.CFrame = targetCFrame * CFrame.Angles(angle, angle, angle)
            end)
        else
            if conn then conn:Disconnect() conn = nil end
        end
    end,
})

-- Slider Speed
FunTab:CreateSlider({
    Name = "Kecepatan Putar",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = spinSpeed,
    Flag = "SpinSpeed",
    Callback = function(Value)
        spinSpeed = Value
    end,
})


-- Script: Romance Lempar Diri (Superman Slowmo + Pose)
-- Executor Roblox + Rayfield GUI
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local selectedPlayer = nil
local enabled = false
local pose = "Tidur"
local alreadyThrown = false
local slowDuration = 3

-- ambil daftar player (pakai DisplayName)
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName)
        end
    end
    return list
end

-- cari player berdasarkan DisplayName
local function findPlayerByDisplayName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == name then
            return p
        end
    end
    return nil
end

local RomantisTab = Window:CreateTab("💘 Romantis", 4483362458)

-- Dropdown player
local playerDropdown = RomantisTab:CreateDropdown({
    Name = "Pilih Player",
    Options = getPlayerList(),
    CurrentOption = {},
    Flag = "TargetPlayer",
    Callback = function(Option)
        selectedPlayer = Option[1]
    end,
})

-- Tombol refresh pasangan
RomantisTab:CreateButton({
    Name = "🔄 Segarkan Daftar Target",
    Callback = function()
        playerDropdown:Set(getPlayerList())
    end
})

-- Dropdown gaya jatuh
RomantisTab:CreateDropdown({
    Name = "Gaya Jatuh 💏",
    Options = {"Tidur", "Tengkurap", "Duduk", "Miring"},
    CurrentOption = {"Tidur"},
    Flag = "PosePilihan",
    Callback = function(Option)
        pose = Option[1]
    end,
})

-- Slider slowmo
RomantisTab:CreateSlider({
    Name = "Durasi Slow Motion  ⏳",
    Range = {1, 10},
    Increment = 1,
    Suffix = " detik",
    CurrentValue = 3,
    Flag = "SlowmoSlider",
    Callback = function(Value)
        slowDuration = Value
    end,
})

-- Toggle aktifkan mode romantis
RomantisTab:CreateToggle({
    Name = "💖 Aktifkan Lemparan Cinta",
    CurrentValue = false,
    Flag = "ToggleRomance",
    Callback = function(Value)
        enabled = Value
        alreadyThrown = false
        if not enabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                char.Humanoid.Sit = false
            end
        end
    end,
})

-- fungsi lempar dengan slowmo
local function throwAtTarget()
    local target = findPlayerByDisplayName(selectedPlayer)
    local char = LocalPlayer.Character
    if not (target and target.Character and char) then return end

    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not (targetHRP and myHRP and hum) then return end

    -- gaya terbang ke pasangan
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    myHRP.CFrame = myHRP.CFrame * CFrame.Angles(math.rad(-30), 0, 0)

    -- tween ke target
    local goal = {}
    goal.CFrame = targetHRP.CFrame * CFrame.new(0,0,-2)
    local tween = TweenService:Create(myHRP, TweenInfo.new(slowDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), goal)
    tween:Play()
    tween.Completed:Wait()

    -- jatuh sesuai pose
    task.wait(0.2)
    if pose == "Tidur" then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        myHRP.CFrame = myHRP.CFrame * CFrame.Angles(math.rad(90),0,0)
    elseif pose == "Tengkurap" then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        myHRP.CFrame = myHRP.CFrame * CFrame.Angles(math.rad(-90),0,0)
    elseif pose == "Duduk" then
        hum.Sit = true
    elseif pose == "Miring" then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        myHRP.CFrame = myHRP.CFrame * CFrame.Angles(0,0,math.rad(90))
    end
end

-- loop
RunService.Heartbeat:Connect(function()
    if enabled and selectedPlayer then
        if not alreadyThrown then
            throwAtTarget()
            alreadyThrown = true
        else
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if pose ~= "Duduk" then
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                end
            end
        end
    end
end)


