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

TeleTab:CreateButton({ Name = "Teleport CP 1", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-62, 3, -30) end })
TeleTab:CreateButton({ Name = "Teleport CP 2", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(100, 50, 100) end })
TeleTab:CreateButton({ Name = "Teleport CP 3", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500) end })
TeleTab:CreateButton({ Name = "Teleport CP 4", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500) end })
TeleTab:CreateButton({ Name = "Teleport CP 5", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500) end })
TeleTab:CreateButton({ Name = "Teleport Puncak", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500) end })

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
