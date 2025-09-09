-- ===== Admin & Summit Detector Part 1/3 =====
-- By: ChatGPT (modifikasi panjang & lengkap)
-- WARNING: webhook digabung permanen, nama player di webhook disamarkan

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Config =====
local Config = {
    AutoHop = true,            -- auto hop jika admin terdeteksi
    AutoLeave = false,         -- auto kick jika hop gagal
    SendWebhook = true,        -- kirim notifikasi ke discord
    ScanInterval = 2.5,        -- detik
    SummitDetectMethod = "leaderstat", -- leaderstat / position
    SummitPositionY = 1000,
    SummitPositionHold = 1.2,
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/XXXX", -- <--- Ganti jika perlu
}

-- Blacklist
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

-- Rank keywords
local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- ===== Helper Functions =====
local function lower(s) return (type(s) == "string" and string.lower(s) or "") end

-- Safe webhook send
local function SendWebhook(content)
    if not Config.SendWebhook then return false, "disabled" end
    local url = Config.WebhookURL
    if not url or url == "" then return false, "no webhook" end

    -- Obfuscate player names (replace letters with X)
    content = content:gsub("([%w_]+)", function(match)
        if #match > 2 then
            return string.rep("X", #match)
        else
            return match
        end
    end)

    local body = HttpService:JSONEncode({ content = content })
    local ok, err
    if syn and syn.request then
        ok, err = pcall(function() syn.request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body}) end)
    elseif http_request then
        ok, err = pcall(function() http_request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body}) end)
    elseif request then
        ok, err = pcall(function() request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body}) end)
    else
        ok, err = pcall(function() game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson) end)
    end
    if not ok then warn("SendWebhook failed:", err) return false, tostring(err) end
    return true
end

-- Format time helper
local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec/60)
    local s = sec%60
    return string.format("%02dm:%02ds", m, s)
end

-- ===== Rayfield Window =====
local ok, Rayfield = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
if not ok or not Rayfield then
    warn("Rayfield gagal dimuat.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detektor",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Siap jalan"
})

local DetTab = Window:CreateTab("Detektor")

-- UI helpers
local function CreateLabel(text) if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(text) end return {Set=function() end} end
local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end end
local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end end
local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end end
local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield.Notify({Title=title,Content=content,Duration=5}) else warn(title,content) end end

-- ===== UI =====
local AdminLabel = CreateLabel("Admin Terdeteksi: -")
local SummitLabel = CreateLabel("Summit: 0 | Last: 00m:00s")
local StatusLabel = CreateLabel("Status: Idle")

local toggleAutoHop = CreateToggle({Name="🌍 Auto Hop jika Admin", CurrentValue=Config.AutoHop, Callback=function(v) Config.AutoHop=v end})
local toggleAutoLeave = CreateToggle({Name="🚪 Auto Leave jika Admin", CurrentValue=Config.AutoLeave, Callback=function(v) Config.AutoLeave=v end})
local toggleSendWebhook = CreateToggle({Name="📲 Kirim Notif ke Discord (Webhook)", CurrentValue=Config.SendWebhook, Callback=function(v) Config.SendWebhook=v end})
local inputWebhook = CreateTextBox({Name="Webhook URL", PlaceholderText=Config.WebhookURL, Text=Config.WebhookURL or "", Callback=function(txt) Config.WebhookURL=txt or Config.WebhookURL end})
local inputScanInterval = CreateTextBox({Name="Scan Interval (detik)", PlaceholderText=tostring(Config.ScanInterval), Text=tostring(Config.ScanInterval), Callback=function(txt) local n=tonumber(txt) if n and n>=0.5 then Config.ScanInterval=n end end})
local btnTestWebhook = CreateButton({Name="📡 Test Webhook", Callback=function() local ok,err=SendWebhook("✅ Test webhook dari Detektor") if ok then Notify("Webhook","Test terkirim") else Notify("Webhook Gagal",tostring(err)) end end})
local btnReset = CreateButton({Name="🔄 Reset ke default", Callback=function() Notify("Reset","Reload manual diperlukan") end})

