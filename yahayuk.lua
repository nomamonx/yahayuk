local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: MT Yahayyuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
})

-- ========================
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

TeleTab:CreateButton({ Name = "Teleport Spawn", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-932, 170, 881) end })
TeleTab:CreateButton({ Name = "Teleport CP 1", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-431, 250, 789) end })
TeleTab:CreateButton({ Name = "Teleport CP 2", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-347, 389, 522) end })
TeleTab:CreateButton({ Name = "Teleport CP 3", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(288, 430, 506) end })
TeleTab:CreateButton({ Name = "Teleport CP 4", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(334, 491, 349) end })
TeleTab:CreateButton({ Name = "Teleport CP 5", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(224, 315, -147) end })
TeleTab:CreateButton({ Name = "Teleport Puncak", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-584, 938, -520) end })

-- 🌀 Toggle: Loop Teleport Puncak
local TeleportLoop
TeleTab:CreateToggle({
    Name = "Loop Teleport ke Puncak",
    CurrentValue = false,
    Flag = "LoopTeleportPuncak",
    Callback = function(Value)
        if Value then
            TeleportLoop = task.spawn(function()
                while true do
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-584, 938, -520)
                    task.wait(5) -- jeda 5 detik
                end
            end)
        else
            if TeleportLoop then
                task.cancel(TeleportLoop)
                TeleportLoop = nil
            end
        end
    end,
})

-- 🛑 Tombol: Stop Loop Teleport
TeleTab:CreateButton({
    Name = "Stop Loop Teleport",
    Callback = function()
        if TeleportLoop then
            task.cancel(TeleportLoop)
            TeleportLoop = nil
            Rayfield:Notify({
                Title = "Loop Teleport Dihentikan",
                Content = "Teleport otomatis ke puncak telah dimatikan.",
                Duration = 5,
            })
        else
            Rayfield:Notify({
                Title = "Tidak Aktif",
                Content = "Loop teleport belum aktif atau sudah dihentikan.",
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
    Name = "Check Admin (Notif Loop)",
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
local CheckSummitLoop
SettingsTab:CreateToggle({
    Name = "Check Summit > 100 (Notif Loop)",
    CurrentValue = false,
    Flag = "CheckSummitToggle",
    Callback = function(Value)
        if Value then
            CheckSummitLoop = task.spawn(function()
                while true do
                    local detected, playerName, summit = DetectSummitAbove100()
                    if detected then
                        Rayfield:Notify({
                            Title = "Summit Tinggi!",
                            Content = playerName .. " punya Summit: " .. summit,
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
