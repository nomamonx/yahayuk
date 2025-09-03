-- GUI Script Mt.Yahayuk (Support Delta Executor)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("VIP Script: Mt.Yahayuk", "DarkTheme")

-- Tab Utama
local Tab = Window:NewTab("Main Menu")
local Section = Tab:NewSection("Fitur")

-- Notifikasi awal
game.StarterGui:SetCore("SendNotification", {
    Title = "Script Dimuat",
    Text = "VIP Script Mt.Yahayuk aktif!",
    Duration = 5
})

-- Tombol Teleport
Section:NewButton("Teleport ke Spawn", "Pindah ke lokasi spawn", function()
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0) -- ganti posisi sesuai map
    end
end)

-- Anti AFK
Section:NewToggle("Anti-AFK", "Hindari kick AFK otomatis", function(state)
    if state then
        local vu = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
        game.StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = "Anti-AFK diaktifkan",
            Duration = 4
        })
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = "Anti-AFK dimatikan",
            Duration = 4
        })
    end
end)

-- Tombol Tes
Section:NewButton("Tes Notifikasi", "Cek apakah GUI berjalan", function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "Notifikasi Tes",
        Text = "GUI berjalan dengan baik!",
        Duration = 4
    })
end)