-- ===== Admin Detection Functions =====
local function isBlacklisted(player)
    local uname, dname = lower(player.Name), lower(player.DisplayName)
    for _,b in ipairs(BlacklistNames) do
        if uname==lower(b) or dname==lower(b) or uname:find(lower(b),1,true) or dname:find(lower(b),1,true) then
            return true,"BlacklistName:"..b
        end
    end
    return false,nil
end

local function hasRankKeywordInName(player)
    local uname,dname = lower(player.Name), lower(player.DisplayName)
    for _,kw in ipairs(RankKeywords) do
        local lk = lower(kw)
        if uname:find(lk,1,true) or dname:find(lk,1,true) then
            return true,"NameContains:"..kw
        end
    end
    return false,nil
end

local function guiAdminDetect(player)
    if not player.Character then return false,nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false,nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
                    if text:match("^[A-Z0-9%s%p]+$") then
                        for _,kw in ipairs(RankKeywords) do
                            if text:find(kw) then return true,"GuiText:"..text end
                        end
                    end
                end
            end
        end
    end
    return false,nil
end

-- End of Part 1
-- ===== Admin & Summit Detector Part 2/3 =====
-- By: ChatGPT (lanjutan panjang)

-- ===== Admin Handling =====
local handlingAdmin = false
local lastAdminDetectTime = 0
local adminCooldown = 6

local function serverHopAttempt()
    local maxPages = 6
    local pageCursor = nil
    local found = nil
    for page=1,maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end
        local ok,res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then break end
        local ok2,json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or not json or type(json.data)~="table" then break end
        for _,srv in ipairs(json.data) do
            if type(srv)=="table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id)~=tostring(JobId) and srv.playing<srv.maxPlayers then
                    found = srv.id
                    break
                end
            end
        end
        if found then break end
        pageCursor = json.nextPageCursor
        if not pageCursor then break end
    end
    if found then
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId,found,LocalPlayer) end)
        return true
    end
    return false
end

local function handleAdminDetected(player, reason)
    if handlingAdmin then return end
    local now = tick()
    if now - lastAdminDetectTime < adminCooldown then return end
    handlingAdmin = true
    lastAdminDetectTime = now

    local status = (player and player:IsDescendantOf(game)) and "Online" or "Offline"
    local message = ("⚠️ Admin Detected: **%s**\nReason: %s\nStatus: %s\nPlaceId: %d\nTime: %s"):format(
        tostring(player and player.Name or "Unknown"),
        tostring(reason or "-"),
        status,
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )

    -- Update UI
    pcall(function() AdminLabel:Set("Admin Terdeteksi: " .. tostring(player and player.Name or "Unknown") .. " (" .. tostring(reason) .. ")") end)
    pcall(function() StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(player and player.Name or "Unknown")) end)

    -- Send webhook
    pcall(function() SendWebhook(message) end)

    -- Notify in-game
    Notify("⚠️ Admin Terdeteksi", tostring(player and player.Name or "Unknown") .. " (" .. tostring(reason) .. ")")

    -- Action: hop or leave
    if Config.AutoHop then
        task.spawn(function()
            task.wait(0.6)
            local ok = pcall(serverHopAttempt)
            if not ok and Config.AutoLeave then
                pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(player and player.Name or "Unknown")) end)
            end
        end)
    elseif Config.AutoLeave then
        task.spawn(function()
            task.wait(0.6)
            pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(player and player.Name or "Unknown")) end)
        end)
    end

    task.delay(8,function() handlingAdmin=false end)
end

-- Single-player check
local function CheckPlayerForAdmin(player)
    if not player then return false end
    local ok,reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then handleAdminDetected(player,reason) return true end
    local ok2,reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then handleAdminDetected(player,reason2) return true end
    local ok3,reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then handleAdminDetected(player,reason3) return true end
    return false
