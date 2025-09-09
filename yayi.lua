-- FULL Admin & Summit Detector (siap-tempel dan jalan langsung)
-- By: ChatGPT (modifikasi lengkap untuk kebutuhanmu)
-- ============================
-- Part 1 / 3: Setup & Helpers
-- ============================

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
    AutoHop = true,
    AutoLeave = false,
    SendWebhook = true,
    ScanInterval = 2.5,
    SummitDetectMethod = "leaderstat", -- "leaderstat" or "position"
    SummitPositionY = 1000,
    SummitPositionHold = 1.2,
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/rjde-YwMH6pOi9Dk7LzQhlbCg1RGhYvouHgwrz_dYJi8amlIQLImuHnRXlLot-1mFfUU", -- permanen di script
}

-- ===== Blacklist =====
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

-- ===== Rank Keywords =====
local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- ===== Helpers =====
local function SendWebhook(content)
    if not Config.SendWebhook then return false, "disabled" end
    local url = Config.WebhookURL
    if not url or url == "" then return false, "no webhook" end

    local body = HttpService:JSONEncode({ content = content })
    local ok, err
    if syn and syn.request then
        ok, err = pcall(function() syn.request({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        }) end)
    elseif http_request then
        ok, err = pcall(function() http_request({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        }) end)
    elseif request then
        ok, err = pcall(function() request({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        }) end)
    elseif http and http.request then
        ok, err = pcall(function() http.request({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        }) end)
    else
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

-- ============================
-- Part 2 / 3: UI & Detection
-- ============================

-- Load Rayfield dengan aman
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("Rayfield gagal dimuat:", result)
    return
end

local Rayfield = result

-- Buat Window utama
local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detektor",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Siap jalan",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DetektorSummit",
        FileName = "Config"
    },
})
-- ===== HWID Check =====
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local success, AllowedHWIDs = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nomamonx/gunung/refs/heads/main/hwid1.lua"))()
end)
if not success or type(AllowedHWIDs) ~= "table" then
    AllowedHWIDs = {}
end
local isVIP = AllowedHWIDs[hwid] == true

local HWIDTab = Window:CreateTab("HWID", 4483362458)
if isVIP then
    HWIDTab:CreateParagraph({
        Title = "✅ HWID Terdaftar",
        Content = "HWID kamu sudah terdaftar.\n\n"..hwid
    })
    HWIDTab:CreateButton({
        Name = "Reset HWID",
        Callback = function()
            setclipboard(hwid)
            Rayfield:Notify({
                Title = "Reset HWID",
                Content = "HWID disalin. Hubungi owner untuk reset di database.",
                Duration = 6
            })
        end,
    })
else
    HWIDTab:CreateParagraph({
        Title = "❌ HWID Tidak Terdaftar",
        Content = "HWID kamu tidak terdaftar.\n\n"..hwid
    })
end

-- ===== Detection Utilities =====
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

local function guiAdminDetect(player)
    if not player.Character then return false, nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false, nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text = tostring(desc.Text or "")
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

-- ===== UI Setup =====
local DetTab = Window:CreateTab("Detektor")
local function CreateLabel(text)
    if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(text) end
    return { Set = function() end }
end
local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end end
local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end end
local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end end
local function Notify(title, content) if Rayfield and Rayfield.Notify then Rayfield:Notify({ Title = title, Content = content, Duration = 5 }) else warn(title, content) end end

-- Labels
local AdminLabel = CreateLabel("Admin Terdeteksi: -")
local SummitLabel = CreateLabel("Summit: 0 | Last: 00m:00s")
local StatusLabel = CreateLabel("Status: Idle")

