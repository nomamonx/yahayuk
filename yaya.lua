-- FULL Admin & Summit Detector (siap-tempel dan jalan langsung)
-- By: ChatGPT (modifikasi lengkap untuk kebutuhanmu)
-- WARNING: webhook digabung permanen di bawah (ganti jika mau)

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Config (hard-coded webhook PERMANEN di sini) =====
local Config = {
    AutoHop = true,            -- Auto hop ke server lain saat admin terdeteksi
    AutoLeave = false,         -- Auto kick (jika ingin kick instead of hop)
    SendWebhook = true,        -- Kirim semua notif ke Discord
    ScanInterval = 2.5,        -- interval scan admin (detik)
    SummitDetectMethod = "leaderstat", -- "leaderstat" or "position"
    SummitPositionY = 1000,    -- jika pakai position, threshold Y untuk anggap "summit"
    SummitPositionHold = 1.2,  -- harus bertahan di atas threshold (detik)
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/rjde-YwMH6pOi9Dk7LzQhlbCg1RGhYvouHgwrz_dYJi8amlIQLImuHnRXlLot-1mFfUU", -- <--- GANTI bila perlu
}

-- Blacklist (sesuai permintaan)
local BlacklistNames = {
    "YAHAVUKazigen","Dim","eugyne","VBZ","HeruAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

-- Rank keywords (untuk cek GUI text uppercase)
local RankKeywords = {"ADMIN","OWNER","DEV","DEVELOPER","MOD","STAFF","GM","PENGAWAS","ADMIN 1","ADMIN 2","ADMIN 3"}

-- ===== Helpers: safe send webhook =====
local function SendWebhook(content)
    if not Config.SendWebhook then return false, "disabled" end
    local url = Config.WebhookURL
    if not url or url == "" then return false, "no webhook" end

    local body = HttpService:JSONEncode({ content = content })

    -- try several methods
    local ok, err
    if syn and syn.request then
        ok, err = pcall(function() syn.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif http_request then
        ok, err = pcall(function() http_request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif request then
        ok, err = pcall(function() request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    elseif http and http.request then
        ok, err = pcall(function() http.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    else
        -- fallback to game:HttpPost (may fail in some env)
        ok, err = pcall(function() game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson) end)
    end

    if not ok then
        warn("SendWebhook failed:", err)
        return false, tostring(err)
    end
    return true
end

local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02dm:%02ds", m, s)
end

-- ===== Rayfield window (create new window) =====
local ok, Rayfield = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
if not ok or not Rayfield then
    warn("Rayfield gagal dimuat. Pastikan URL accesible di envmu.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detektor",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Siap jalan"
})
local DetTab = Window:CreateTab("Detektor")

-- UI helpers (Rayfield API)
local function CreateLabel(text)
    if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(text) end
    return { Set = function() end }
end
local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end end
local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end end
local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end end
local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield:Notify({ Title = title, Content = content, Duration = 5 }) else warn(title, content) end end

-- ===== UI: create controls & labels =====
local AdminLabel = CreateLabel("Admin Terdeteksi: -")
local SummitLabel = CreateLabel("Summit: 0 | Last: 00m:00s")
local StatusLabel = CreateLabel("Status: Idle")

-- toggles & inputs
local toggleAutoHop = CreateToggle({ Name = "🌍 Auto Hop jika Admin", CurrentValue = Config.AutoHop, Callback = function(v) Config.AutoHop = v end })
local toggleAutoLeave = CreateToggle({ Name = "🚪 Auto Leave (Kick) jika Admin", CurrentValue = Config.AutoLeave, Callback = function(v) Config.AutoLeave = v end })
local toggleSendWebhook = CreateToggle({ Name = "📲 Kirim Notif ke Discord (Webhook)", CurrentValue = Config.SendWebhook, Callback = function(v) Config.SendWebhook = v end })
local inputWebhook = CreateTextBox({ Name = "Webhook URL (permanen di script, bisa ubah)", PlaceholderText = Config.WebhookURL, Text = Config.WebhookURL or "", Callback = function(txt) Config.WebhookURL = txt or Config.WebhookURL end })
local inputScanInterval = CreateTextBox({ Name = "Scan Interval (detik)", PlaceholderText = tostring(Config.ScanInterval), Text = tostring(Config.ScanInterval), Callback = function(txt) local n = tonumber(txt) if n and n >= 0.5 then Config.ScanInterval = n end end })
local comboSummitMethodLabel = CreateLabel("Summit detect method: " .. tostring(Config.SummitDetectMethod))
local btnTestWebhook = CreateButton({ Name = "📡 Test Webhook", Callback = function() local ok,err = SendWebhook("✅ Test webhook dari Detektor | Player: " .. (LocalPlayer and LocalPlayer.Name or "Unknown")) if ok then Notify("Webhook", "Test terkirim") else Notify("Webhook Gagal", tostring(err)) end end })
local btnReset = CreateButton({ Name = "🔄 Reset ke default (reload script)", Callback = function() Notify("Reset", "Reload manual diperlukan. Restart executor.") end })

-- ===== Detection utilities =====
local function lower(s) return (type(s) == "string" and string.lower(s) or "") end

local function isBlacklisted(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,b in ipairs(BlacklistNames) do
        if uname == lower(b) or dname == lower(b) or string.find(uname, lower(b), 1, true) or string.find(dname, lower(b), 1, true) then
            return true, "BlacklistName:" .. tostring(b)
        end
    end
    return false, nil
end

-- check name/display keywords (case-insensitive)
local function hasRankKeywordInName(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,kw in ipairs(RankKeywords) do
        local lk = lower(kw)
        if string.find(uname, lk, 1, true) or string.find(dname, lk, 1, true) then
            return true, "NameContains:"..kw
        end
    end
    return false, nil
end

-- check GUI text above head: only consider strings that are ALL CAPS / digits / spaces (like "ADMIN 1")
local function guiAdminDetect(player)
    if not player.Character then return false, nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false, nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
                    -- consider only uppercase+digits+spaces (and small chance punctuation)
                    if text:match("^[A-Z0-9%s%p]+$") then
                        for _,kw in ipairs(RankKeywords) do
                            if text:find(kw) then
                                return true, "GuiText:"..text
                            end
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

-- combine all detection methods for admin
local handlingAdmin = false
local lastAdminDetectTime = 0
local adminCooldown = 6

local function serverHopAttempt()
    -- try find other server similar to earlier implementations
    local maxPages = 6
    local pageCursor = nil
    local found = nil
    for page=1,maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then break end
        local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or not json or type(json.data) ~= "table" then break end
        for _,srv in ipairs(json.data) do
            if type(srv) == "table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id) ~= tostring(JobId) and srv.playing < srv.maxPlayers then
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
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, found, LocalPlayer) end)
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

    -- update UI
    pcall(function() AdminLabel:Set("Admin Terdeteksi: " .. tostring(player and player.Name or "Unknown") .. " (" .. tostring(reason) .. ")") end)
    pcall(function() StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(player and player.Name or "Unknown")) end)

    -- send webhook
    pcall(function() SendWebhook(message) end)

    -- in-game notify
    Notify("⚠️ Admin Terdeteksi", tostring(player and player.Name or "Unknown") .. " (" .. tostring(reason) .. ")")

    -- action: hop or leave
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

    task.delay(8, function() handlingAdmin = false end)
end

-- single-player check wrapper
local function CheckPlayerForAdmin(player)
    if not player then return false end
    local ok, reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then
        handleAdminDetected(player, reason)
        return true
    end
    local ok2, reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then
        handleAdminDetected(player, reason2)
        return true
    end
    local ok3, reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then
        handleAdminDetected(player, reason3)
        return true
    end
    return false
end

-- ===== Summit tracking (self) =====
local mySummitCount = 0
local myLastRespawn = tick()
local myLastSummitTime = 0

-- reset respawn time on CharacterAdded
if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function()
        myLastRespawn = tick()
        pcall(function() SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime)) end)
    end)