end

-- ===== Summit Tracking =====
local mySummitCount = 0
local myLastRespawn = tick()
local myLastSummitTime = 0

if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function()
        myLastRespawn = tick()
        pcall(function() SummitLabel:Set("Summit: "..mySummitCount.." | Last: "..FormatTimeSec(myLastSummitTime)) end)
    end)
end

local function OnSummitReached()
    local now = tick()
    local timeTaken = math.floor(now - myLastRespawn)
    myLastSummitTime = timeTaken
    mySummitCount = mySummitCount + 1
    pcall(function() SummitLabel:Set("Summit: "..mySummitCount.." | Last: "..FormatTimeSec(myLastSummitTime)) end)

    local msg = ("✅ Summit Reached!\nPlayer: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        mySummitCount,
        myLastSummitTime,
        FormatTimeSec(myLastSummitTime),
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )
    pcall(function() SendWebhook(msg) end)
    Notify("🏔️ Summit", "Summit tercapai! Waktu: "..tostring(FormatTimeSec(myLastSummitTime)))
    myLastRespawn = tick()
end

-- Leaderstat watcher
local leaderstatWatching = false
local function TryStartLeaderstatWatcher()
    if leaderstatWatching then return end
    leaderstatWatching = true
    task.spawn(function()
        while true do
            if not LocalPlayer or not LocalPlayer.Parent then break end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Summit") and typeof(ls.Summit.Value)=="number" then
                local lastVal = ls.Summit.Value
                ls.Summit.Changed:Connect(function(newVal)
                    pcall(function()
                        if type(newVal)=="number" and newVal>lastVal then
                            lastVal=newVal
                            OnSummitReached()
                        else
                            lastVal=newVal
                        end
                    end)
                end)
                break
            end
            task.wait(1)
        end
    end)
end

