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

TeleTab:CreateButton({
   Name = "Teleport CP 1",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-62, 3, -30)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport CP 2",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(100, 50, 100)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport CP 3",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport CP 4",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport CP 5",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport Puncak",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10, 500)
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
-- Tambahan Fitur Deteksi Admin & Puncak 1000an
-- ========================
local Players = game:GetService("Players")

-- Fungsi deteksi admin
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

-- Fungsi deteksi puncak >= 1000
local function DetectPuncak1000()
    local leaderboard = workspace:FindFirstChild("Leaderboard")
    if not leaderboard then return false end
    for _, stat in ipairs(leaderboard:GetChildren()) do
        local puncak = stat:FindFirstChild("Puncak")
        if puncak and tonumber(puncak.Value) >= 1000 then
            return true
        end
    end
    return false
end

-- Tombol cek admin
SettingsTab:CreateButton({
    Name = "Check Admin",
    Callback = function()
        task.spawn(function()
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
    end,
})

-- Tombol cek puncak 1000an
SettingsTab:CreateButton({
    Name = "Check Puncak 1000an",
    Callback = function()
        task.spawn(function()
            while true do
                if DetectPuncak1000() then
                    Rayfield:Notify({
                        Title = "Puncak Tinggi!",
                        Content = "Ada pemain dengan puncak 1000+!",
                        Duration = 5,
                    })
                end
                task.wait(5)
            end
        end)
    end,
})