-- Toggles & Inputs
local toggleAutoHop = CreateToggle({ Name = "🌍 Auto Hop jika Admin", CurrentValue = Config.AutoHop, Callback = function(v) Config.AutoHop = v end })
local toggleAutoLeave = CreateToggle({ Name = "🚪 Auto Leave (Kick) jika Admin", CurrentValue = Config.AutoLeave, Callback = function(v) Config.AutoLeave = v end })
local toggleSendWebhook = CreateToggle({ Name = "📲 Kirim Notif ke Discord (Webhook)", CurrentValue = Config.SendWebhook, Callback = function(v) Config.SendWebhook = v end })
local inputWebhook = CreateTextBox({ Name = "Webhook URL", PlaceholderText = Config.WebhookURL, Text = Config.WebhookURL or "", Callback = function(txt) Config.WebhookURL = txt or Config.WebhookURL end })
local inputScanInterval = CreateTextBox({ Name = "Scan Interval (detik)", PlaceholderText = tostring(Config.ScanInterval), Text = tostring(Config.ScanInterval), Callback = function(txt) local n = tonumber(txt) if n and n >= 0.5 then Config.ScanInterval = n end end })
local comboSummitMethodLabel = CreateLabel("Summit detect method: " .. tostring(Config.SummitDetectMethod))
local btnTestWebhook = CreateButton({ Name = "📡 Test Webhook", Callback = function() local ok,err = SendWebhook("✅ Test webhook dari Detektor | Player: " .. (LocalPlayer and LocalPlayer.Name or "Unknown")) if ok then Notify("Webhook", "Test terkirim") else Notify("Webhook Gagal", tostring(err)) end end })
local btnReset = CreateButton({ Name = "🔄 Reset ke default (reload script)", Callback = function() Notify("Reset", "Reload manual diperlukan. Restart executor.") end })
-- ============================
-- Part 2 / 3: Detection, Actions & Summit Tracking
-- (gabungkan dengan Part 1 di atas; pastikan Part 1 sudah ditempel)
-- ============================

-- ======= Extra helpers & state =======
local _VERSION = "Detektor v1.0.0-CHATGPT-MOD"
local StartTick = tick()
local LogHistory = {}
local function Log(...) -- menyimpan log internal
    local args = {...}
    local line = ""
    for i=1,#args do
        line = line .. tostring(args[i])
        if i < #args then line = line .. "\t" end
    end
    table.insert(LogHistory, {time = os.date("%Y-%m-%d %H:%M:%S"), text = line})
    -- pembatas history
    if #LogHistory > 400 then
        for i=1,200 do table.remove(LogHistory, 1) end
    end
    -- juga print ke output
    pcall(function() print("[Detektor] "..os.date("%H:%M:%S").." - "..line) end)
end

-- safe pcall wrapper
local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        Log("safeCall error:", res)
        return nil, res
    end
    return res
end

-- small utility: copy text to clipboard if available
local function CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
            Notify("Clipboard", "Teks disalin ke clipboard.")
        elseif toclipboard then
            toclipboard(text)
            Notify("Clipboard", "Teks disalin ke clipboard.")
        else
            Notify("Clipboard", "Fungsi clipboard tidak tersedia di executor-mu.")
        end
    end)
end

-- ====== Additional Config features (dapat diubah lewat UI) ======
Config.IgnoreFriends = true            -- ignore players who are your friends
Config.IgnoreGroupAdmins = false       -- check group roles? (implem partial)
Config.WebhookUseEmbed = true         -- gunakan embed payload jika diinginkan
Config.VerboseLogging = true          -- simpan detail event ke log
Config.DetectionCooldown = 6          -- cooldown antar detection (detik)
Config.NotifyInGame = true            -- pakai Rayfield Notify

-- ====== Runtime State ======
local handlingAdmin = false
local lastAdminDetect = 0
local summonStats = {
    count = mySummitCount or 0,
    lastTime = myLastSummitTime or 0,
    lastRespawn = myLastRespawn or tick(),
}
local playerCache = {} -- cache nama->info
local bannedServersCache = {} -- server ids yang sudah dicoba hop

-- ====== Utility: build webhook payload (rich) ======
local function BuildWebhookPayload(title, description, extra)
    extra = extra or {}
    if Config.WebhookUseEmbed then
        local embed = {
            title = title,
            description = description,
            color = extra.color or 16753920,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            fields = extra.fields or {},
            footer = { text = _VERSION }
        }
        local payload = { embeds = { embed } }
        return HttpService:JSONEncode(payload)
    else
        -- plain content
        return HttpService:JSONEncode({ content = ("**%s**\n%s"):format(title, description) })
    end