end

-- function to call when summit reached
local function OnSummitReached()
    local now = tick()
    local timeTaken = math.floor(now - myLastRespawn)
    myLastSummitTime = timeTaken
    mySummitCount = mySummitCount + 1
    pcall(function() SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime)) end)

    local msg = ("✅ Summit Reached!\nPlayer: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        mySummitCount,
        myLastSummitTime,
        FormatTimeSec(myLastSummitTime),
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )
    pcall(function() SendWebhook(msg) end)
    Notify("🏔️ Summit", "Summit tercapai! Waktu: " .. tostring(FormatTimeSec(myLastSummitTime)))
    -- reset respawn start time for next round
    myLastRespawn = tick()
end

-- automatic summit detection strategies:
-- 1) monitor leaderstats.Summit (value increases) if exists
-- 2) fallback: position Y threshold (must stay above for some hold time)
local leaderstatWatching = false

local function TryStartLeaderstatWatcher()
    if leaderstatWatching then return end
    leaderstatWatching = true
    local function watch()
        while true do
            if not LocalPlayer or not LocalPlayer.Parent then break end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Summit") and typeof(ls.Summit.Value) == "number" then
                local lastVal = ls.Summit.Value
                ls.Summit.Changed:Connect(function(newVal)
                    pcall(function()
                        if type(newVal) == "number" and newVal > lastVal then
                            lastVal = newVal
                            OnSummitReached()
                        else
                            lastVal = newVal
                        end
                    end)
                end)
                break
            end
            task.wait(1)
        end
    end
    task.spawn(watch)
end

-- position-based detection fallback
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
                        task.wait(3) -- small cooldown after detection
                    end
                else
                    positionHoldTimer = 0
                end
            end
            task.wait(0.5)
        end
    end)
end

-- start chosen summit detection method(s)
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcher()
    -- also start position fallback (optional)
    TryStartPositionWatcher()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcher()
else
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
end

-- ===== Main scanner loop =====
task.spawn(function()
    while true do
        local players = Players:GetPlayers()
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdmin(pl) end)
            end
        end
        -- update UI labels periodically
        pcall(function()
            StatusLabel:Set("Status: Running | Players: " .. tostring(#players))
        end)
        task.wait(Config.ScanInterval or 2.5)
    end
end)

-- initial UI update
pcall(function()
    AdminLabel:Set("Admin Terdeteksi: -")
    SummitLabel:Set("Summit: "..mySummitCount.." | Last: " .. FormatTimeSec(myLastSummitTime))
    StatusLabel:Set("Status: Idle")
end)

Notify("Detektor Aktif", "Admin & Summit Detector berjalan. Webhook permanen disimpan di script.")
