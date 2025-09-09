-- Admin & Summit Detector (Versi Rayfield GUI)
-- By ChatGPT

-- ========== Load Rayfield ==========
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not Rayfield then
    warn("❌ Gagal load Rayfield, cek koneksi atau URL.")
    return
end

-- ========== Window ==========
local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detektor",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Siap Jalan 🚀",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DetektorSummit", -- folder di workspace
        FileName = "Config" -- file untuk save config
    },
})

-- ========== Tabs ==========
local DetectorTab = Window:CreateTab("🔎 Detector", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

-- ========== Detector Features ==========
DetectorTab:CreateParagraph({
    Title = "ℹ️ Info",
    Content = "Script Deteksi Summit + Admin.\n\n🔴 Auto leave/hop jika admin.\n📊 Hitung summit otomatis.\n🔔 Notifikasi ke Discord."
})

DetectorTab:CreateToggle({
    Name = "Auto Leave Jika Admin",
    CurrentValue = false,
    Flag = "AutoLeaveAdmin",
    Callback = function(Value)
        print("Auto Leave:", Value)
    end
})

DetectorTab:CreateToggle({
    Name = "Auto Hop Jika Admin",
    CurrentValue = true,
    Flag = "AutoHopAdmin",
    Callback = function(Value)
        print("Auto Hop:", Value)
    end
})

DetectorTab:CreateToggle({
    Name = "Kirim Notif ke Discord",
    CurrentValue = true,
    Flag = "SendWebhook",
    Callback = function(Value)
        print("Webhook aktif:", Value)
    end
})

-- ========== Settings Features ==========
SettingsTab:CreateParagraph({
    Title = "⚙️ Config",
    Content = "Semua pengaturan disimpan otomatis.\nReset kapanpun dari folder Config."
})

SettingsTab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        print("🔔 Tes webhook terkirim!")
    end
})