end

-- override SendWebhook to support embed payloads
local function SendWebhook2(title, description, extra)
    if not Config.SendWebhook then
        Log("SendWebhook2: disabled")
        return false, "disabled"
    end
    local url = Config.WebhookURL
    if not url or url == "" then
        Log("SendWebhook2: no webhook")
        return false, "no webhook"
    end

    local body = BuildWebhookPayload(title, description, extra)

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
        ok, err = pcall(function() game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson) end)
    end

    if not ok then
        Log("SendWebhook2 failed:", err)
        return false, tostring(err)
    end
    Log("SendWebhook2 success:", title)
    return true
end

-- ====== Detect friend check (if available) ======
local function IsFriend(player)
    if not Config.IgnoreFriends then return false end
    local ok, res = pcall(function() return player and player:IsFriendsWith(LocalPlayer.UserId) end)
    if ok and res then return true end
    return false
end

-- ====== Enhanced admin handling ======
local function performEscapeAction(playerName, reason)
    -- This function chooses between hop or leave and tries to record attempt
    if Config.AutoHop then
        -- attempt server hop, but avoid repeating same server if failed recently
        local success = false
        pcall(function()
            success = serverHopAttempt()
        end)
        if success then
            Log("AutoHop: teleport attempted for", playerName)
            SendWebhook2("Admin Detected - Hop", ("Detected **%s** (%s). Attempting server hop."):format(playerName, reason), { color = 16766720, fields = { { name = "Player", value = tostring(playerName), inline = true } } })
            return true
        else
            Log("AutoHop failed, fallback to AutoLeave:", tostring(Config.AutoLeave))
            if Config.AutoLeave then
                pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end)
            end
        end
    elseif Config.AutoLeave then
        pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end)
    end
    return false
end

local function handleAdminDetectedEnhanced(player, reason)
    if handlingAdmin then return end
    local now = tick()
    if now - lastAdminDetect < Config.DetectionCooldown then
        Log("handleAdminDetectedEnhanced: on cooldown")
        return
    end
    handlingAdmin = true
    lastAdminDetect = now

    local pname = (player and player.Name) or "Unknown"
    local pdisplay = (player and player.DisplayName) or pname
    local status = (player and player:IsDescendantOf(game)) and "Online" or "Offline"
    local msg = ("⚠️ Admin Detected: **%s** (%s)\nReason: %s\nStatus: %s\nPlaceId: %d\nTime: %s"):format(
        tostring(pname),
        tostring(pdisplay),
        tostring(reason or "-"),
        status,
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )

    -- update UI
    pcall(function() AdminLabel:Set("Admin Terdeteksi: " .. tostring(pname) .. " (" .. tostring(reason) .. ")") end)
    pcall(function() StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(pname)) end)

    -- log
    Log("Detected admin:", pname, reason)

    -- send webhook enhanced
    pcall(function()
        SendWebhook2("⚠️ Admin Detected", msg, {
            color = 15158332,
            fields = {
                { name = "Player", value = pname, inline = true },
                { name = "Display", value = pdisplay, inline = true },
                { name = "Reason", value = tostring(reason), inline = false },
                { name = "ServerId", value = tostring(JobId), inline = true },
                { name = "PlaceId", value = tostring(PlaceId), inline = true },
            }
        })
    end)

    -- in-game notify
    if Config.NotifyInGame then
        Notify("⚠️ Admin Terdeteksi", tostring(pname) .. " (" .. tostring(reason) .. ")")
    end

    -- copy name to clipboard quick action
    pcall(function() CopyToClipboard(pname) end)

    -- attempt escape action
    task.spawn(function()
        task.wait(0.6)
        performEscapeAction(pname, reason)
    end)

    task.delay(8, function() handlingAdmin = false end)
end

