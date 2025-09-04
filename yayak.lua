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
    Spawn = CFrame.new(-932, 170, 881),     -- Sesuaikan koordinat spawn di game kamu
    CP1 = CFrame.new(-430, 250, 789),
    CP2 = CFrame.new(-347, 389, 522),
    CP3 = CFrame.new(288, 430, 506),
    CP4 = CFrame.new(334, 491, 349),
    CP5 = CFrame.new(224, 315, -147),
    Puncak = CFrame.new(-587, 906, -511),
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

TeleTab:CreateButton({ Name = "📍 Teleport Puncak", Callback = function()
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
TeleTab:CreateButton({
    Name = "🏁 Start Auto Teleport",
    Callback = function()
        if isAutoTeleporting then
            Rayfield:Notify({
                Title = "Auto Teleport",
                Content = "Auto teleport sudah berjalan!",
                Duration = 3,
            })
            return
        end
        isAutoTeleporting = true
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
                            Content = "Teleport ke CP "..i,
                            Duration = 2,
                        })
                    end
                    task.wait(2)
                end

                -- Respawn setelah sampai Puncak
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
    end,
})

TeleTab:CreateButton({
    Name = "🛑 Stop Auto Teleport ",
    Callback = function()
        if isAutoTeleporting then
            isAutoTeleporting = false
            if autoTeleportTask then
                task.cancel(autoTeleportTask)
                autoTeleportTask = nil
            end
            Rayfield:Notify({
                Title = "Auto Teleport",
                Content = "Auto teleport dan respawn dihentikan!",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Auto Teleport",
                Content = "Auto teleport belum berjalan.",
                Duration = 3,
            })
        end
    end,
})



-- ========================
-- Tab Pengaturan
-- ========================
local SettingsTab = Window:CreateTab("Settings", 6034509993)
SettingsTab:CreateSection("Pengaturan")
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

SettingsTab:CreateSection("Lainnya")
-- ========================
-- ESP Semua Player
-- ========================
local ESPEnabled = false
local ESPObjects = {}

local function CreateESP(player)
    if ESPObjects[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character or player.CharacterAdded:Wait()
    ESPObjects[player] = highlight

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        highlight.Parent = char
    end)
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function ToggleESP(state)
    ESPEnabled = state
    if ESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer then
                CreateESP(plr)
            end
        end
        Players.PlayerAdded:Connect(function(plr)
            if ESPEnabled and plr ~= Players.LocalPlayer then
                CreateESP(plr)
            end
        end)
        Players.PlayerRemoving:Connect(function(plr)
            RemoveESP(plr)
        end)
    else
        for _, obj in pairs(ESPObjects) do
            obj:Destroy()
        end
        ESPObjects = {}
    end
end

SettingsTab:CreateToggle({
    Name = "ESP Semua Player",
    CurrentValue = false,
    Flag = "ESPAllPlayers",
    Callback = function(Value)
        ToggleESP(Value)
    end,
})

-- ========================
-- Teleport ke Player
-- ========================
local SelectedPlayer = nil

local function RefreshPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return names
end

local PlayerDropdown = SettingsTab:CreateDropdown({
    Name = "Pilih Player",
    Options = RefreshPlayerList(),
    CurrentOption = {},
    Flag = "PlayerDropdown",
    Callback = function(Option)
        SelectedPlayer = Option[1]
    end,
})

-- Tombol teleport
SettingsTab:CreateButton({
    Name = "Teleport ke Player",
    Callback = function()
        if SelectedPlayer then
            local target = Players:FindFirstChild(SelectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    Rayfield:Notify({
                        Title = "Teleport",
                        Content = "Berhasil teleport ke " .. SelectedPlayer,
                        Duration = 5,
                    })
                end
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Tidak ada player dipilih!",
                Duration = 5,
            })
        end
    end,
})

-- Tombol refresh dropdown
SettingsTab:CreateButton({
    Name = "Refresh Daftar Player",
    Callback = function()
        PlayerDropdown:Refresh(RefreshPlayerList(), true)
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
    Name = "Check Admins",
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
    Name = "Check Pro",
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
    Name = "Auto Leave Jika Admin",
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
    Name = "Notif Admin Masuk",
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
