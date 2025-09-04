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

-- ========================
-- Deteksi Admin & Summit (Universal)
-- ========================
local Players = game:GetService("Players")

-- Fungsi deteksi Admin dari BillboardGui
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
                                table.insert(admins, player.Name)
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

-- Fungsi deteksi Summit (BillboardGui + leaderstats)
local function DetectHighestSummit()
    local highestSummit = 100 -- minimal threshold
    local highestPlayer = nil

    for _, player in ipairs(Players:GetPlayers()) do
        local summitNumber = nil

        -- 1) Cek dari BillboardGui
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

        -- 2) Kalau nggak ada, cek leaderstats
        if not summitNumber then
            local stats = player:FindFirstChild("leaderstats")
            if stats then
                local summitStat = stats:FindFirstChild("Summit") or stats:FindFirstChild("Summits")
                if summitStat and tonumber(summitStat.Value) then
                    summitNumber = tonumber(summitStat.Value)
                end
            end
        end

        -- 3) Bandingkan dengan summit tertinggi
        if summitNumber and summitNumber > highestSummit then
            highestSummit = summitNumber
            highestPlayer = player.Name
        end
    end

    return highestPlayer, highestSummit
end

-- ========================
-- UI Settings
-- ========================

-- Label status (real-time)
local AdminLabel = SettingsTab:CreateLabel("Admin Terdeteksi: (Belum ada)")
local SummitLabel = SettingsTab:CreateLabel("Summit Tertinggi: (Belum ada)")

-- Toggle: Check Admin
local CheckAdminLoop
local lastAdmins = {}

SettingsTab:CreateToggle({
    Name = "Check Admin (Beta)",
    CurrentValue = false,
    Flag = "CheckAdminToggle",
    Callback = function(Value)
        if Value then
            CheckAdminLoop = task.spawn(function()
                while true do
                    local admins = DetectAdmins()
                    if #admins > 0 then
                        AdminLabel:Set("Admin Terdeteksi: " .. table.concat(admins, ", "))
                        if table.concat(admins, ",") ~= table.concat(lastAdmins, ",") then
                            Rayfield:Notify({
                                Title = "Admin Terdeteksi!",
                                Content = "Admin: " .. table.concat(admins, ", "),
                                Duration = 5,
                            })
                            lastAdmins = admins
                        end
                    else
                        AdminLabel:Set("Admin Terdeteksi: (Tidak ada)")
                        lastAdmins = {}
                    end
                    task.wait(5)
                end
            end)
        else
            if CheckAdminLoop then
                task.cancel(CheckAdminLoop)
                CheckAdminLoop = nil
            end
            AdminLabel:Set("Admin Terdeteksi: (Belum aktif)")
        end
    end,
})

-- Toggle: Check Summit > 100
local CheckSummitLoop
local lastSummitPlayer = nil

SettingsTab:CreateToggle({
    Name = "Check Summit Pro",
    CurrentValue = false,
    Flag = "CheckSummitToggle",
    Callback = function(Value)
        if Value then
            CheckSummitLoop = task.spawn(function()
                while true do
                    local playerName, summitCount = DetectHighestSummit()
                    if playerName then
                        SummitLabel:Set("Summit Tertinggi: " .. playerName .. " (" .. summitCount .. ")")
                        if playerName ~= lastSummitPlayer then
                            Rayfield:Notify({
                                Title = "Summit Tertinggi Terdeteksi!",
                                Content = playerName .. " punya Summit: " .. summitCount,
                                Duration = 5,
                            })
                            lastSummitPlayer = playerName
                        end
                    else
                        SummitLabel:Set("Summit Tertinggi: (Tidak ada >100)")
                        lastSummitPlayer = nil
                    end
                    task.wait(5)
                end
            end)
        else
            if CheckSummitLoop then
                task.cancel(CheckSummitLoop)
                CheckSummitLoop = nil
            end
            SummitLabel:Set("Summit Tertinggi: (Belum aktif)")
        end
    end,
})