-- Position-based watcher
local positionHoldTimer = 0
local function TryStartPositionWatcher()
    task.spawn(function()
        while true do
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                if hrp.Position.Y >= (Config.SummitPositionY or 1000) then
                    positionHoldTimer = positionHoldTimer + 0.5
                    if positionHoldTimer >= (Config.SummitPositionHold or 1.2) then
                        OnSummitReached()
                        positionHoldTimer = 0
                        task.wait(3)
                    end
                else
                    positionHoldTimer = 0
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Start summit detection
if Config.SummitDetectMethod=="leaderstat" then
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
elseif Config.SummitDetectMethod=="position" then
    TryStartPositionWatcher()
else
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
end

-- End of Part 2
-- ===== Admin & Summit Detector Part 3/3 =====
-- By: ChatGPT (lanjutan panjang terakhir)

-- ===== Main Scanner Loop =====
task.spawn(function()
    while true do
        local players = Players:GetPlayers()
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdmin(pl) end)
            end
        end
        -- Update status UI
        pcall(function()
            StatusLabel:Set("Status: Running | Players: " .. tostring(#players))
        end)
        task.wait(Config.ScanInterval or 2.5)
    end
end)

-- ===== Initial UI Update =====
pcall(function()
    AdminLabel:Set("Admin Terdeteksi: -")
    SummitLabel:Set("Summit: "..mySummitCount.." | Last: "..FormatTimeSec(myLastSummitTime))
    StatusLabel:Set("Status: Idle")
end)

-- ===== Final Notify =====
Notify("Detektor Aktif", "Admin & Summit Detector berjalan. Webhook permanen disimpan di script.")

-- Optional: Test webhook on start
pcall(function() SendWebhook("🟢 Detector started | Player: " .. (LocalPlayer and LocalPlayer.Name or "Unknown")) end)

-- ===== Extra Safety Features (Optional) =====
-- Anti-crash: catch unexpected errors globally
local function GlobalSafeCall(func)
    local ok,err = pcall(func)
    if not ok then warn("Error caught:", err) end
end

-- Reconnect player listeners on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    GlobalSafeCall(function()
        -- reset timers
        myLastRespawn = tick()
        positionHoldTimer = 0
        pcall(function() SummitLabel:Set("Summit: "..mySummitCount.." | Last: "..FormatTimeSec(myLastSummitTime)) end)
    end)
end)

-- Optional: Extra periodic heartbeat for safety
task.spawn(function()
    while true do
        task.wait(15)
        GlobalSafeCall(function()
            -- ensure UI still updating
            StatusLabel:Set("Status: Running | Players: "..tostring(#Players:GetPlayers()))
        end)
    end
end)

-- End of Part 3/3


-- ========================
-- Tab Teleport
-- ========================
local TeleTab = Window:CreateTab("Teleport", 4483362458)

-- Variabel delay default (khusus auto teleport)
local AutoTeleportDelay = 2


local teleportPoints = {
    Spawn = CFrame.new(-932, 170, 881),
    CP1 = CFrame.new(-418, 250, 766),
    CP2 = CFrame.new(-347, 389, 522),
    CP3 = CFrame.new(288, 430, 506),
    CP4 = CFrame.new(334, 491, 349),
    CP5 = CFrame.new(210, 315, -148),
    Puncak = CFrame.new(-587, 906, -511),
}

-- Manual Teleport TANPA delay
TeleTab:CreateSection("Teleport Manual")
TeleTab:CreateButton({ Name = "🚩 Spawn", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Spawn end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 1", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP1 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 2", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP2 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 3", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP3 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 4", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP4 end })
TeleTab:CreateButton({ Name = "📍 Teleport CP 5", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.CP5 end })
TeleTab:CreateButton({ Name = "📍 Teleport Puncak", Callback = function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportPoints.Puncak end })

-- Auto Teleport
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
    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0
end

local function isAtSpawn(pos, threshold)
    local spawnPos = teleportPoints.Spawn.Position
    return (pos - spawnPos).Magnitude <= threshold
end

TeleTab:CreateSection("Teleport Otomatis")
TeleTab:CreateToggle({
    Name = "⚡ Auto Teleport )",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(Value)
        isAutoTeleporting = Value
        if Value then
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
                                Content = "Teleport ke CP " .. i,
                                Duration = 2,
                            })
                        end
                        task.wait(AutoTeleportDelay) -- delay sesuai slider
                    end

                    if not isAutoTeleporting then break end
                    Rayfield:Notify({
                        Title = "Respawn",
                        Content = "Respawn karakter...",
                        Duration = 2,
                    })
                    respawnCharacter()

                    -- Tunggu sampai karakter benar-benar di spawn
                    local maxWaitTime, waited = 6, 0
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
        else
            if autoTeleportTask then
                task.cancel(autoTeleportTask)
                autoTeleportTask = nil
            end
            Rayfield:Notify({
                Title = "Auto Teleport",
                Content = "Auto teleport dihentikan!",
                Duration = 3,
            })
        end
    end,
})
TeleTab:CreateSection("Atur Delay Auto Teleport")
-- Slider untuk atur delay auto teleport
TeleTab:CreateSlider({
    Name = "⏳ Delay Auto Teleport (detik)",
    Range = {0, 20},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = AutoTeleportDelay,
    Flag = "ATDelay",
    Callback = function(Value)
        AutoTeleportDelay = Value
    end,
})


else
    -- Kalau HWID tidak terdaftar
    HWIDTab:CreateParagraph({
        Title = "⚠️ HWID Tidak Terdaftar",
        Content = "HWID kamu belum terdaftar.\n\n" .. hwid
    })

    HWIDTab:CreateButton({
        Name = "Salin HWID",
        Callback = function()
            setclipboard(hwid)
            Rayfield:Notify({
                Title = "Disalin",
                Content = "HWID kamu sudah disalin. Kirim ke owner untuk didaftarkan.",
                Duration = 6
            })
        end,
    })
end
