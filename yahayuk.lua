local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: MT Yahayyuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
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
    Puncak = CFrame.new(-577, 932, -520),
}

-- Tombol manual teleport tetap ada (Spawn sampai Puncak)
TeleTab:CreateButton({ Name = "Teleport Spawn", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.Spawn
    end
end })

TeleTab:CreateButton({ Name = "Teleport CP 1", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP1
    end
end })

TeleTab:CreateButton({ Name = "Teleport CP 2", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP2
    end
end })

TeleTab:CreateButton({ Name = "Teleport CP 3", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP3
    end
end })

TeleTab:CreateButton({ Name = "Teleport CP 4", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP4
    end
end })

TeleTab:CreateButton({ Name = "Teleport CP 5", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = teleportPoints.CP5
    end
end })

TeleTab:CreateButton({ Name = "Teleport Puncak", Callback = function()
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

TeleTab:CreateButton({
    Name = "Start Auto Teleport & Respawn Loop",
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
                local char = player.Character
                for i, cf in ipairs(autoTeleportPoints) do
                    if not isAutoTeleporting then break end
                    char = player.Character
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
                    Duration = 3,
                })
                respawnCharacter()
                task.wait(2) -- waktu tunggu setelah respawn biar stabil
            end
        end)
    end,
})

TeleTab:CreateButton({
    Name = "Stop Auto Teleport & Respawn",
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

-- (sisa kode pengaturan dan deteksi admin tetap sama, tidak aku ulang di sini)
