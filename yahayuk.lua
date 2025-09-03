-- Script GUI Teleport + Anti-AFK
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: Mt.Yahayuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By Agus",
})

-- Tab utama
local MainTab = Window:CreateTab("Informasi", 4483362458)

Rayfield:Notify({
   Title = "Teleport System Dimuat",
   Content = "Script berhasil Telaso. Selamat mencoba!",
   Duration = 6.5,
   Image = 4483362458,
})

-- Tombol Anti AFK
local AntiAFK = MainTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = true,
   Flag = "AntiAFK",
   Callback = function(Value)
       if Value then
           local vu = game:GetService("VirtualUser")
           game:GetService("Players").LocalPlayer.Idled:Connect(function()
               vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
               task.wait(1)
               vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
           end)
       end
   end,
})

-- Tombol Teleport
local Teleport = MainTab:CreateButton({
   Name = "Teleport ke Shop",
   Callback = function()
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(10,5,10) -- ubah posisi teleport
   end,
})