-- ====== Single player detection wrapper with enhancements ======
local function CheckPlayerForAdminEnhanced(player)
    if not player then return false end
    if player == LocalPlayer then return false end

    -- respect ignore friends
    if Config.IgnoreFriends and IsFriend(player) then
        if Config.VerboseLogging then Log("Ignored friend:", player.Name) end
        return false
    end

    local ok, reason = pcall(function() return isBlacklisted(player) end)
    if ok and reason then
        handleAdminDetectedEnhanced(player, reason)
        return true
    end

    local ok2, reason2 = pcall(function() return hasRankKeywordInName(player) end)
    if ok2 and reason2 then
        handleAdminDetectedEnhanced(player, reason2)
        return true
    end

    local ok3, reason3 = pcall(function() return guiAdminDetect(player) end)
    if ok3 and reason3 then
        handleAdminDetectedEnhanced(player, reason3)
        return true
    end

    -- additional checks: unusual humanoid properties /tools
    pcall(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            -- unusual walkspeed or jumppower might be flagged (optional)
            local ws = hum.WalkSpeed or 16
            local jp = hum.JumpPower or hum.JumpHeight or 0
            if ws > 40 or jp > 200 then
                handleAdminDetectedEnhanced(player, ("UnusualMovement(ws=%s,jp=%s)"):format(ws, jp))
            end
        end
    end)

    return false
end

-- ====== Summit detection enhancements (stats, persistence, webhook) ======
local summitCooldown = 3
local function OnSummitReachedEnhanced()
    local now = tick()
    local timeTaken = math.floor(now - summitStats.lastRespawn)
    summitStats.lastTime = timeTaken
    summitStats.count = summitStats.count + 1
    summitStats.lastRespawn = now

    -- UI update
    pcall(function() SummitLabel:Set("Summit: "..summitStats.count.." | Last: " .. FormatTimeSec(summitStats.lastTime)) end)

    -- build message
    local desc = ("Player: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        summitStats.count,
        summitStats.lastTime,
        FormatTimeSec(summitStats.lastTime),
        PlaceId,
        os.date("%Y-%m-%d %H:%M:%S")
    )

    -- send webhook
    pcall(function() SendWebhook2("✅ Summit Reached", desc, { color = 3066993 }) end)

    -- small in-game notify
    if Config.NotifyInGame then
        Notify("🏔️ Summit", "Summit tercapai! Waktu: " .. tostring(FormatTimeSec(summitStats.lastTime)))
    end

    Log("Summit reached:", summitStats.count, "time:", summitStats.lastTime)
end

-- TryStartLeaderstatWatcher (enhanced with reconnection)
local leaderstatWatching = false
local function TryStartLeaderstatWatcherEnhanced()
    if leaderstatWatching then return end
    leaderstatWatching = true
    task.spawn(function()
        while true do
            if not LocalPlayer or not LocalPlayer.Parent then break end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Summit") then
                local lastVal = ls.Summit.Value
                ls.Summit.Changed:Connect(function(newVal)
                    pcall(function()
                        if type(newVal) == "number" and newVal > lastVal then
                            lastVal = newVal
                            OnSummitReachedEnhanced()
                        else
                            lastVal = newVal
                        end
                    end)
                end)
                Log("Leaderstat watcher hooked.")
                break
            end
            task.wait(1)
        end
    end)
end

