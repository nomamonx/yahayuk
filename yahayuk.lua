local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: MT Yahayyuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
})
-- Tab Informasi
-- ========================
local InfoTab = Window:CreateTab("Informasi", 4483362458)

Rayfield:Notify({
   Title = "Script Dimuat",
   Content = "TELASO berhasil muncul!!!",
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
TeleTab:CreateLabel("Teleport Manual")
-- Tombol manual teleport tetap ada (Spawn sampai Puncak)
TeleTab:CreateButton({ Name = "🚩 Teleport Spawn", Callback = function()
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
local SettingsTab = Window:CreateTab("Pengaturan", 4483362458)

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

-- ========================
-- Tambahan: Deteksi Admin dan Summit > 100
-- ========================
local Players = game:GetService("Players")

-- Fungsi deteksi admin dari BillboardGui
local function DetectAdmins()
    local adminCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                for _, gui in ipairs(head:GetChildren()) do
                    if gui:IsA("BillboardGui") then
                        for _, label in ipairs(gui:GetChildren()) do
                            if label:IsA("TextLabel") and string.find(string.upper(label.Text), "ADMIN") then
                                adminCount += 1
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return adminCount
end

-- Fungsi deteksi Summit > 100
local function DetectSummitAbove100()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                for _, gui in ipairs(head:GetChildren()) do
                    if gui:IsA("BillboardGui") then
                        for _, label in ipairs(gui:GetChildren()) do
                            if label:IsA("TextLabel") then
                                local summitText = string.match(label.Text, "Summit:%s*(%d+)")
                                if summitText and tonumber(summitText) > 100 then
                                    return true, player.Name, tonumber(summitText)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Toggle: Check Admin
local CheckAdminLoop
SettingsTab:CreateToggle({
    Name = "Check Admin (Beta)",
    CurrentValue = false,
    Flag = "CheckAdminToggle",
    Callback = function(Value)
        if Value then
            CheckAdminLoop = task.spawn(function()
                while true do
                    local adminCount = DetectAdmins()
                    if adminCount > 0 then
                        Rayfield:Notify({
                            Title = "Admin Terdeteksi!",
                            Content = tostring(adminCount).." Admin terdeteksi di server!",
                            Duration = 5,
                        })
                    end
                    task.wait(5)
                end
            end)
        else
            if CheckAdminLoop then
                task.cancel(CheckAdminLoop)
                CheckAdminLoop = nil
            end
        end
    end,
})

-- Toggle: Check Summit > 100
-- Toggle: Check Summit > 100
local CheckSummitLoop
SettingsTab:CreateToggle({
    Name = "Check Pro",
    CurrentValue = false,
    Flag = "CheckSummitToggle",
    Callback = function(Value)
        if Value then
            CheckSummitLoop = task.spawn(function()
                while true do
                    local highestSummit = 100 -- minimal threshold
                    local highestPlayer = nil

                    for _, player in ipairs(Players:GetPlayers()) do
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
                                                    local summitNumber = tonumber(summitText)
                                                    if summitNumber and summitNumber > highestSummit then
                                                        highestSummit = summitNumber
                                                        highestPlayer = player.Name
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if highestPlayer then
                        Rayfield:Notify({
                            Title = "Summit Tertinggi Terdeteksi!",
                            Content = highestPlayer .. " punya Summit: " .. highestSummit,
                            Duration = 5,
                        })
                    end

                    task.wait(5)
                end
            end)
        else
            if CheckSummitLoop then
                task.cancel(CheckSummitLoop)
                CheckSummitLoop = nil
            end
        end
    end,
})

-- (sisa kode pengaturan dan deteksi admin tetap sama, tidak aku ulang di sini)
