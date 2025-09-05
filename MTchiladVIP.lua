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

local teleportPoints = {
    Spawn = CFrame.new(-46, 10, -5),     -- Sesuaikan koordinat spawn di game kamu
    CP1 = CFrame.new(82, 118, -535),
    CP2 = CFrame.new(545, 450, 498),
    CP3 = CFrame.new(-290, 381, 457),
    CP4 = CFrame.new(-1008, 546, 1358),
    CP5 = CFrame.new(-1779, 830, 874),
    CP6 = CFrame.new(-1897, 917, 1547),
    CP7 = CFrame.new(-2270, 994, 1803),
    Puncak = CFrame.new(-3017, 1218, 1177),
}

-- Tombol manual teleport tetap ada 
TeleTab:CreateSection("Teleport Manual")
TeleTab:CreateButton({ Name = "🚩 Spawn", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.Spawn
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 1", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP1
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 2", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP2
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 3", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP3
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 4", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP4
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 5", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP5
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 6", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP6
    end
end })

TeleTab:CreateButton({ Name = "📍 Teleport CP 7", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP7
    end
end })


TeleTab:CreateButton({ Name = "⛰️ Teleport Puncak", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.Puncak
    end
end })

-- Fitur Auto Teleport CP1 sampai Puncak + Respawn + Loop
local isAutoTeleporting = false
local autoTeleportTask = nil

local autoTeleportPoints = {
    teleportPoints.CP1,
    teleportPoints.CP2,
    teleportPoints.CP3,
    teleportPoints.CP4,
    teleportPoints.CP5,
    teleportPoints.CP6,
    teleportPoints.CP7,
    teleportPoints.Puncak,
}

local function respawnCharacter()
    local player = game.Players.LocalPlayer
    if player.Character then
        player.Character:BreakJoints()
    end
    -- Tunggu karakter respawn
    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0
end

local function isAtSpawn(pos, threshold)
    local spawnPos = teleportPoints.Spawn.Position
    return (pos - spawnPos).Magnitude <= threshold
end

TeleTab:CreateSection("Teleport Otomatis")