-- position-based detection fallback (enhanced)
local positionHoldTimer = 0
local function TryStartPositionWatcherEnhanced()
    task.spawn(function()
        while true do
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                if hrp.Position.Y >= (Config.SummitPositionY or 1000) then
                    positionHoldTimer = positionHoldTimer + 0.5
                    if positionHoldTimer >= (Config.SummitPositionHold or 1.2) then
                        OnSummitReachedEnhanced()
                        positionHoldTimer = 0
                        task.wait(summitCooldown)
                    end
                else
                    positionHoldTimer = 0
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ====== Server hop attempt with backoff + log ======
local function serverHopAttemptEnhanced()
    local maxPages = 8
    local pageCursor = nil
    local found = nil
    local tried = 0
    for page=1,maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then
            Log("serverHopAttemptEnhanced: HttpGet failed at page", page)
            break
        end
        local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(json) ~= "table" then
            Log("serverHopAttemptEnhanced: JSON decode failed")
            break
        end
        for _,srv in ipairs(json.data or {}) do
            tried = tried + 1
            if type(srv) == "table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id) ~= tostring(JobId) and srv.playing < srv.maxPlayers and (not bannedServersCache[srv.id]) then
                    found = srv.id
                    break
                end
            end
        end
        if found then break end
        pageCursor = json.nextPageCursor
        if not pageCursor then break end
        task.wait(0.08)
    end
    if found then
        Log("Found server to hop:", found)
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, found, LocalPlayer) end)
        return true
    end
    Log("No suitable server found after", tried, "checks.")
    return false
end

-- alias serverHopAttempt to enhanced
serverHopAttempt = serverHopAttemptEnhanced
serverHopAttempt_legacy = serverHopAttemptEnhanced

-- ====== Main scanner loop (enhanced with events) ======
local function StartMainScanner()
    -- hook playeradded for faster detection
    Players.PlayerAdded:Connect(function(pl)
        task.spawn(function()
            task.wait(0.4)
            pcall(function() CheckPlayerForAdminEnhanced(pl) end)
        end)
    end)
    -- initial scan + loop
    task.spawn(function()
        while true do
            local players = Players:GetPlayers()
            for _,pl in ipairs(players) do
                if pl ~= LocalPlayer then
                    pcall(function() CheckPlayerForAdminEnhanced(pl) end)
                end
            end
            pcall(function() StatusLabel:Set("Status: Running | Players: " .. tostring(#players)) end)
            task.wait(Config.ScanInterval or 2.5)
        end
    end)
end

-- ====== UI: Additional controls (Log viewer, actions) ======
-- Create more UI controls to make script long and useful
local btnShowLog = CreateButton({ Name = "📜 Show Recent Log", Callback = function()
    local text = ""
    for i = math.max(1, #LogHistory - 40), #LogHistory do
        local e = LogHistory[i]
        if e then text = text .. "["..e.time.."] "..e.text.."\n" end
    end
    -- copy logs to clipboard and notify
    CopyToClipboard(text)
    Notify("Log disalin", "Recent log disalin ke clipboard.")
end })

local btnToggleVIP = CreateButton({ Name = "🔒 Toggle HWID VIP Display", Callback = function()
    if isVIP then
        Notify("HWID", "Kamu terdaftar sebagai VIP.")
    else
        Notify("HWID", "Kamu TIDAK terdaftar.")
    end
end })

local btnManualScan = CreateButton({ Name = "🔎 Manual Scan Sekarang", Callback = function()
    task.spawn(function()
        local players = Players:GetPlayers()
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdminEnhanced(pl) end)
            end
        end
        Notify("Manual Scan", "Selesai memindai pemain.")
    end)
end })

local toggleIgnoreFriends = CreateToggle({ Name = "👥 Ignore Friends", CurrentValue = Config.IgnoreFriends, Callback = function(v) Config.IgnoreFriends = v end })
local toggleUseEmbed = CreateToggle({ Name = "🧾 Use Webhook Embed", CurrentValue = Config.WebhookUseEmbed, Callback = function(v) Config.WebhookUseEmbed = v end })
local toggleVerbose = CreateToggle({ Name = "📈 Verbose Logging", CurrentValue = Config.VerboseLogging, Callback = function(v) Config.VerboseLogging = v end })

-- ====== Start watchers based on config ======
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcherEnhanced()
else
    TryStartLeaderstatWatcherEnhanced()
    TryStartPositionWatcherEnhanced()
end

-- start main scanner
StartMainScanner()

-- ====== Small auto-notify on ready ======
Notify("Detektor Aktif", "Admin & Summit Detector berjalan. Periksa tab HWID bila perlu.")
Log("Detektor initialized. Version:", _VERSION, "StartTick:", StartTick)

-- End of Part 2/3


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
