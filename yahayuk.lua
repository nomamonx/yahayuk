local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: GACOOOR",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
})

-- ========================
-- Tab Informasi
-- ========================
local InfoTab = Window:CreateTab("Informasi", 4483362458)

Rayfield:Notify({
   Title = "Script Dimuat",
   Content = "Telaso berhasil muncul!",
   Duration = 6.5,
   Image = 4483362458,
})

InfoTab:CreateButton({
   Name = "Tes Tombol",
   Callback = function()
       Rayfield:Notify({
          Title = "Tombol Ditekan",
          Content = "Berhasil menekan tombol di Tab Informasi!",
          Duration = 5,
       })
   end,
})

-- ========================
-- Tab Teleport
-- ========================
local TeleTab = Window:CreateTab("Teleport", 4483362458)

TeleTab:CreateButton({
   Name = "Teleport ke tengah",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-62, 3, -30)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport ke Base Gunung",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(100, 50, 100)
   end,
})

TeleTab:CreateButton({
   Name = "Teleport ke Laut",
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