-- Toggle Auto Teleport
TeleTab:CreateToggle({
    Name = "🏆 Auto Teleport",
    CurrentValue = false,
    Flag = "AutoTeleportToggle",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        isAutoTeleporting = Value

        if isAutoTeleporting then
            -- Start Auto Teleport
            autoTeleportTask = task.spawn(function()
                while isAutoTeleporting do
                    for i, cf in ipairs(autoTeleportPoints) do
                        if not isAutoTeleporting then break end
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = cf
                            Rayfield:Notify({
                                Title = "Auto Teleport",
                                Content = "Teleport ke CP "..i,
                                Duration = 2,
                            })
                        end
                        task.wait(2)
                    end

                    if not isAutoTeleporting then break end
                    Rayfield:Notify({
                        Title = "Respawn",
                        Content = "Respawn karakter...",
                        Duration = 2,
                    })
                    respawnCharacter()

                    -- Tunggu sampai karakter benar-benar berada di spawn
                    local maxWaitTime = 6
                    local waited = 0
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
            -- Stop Auto Teleport
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



-- Detection Tab
-- ========================
local Players = game:GetService("Players")
local DetectionTab = Window:CreateTab("Detection", 4483362458)
DetectionTab:CreateSection("Deteksi")
-- ========================
-- Helper Functions
-- ========================
local function GetPlayerSummit(player)
    local summitNumber = nil
    local character = player.Character
    if character then
        local head = character:FindFirstChild("Head")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") then
                    for _, label in ipairs(gui:GetChildren()) do
                        if label:IsA("TextLabel") then
                            local summitText = string.match(label.Text, "[Ss]ummit[^%d]*([%d,%.]+)")
                            if summitText then
                                summitText = summitText:gsub("[,%.]", "")
                                summitNumber = tonumber(summitText)
                            end
                        end
                    end
                end
            end
        end
    end
    if not summitNumber then
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            local summitStat = stats:FindFirstChild("Summit") or stats:FindFirstChild("Summits")
            if summitStat and tonumber(summitStat.Value) then
                summitNumber = tonumber(summitStat.Value)
            end
        end
    end
    return summitNumber or 0
end

local function DetectAdmins()
    local admins = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                for _, gui in ipairs(head:GetChildren()) do
                    if gui:IsA("BillboardGui") then
                        for _, label in ipairs(gui:GetChildren()) do
                            if label:IsA("TextLabel") and string.find(string.upper(label.Text), "ADMIN") then
                                table.insert(admins, {
                                    Name = player.Name,
                                    Summit = GetPlayerSummit(player)
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return admins
end

local function DetectTopSummits(limit)
    local results = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local summitNumber = GetPlayerSummit(player)
        if summitNumber then
            table.insert(results, {Name = player.Name, Summit = summitNumber})
        end
    end
    table.sort(results, function(a, b) return a.Summit > b.Summit end)
    local topN = {}
    for i = 1, math.min(limit, #results) do
        table.insert(topN, results[i])
    end
    return topN
end

-- ========================
-- Admin Detection
-- ========================
local AdminLoop
local AdminLabel

DetectionTab:CreateToggle({
    Name = "🔍 Check Admins",
    CurrentValue = false,
    Flag = "CheckAdminsToggle",
    Callback = function(Value)
        if Value then
            AdminLoop = task.spawn(function()
                local lastAdmins = ""
                while true do
                    local admins = DetectAdmins()
                    if #admins > 0 then
                        local labelText = "Admin Terdeteksi ("..#admins.."):"
                        local notifyText = labelText
                        for _, data in ipairs(admins) do
                            labelText = labelText .. "\n- " .. data.Name .. " (Summit: " .. data.Summit .. ")"
                            notifyText = notifyText .. "\n- " .. data.Name .. " (Summit: " .. data.Summit .. ")"
                        end
                        if AdminLabel then AdminLabel:Set(labelText) end
                        if notifyText ~= lastAdmins then
                            Rayfield:Notify({
                                Title = "Admin Terdeteksi!",
                                Content = notifyText,
                                Duration = 7,
                            })
                            lastAdmins = notifyText
                        end
                    else
                        if AdminLabel then AdminLabel:Set("Admin Terdeteksi: -") end
                        lastAdmins = ""
                    end
                    task.wait(5)
                end
            end)
        else
            if AdminLoop then
                task.cancel(AdminLoop)
                AdminLoop = nil
                if AdminLabel then AdminLabel:Set("Admin Terdeteksi: -") end
            end
        end
    end,
})

-- ========================
-- Summit Detection
-- ========================
local SummitLoop
local SummitLabel

DetectionTab:CreateToggle({
    Name = "🔍 Check Pro",
    CurrentValue = false,
    Flag = "CheckSummitToggle",
    Callback = function(Value)
        if Value then
            SummitLoop = task.spawn(function()
                local lastTop = ""
                while true do
                    local top3 = DetectTopSummits(3)
                    if #top3 > 0 then
                        local labelText = "Top Puncak:"
                        local notifyText = ""
                        for i, data in ipairs(top3) do
                            labelText = labelText .. "\n" .. i .. ") " .. data.Name .. " (" .. data.Summit .. ")"
                            notifyText = notifyText .. "\n" .. i .. ") " .. data.Name .. " (" .. data.Summit .. ")"
                        end
                        if SummitLabel then SummitLabel:Set(labelText) end
                        if notifyText ~= lastTop then
                            Rayfield:Notify({
                                Title = "Puncak Top 3!",
                                Content = notifyText,
                                Duration = 7,
                            })
                            lastTop = notifyText
                        end
                    else
                        if SummitLabel then SummitLabel:Set("Top Puncak: -") end
                        lastTop = ""
                    end
                    task.wait(5)
                end
            end)
        else
            if SummitLoop then
                task.cancel(SummitLoop)
                SummitLoop = nil
                if SummitLabel then SummitLabel:Set("Top Puncak: -") end
            end
        end
    end,
})

-- ========================
-- Label di paling bawah
-- ========================
AdminLabel = DetectionTab:CreateLabel("Admin Terdeteksi: -")
SummitLabel = DetectionTab:CreateLabel("Top Puncak: -")

DetectionTab:CreateSection("Fitur Lainnya")

-- ========================
-- Auto Leave Jika Admin
-- ========================
local AutoLeaveLoop

DetectionTab:CreateToggle({
    Name = "🚪 Auto Leave Jika Admin",
    CurrentValue = false,
    Flag = "AutoLeaveAdminToggle",
    Callback = function(Value)
        if Value then
            AutoLeaveLoop = task.spawn(function()
                while true do
                    local admins = DetectAdmins()
                    if #admins > 0 then
                        -- Notif dulu biar jelas
                        Rayfield:Notify({
                            Title = "Keluar Server!",
                            Content = "Admin terdeteksi, keluar otomatis...",
                            Duration = 5,
                        })
                        task.wait(1)
                        game.Players.LocalPlayer:Kick("Admin terdeteksi di server. Kamu otomatis keluar.")
                        break
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
local AutoNotifyLoop

DetectionTab:CreateToggle({
    Name = "📤 Notif Admin Masuk",
    CurrentValue = false,
    Flag = "NotifyAdminJoinToggle",
    Callback = function(Value)
        if Value then
            -- Pasang listener PlayerAdded
            AutoNotifyLoop = Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function(char)
                    task.wait(2)
                    local head = char:FindFirstChild("Head")
                    if head then
                        for _, gui in ipairs(head:GetChildren()) do
                            if gui:IsA("BillboardGui") then
                                for _, label in ipairs(gui:GetChildren()) do
                                    if label:IsA("TextLabel") and string.find(string.upper(label.Text), "ADMIN") then
                                        Rayfield:Notify({
                                            Title = "⚠️ Admin Masuk!",
                                            Content = player.Name .. " adalah Admin!",
                                            Duration = 8,
                                        })
                                    end
                                end
                            end
                        end
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
-- Tab Pengaturan
-- ========================
local SettingsTab = Window:CreateTab("Settings", 6034509993)


SettingsTab:CreateSection("Fitur Tambahan")

-- ========================
-- Wallhack Nama + Jarak
-- ========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local ESPEnabled = false
local ESPObjects = {}

-- Buat ESP nama di atas kepala dengan jarak
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
    label.TextColor3 = Color3.fromRGB(0, 255, 0) -- hijau
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Text = player.DisplayName
    label.Parent = billboard

    local function Attach(char)
        if char:FindFirstChild("Head") then
            billboard.Adornee = char.Head
            billboard.Parent = char.Head
        end
    end

    if player.Character then
        Attach(player.Character)
    end

    -- Update jarak realtime
    local distanceUpdate
    distanceUpdate = RunService.RenderStepped:Connect(function()
        if not ESPEnabled or not ESPObjects[player] then
            distanceUpdate:Disconnect()
            return
        end
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            label.Text = player.DisplayName .. " [" .. math.floor(distance) .. "m]"
        else
            label.Text = player.DisplayName .. " [N/A]"
        end
    end)

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        Attach(char)
    end)

    ESPObjects[player] = {billboard = billboard, updateConnection = distanceUpdate}
end

-- Hapus ESP
local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].updateConnection then
            ESPObjects[player].updateConnection:Disconnect()
        end
        if ESPObjects[player].billboard then
            ESPObjects[player].billboard:Destroy()
        end
        ESPObjects[player] = nil
    end
end

-- Toggle ESP semua player
local function ToggleESP(state)
    ESPEnabled = state
    if ESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                CreateNameESP(plr)
            end
        end

        -- Player baru join
        Players.PlayerAdded:Connect(function(plr)
            if ESPEnabled and plr ~= LocalPlayer then
                CreateNameESP(plr)
            end
        end)

        -- Player leaving
        Players.PlayerRemoving:Connect(function(plr)
            RemoveESP(plr)
        end)
    else
        for _, obj in pairs(ESPObjects) do
            if obj.updateConnection then obj.updateConnection:Disconnect() end
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


-- Toggle di Settings Walkspeed
-- Default Values
SettingsTab:CreateSection("Pengaturan")
-- Default Values
local defaultWalkSpeed = 16
local defaultInfJump = false
local walkSpeedEnabled = true -- default toggle ON
-- WalkSpeed Slider
local WalkSpeedSlider = SettingsTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = defaultWalkSpeed,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        if walkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

-- WalkSpeed Toggle
local WalkSpeedToggle = SettingsTab:CreateToggle({
    Name = "WalkSpeed On/Off",
    CurrentValue = walkSpeedEnabled,
    Flag = "WalkSpeedToggle",
    Callback = function(Value)
        walkSpeedEnabled = Value
        if not walkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            -- reset ke default saat toggle OFF
            LocalPlayer.Character.Humanoid.WalkSpeed = defaultWalkSpeed
        end
    end,
})




-- ===== Efek Hantu Toggle =====
local player = game.Players.LocalPlayer
local originalDisplayName = player.DisplayName
local ghostToggle = false

SettingsTab:CreateSection("Ubah Nama")

SettingsTab:CreateToggle({
    Name = "Nama Aneh",
    CurrentValue = false,
    Flag = "GhostModeToggle",
    Callback = function(Value)
        ghostToggle = Value

        local char = player.Character
        if not char then return end

        if ghostToggle then
            -- 1. Ubah DisplayName menjadi ??? (semua pemain lihat)
            player.DisplayName = "???"

            -- 2. Kepala transparan untuk efek hantu (local only)
            local head = char:FindFirstChild("Head")
            if head then
                head.Transparency = 0.7 -- bisa diubah level transparansi
                local face = head:FindFirstChild("face")
                if face then face.Transparency = 1 end
            end

            -- 3. Bisa juga bikin seluruh body semi-transparan lokal
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0.5
                end
            end
        else
            -- Kembalikan ke normal
            player.DisplayName = originalDisplayName

            local head = char:FindFirstChild("Head")
            if head then
                head.Transparency = 0
                local face = head:FindFirstChild("face")
                if face then face.Transparency = 0 end
            end

            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end,
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
    Name = "🗿 Joget cacingan",
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
