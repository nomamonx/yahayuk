-- FULL Admin & Summit Detector (siap-tempel dan jalan langsung)
-- By: ChatGPT (modifikasi lengkap untuk kebutuhanmu)
-- WARNING: webhook digabung permanen di bawah (ganti jika mau)
-- =====================================================================
-- Mega Script: Admin & Summit Detector (Single Window, Multi-Tab)
-- Features:
--  - HWID check tab
--  - Admin detection (blacklist, name-keywords, GUI text, movement anomalies)
--  - Summit tracking (leaderstat + position fallback)
--  - Webhook support (embed/plain) with safe send using multiple request hooks
--  - AutoHop with server search/backoff and banned-server cache
--  - UI: many toggles/buttons, log viewer, copy-to-clipboard, test webhook
--  - Verbose logging & internal history
--  - Single Rayfield window (no duplicate windows)
-- =====================================================================

-- ============================
-- Part 0: Services & Globals
-- ============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RbxAnalytics = game:GetService("RbxAnalyticsService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- safety: ensure LocalPlayer available in local script environment
if not LocalPlayer then
    warn("[Detektor] LocalPlayer not found. Script must run in a LocalScript / executor that exposes LocalPlayer.")
end

-- ============================
-- Part 1: Configuration
-- ============================
local Config = {
    AutoHop = true,            -- Auto hop ke server lain saat admin terdeteksi
    AutoLeave = false,         -- Auto kick (jika ingin kick instead of hop)
    SendWebhook = true,        -- Kirim semua notif ke Discord
    ScanInterval = 2.5,        -- interval scan admin (detik)
    SummitDetectMethod = "leaderstat", -- "leaderstat" or "position"
    SummitPositionY = 1000,    -- jika pakai position, threshold Y untuk anggap "summit"
    SummitPositionHold = 1.2,  -- harus bertahan di atas threshold (detik)
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/rjde-YwMH6pOi9Dk7LzQhlbCg1RGhYvouHgwrz_dYJi8amlIQLImuHnRXlLot-1mFfUU", -- <--- GANTI bila perlu
    WebhookUseEmbed = true,    -- apakah gunakan embed payload (discord)
    DetectionCooldown = 6,     -- cooldown antara detection events
    IgnoreFriends = true,      -- ignore friends
    IgnoreGroupAdmins = false, -- placeholder (partial impl)
    VerboseLogging = true,     -- simpan detail event ke log
    ConfigurationSaving = true, -- Rayfield config saving
}

-- Customizable lists
local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}

local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- ============================
-- Part 2: Utilities & Helpers
-- ============================
local function lower(s) return (type(s) == "string" and string.lower(s) or "") end
local function nowStr() return os.date("%Y-%m-%d %H:%M:%S") end

local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02dm:%02ds", m, s)
end

-- safe HTTP send wrapper tries many request methods
local function httpPostJSON(url, body)
    local ok, err
    if syn and syn.request then
        ok, err = pcall(function() syn.request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body}) end)
        if ok then return true end
    end
    if http_request then
        ok, err = pcall(function() http_request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body}) end)
        if ok then return true end
    end
    if request then
        ok, err = pcall(function() request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body}) end)
        if ok then return true end
    end
    if http and http.request then
        ok, err = pcall(function() http.request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body}) end)
        if ok then return true end
    end
    -- fallback
    ok, err = pcall(function() game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson) end)
    if ok then return true end
    return false, tostring(err)
end

-- ============================
-- Part 3: Logging
-- ============================
local LogHistory = {}
local function Log(...)
    local args = {...}
    local str = ""
    for i = 1, #args do
        str = str .. tostring(args[i])
        if i < #args then str = str .. " " end
    end
    table.insert(LogHistory, { time = nowStr(), text = str })
    if #LogHistory > 800 then
        -- keep size manageable
        for i=1,200 do table.remove(LogHistory, 1) end
    end
    if Config.VerboseLogging then
        pcall(function() print("[Detektor] "..nowStr().." - "..str) end)
    end
end

local function CopyToClipboard(txt)
    pcall(function()
        if setclipboard then
            setclipboard(txt)
        elseif toclipboard then
            toclipboard(txt)
        else
            -- no clipboard available
        end
    end)
end

-- ============================
-- Part 4: Webhook Builds
-- ============================
local ScriptVersion = "Detektor v1.0.0-CHATGPT-MOD"

local function BuildWebhookPayload(title, description, extra)
    extra = extra or {}
    if Config.WebhookUseEmbed then
        local embed = {
            title = title,
            description = description,
            color = extra.color or 16753920,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            fields = extra.fields or {},
            footer = { text = ScriptVersion }
        }
        return HttpService:JSONEncode({embeds = {embed}})
    else
        local content = ("**%s**\n%s"):format(title, description)
        return HttpService:JSONEncode({content = content})
    end
end

local function SendWebhook(title_or_content, maybe_desc, extra)
    -- This is flexible: if only one arg, send as plain content
    if not Config.SendWebhook then
        Log("SendWebhook: disabled")
        return false, "disabled"
    end
    if not Config.WebhookURL or Config.WebhookURL == "" then
        Log("SendWebhook: no webhook url")
        return false, "no webhook"
    end

    local ok, res
    local payload
    if not maybe_desc then
        -- single string -> send as content
        payload = HttpService:JSONEncode({ content = tostring(title_or_content) })
    else
        payload = BuildWebhookPayload(title_or_content, maybe_desc, extra)
    end

    ok, res = httpPostJSON(Config.WebhookURL, payload)
    if not ok then
        Log("SendWebhook failed:", res)
        return false, res
    end
    Log("SendWebhook success")
    return true
end

-- ============================
-- Part 5: Admin Detection Methods
-- ============================
local function isBlacklisted(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,b in ipairs(BlacklistNames) do
        local lb = lower(b)
        if uname == lb or dname == lb or string.find(uname, lb, 1, true) or string.find(dname, lb, 1, true) then
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
            return true, "NameContains:" .. kw
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
                    -- quick uppercase check (common admin tags)
                    if text:match("^[A-Z0-9%s%p]+$") then
                        for _,kw in ipairs(RankKeywords) do
                            if text:find(kw) then
                                return true, "GuiText:" .. text
                            end
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

-- additional movement/tools heuristics
local function movementAnomalyDetect(player)
    if not player.Character then return false, nil end
    local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false, nil end
    local ws = hum.WalkSpeed or 16
    local jp = hum.JumpPower or hum.JumpHeight or 0
    if ws > 40 or jp > 200 then
        return true, ("UnusualMovement(ws=%s,jp=%s)"):format(tostring(ws), tostring(jp))
    end
    -- check tools that look like admin tools
    if player.Character:FindFirstChildOfClass("Tool") then
        for _,t in ipairs(player.Character:GetChildren()) do
            if t:IsA("Tool") then
                local tn = lower(t.Name or "")
                if string.find(tn, "admin", 1, true) or string.find(tn, "mod", 1, true) or string.find(tn, "kill", 1, true) then
                    return true, "ToolSuspect:" .. tostring(t.Name)
                end
            end
        end
    end
    return false, nil
end

-- ============================
-- Part 6: Server Hop Implementation
-- ============================
local bannedServersCache = {}
local function serverHopAttempt()
    local maxPages = 8
    local pageCursor = nil
    local found = nil
    for page=1, maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url = url .. "&cursor=" .. pageCursor end
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then
            Log("serverHopAttempt: HttpGet failed (page)", page)
            break
        end
        local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(json) ~= "table" then
            Log("serverHopAttempt: JSONDecode failed (page)", page)
            break
        end
        for _,srv in ipairs(json.data or {}) do
            if type(srv) == "table" and srv.id and srv.playing and srv.maxPlayers then
                local sid = tostring(srv.id)
                if sid ~= tostring(JobId) and srv.playing < srv.maxPlayers and (not bannedServersCache[sid]) then
                    found = sid
                    break
                end
            end
        end
        if found then break end
        pageCursor = json.nextPageCursor
        if not pageCursor then break end
        task.wait(0.05)
    end
    if found then
        Log("serverHopAttempt: teleporting to", found)
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, found, LocalPlayer) end)
        return true
    end
    Log("serverHopAttempt: no server found")
    return false
end

-- ============================
-- Part 7: Handle Admin Detection Action
-- ============================
local handlingAdmin = false
local lastAdminDetect = 0

local function performEscapeAction(playerName, reason)
    if Config.AutoHop then
        local ok = pcall(function() return serverHopAttempt() end)
        if ok then
            SendWebhook("⚠️ AutoHop", ("Detected %s (%s). Attempting auto hop..."):format(playerName, reason))
            return true
        else
            Log("performEscapeAction: serverHopAttempt pcall failed")
            if Config.AutoLeave then
                pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end)
            end
        end
    elseif Config.AutoLeave then
        pcall(function() LocalPlayer:Kick("Admin terdeteksi: " .. tostring(playerName)) end)
    end
    return false
end

local function handleAdminDetected(player, reason)
    local now = tick()
    if handlingAdmin then
        Log("handleAdminDetected: already handling")
        return
    end
    if now - lastAdminDetect < Config.DetectionCooldown then
        Log("handleAdminDetected: on cooldown")
        return
    end
    handlingAdmin = true
    lastAdminDetect = now

    local pname = (player and player.Name) or "Unknown"
    local pdisplay = (player and player.DisplayName) or pname
    local status = (player and player:IsDescendantOf(game)) and "Online" or "Offline"

    local title = "⚠️ Admin Detected"
    local desc = ("Player: **%s** (%s)\nReason: %s\nStatus: %s\nPlaceId: %d\nServerId: %s\nTime: %s"):format(
        pname, pdisplay, tostring(reason or "-"), status, PlaceId, tostring(JobId), nowStr()
    )

    -- update UI label if available
    pcall(function() AdminLabel:Set("Admin Terdeteksi: " .. tostring(pname) .. " (" .. tostring(reason) .. ")") end)
    pcall(function() StatusLabel:Set("Status: Admin terdeteksi - " .. tostring(pname)) end)

    -- copy to clipboard quick
    pcall(function() CopyToClipboard(pname) end)

    -- send webhook / log
    pcall(function() SendWebhook(title, desc, {color = 15158332, fields = {
        {name = "Player", value = pname, inline = true},
        {name = "Display", value = pdisplay, inline = true},
        {name = "Reason", value = tostring(reason), inline = false}
    }}) end)
    Log("Detected admin:", pname, reason)

    -- in-game notify
    pcall(function() if Rayfield and Rayfield.Notify then Rayfield:Notify({Title = "⚠️ Admin Terdeteksi", Content = tostring(pname).." ("..tostring(reason)..")", Duration = 6}) end end)

    -- attempt escape
    task.spawn(function()
        task.wait(0.6)
        performEscapeAction(pname, reason)
    end)

    -- release lock after small delay
    task.delay(8, function() handlingAdmin = false end)
end

-- wrapper check
local function CheckPlayerForAdmin(player)
    if not player or not player:IsDescendantOf(Players) then return false end
    if player == LocalPlayer then return false end

    -- ignore friends if enabled
    if Config.IgnoreFriends then
        local ok, isFriend = pcall(function() return player and LocalPlayer and player:IsFriendsWith(LocalPlayer.UserId) end)
        if ok and isFriend then
            if Config.VerboseLogging then Log("Ignored friend:", player.Name) end
            return false
        end
    end

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
    local ok4, reason4 = pcall(function() return movementAnomalyDetect(player) end)
    if ok4 and reason4 then
        handleAdminDetected(player, reason4)
        return true
    end

    return false
end

-- ============================
-- Part 8: Summit Tracking
-- ============================
local summitCount = 0
local lastRespawnTick = tick()
local lastSummitTime = 0

if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function()
        lastRespawnTick = tick()
        pcall(function() SummitLabel:Set("Summit: "..summitCount.." | Last: " .. FormatTimeSec(lastSummitTime)) end)
    end)
end

local function OnSummitReached()
    local now = tick()
    local timeTaken = math.floor(now - lastRespawnTick)
    lastSummitTime = timeTaken
    summitCount = summitCount + 1
    lastRespawnTick = now
    pcall(function() SummitLabel:Set("Summit: "..summitCount.." | Last: " .. FormatTimeSec(lastSummitTime)) end)

    local title = "✅ Summit Reached!"
    local desc = ("Player: **%s**\nCount: %d\nTimeTaken: %ds (%s)\nServer: %d\nTime: %s"):format(
        tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
        summitCount,
        lastSummitTime,
        FormatTimeSec(lastSummitTime),
        PlaceId,
        nowStr()
    )

    pcall(function() SendWebhook(title, desc, {color = 3066993}) end)
    pcall(function() if Rayfield and Rayfield.Notify then Rayfield:Notify({Title = "🏔️ Summit", Content = "Summit tercapai! Waktu: "..FormatTimeSec(lastSummitTime), Duration = 6}) end end)
    Log("Summit reached:", summitCount, "time:", lastSummitTime)
end

-- leaderstat watcher
local function TryStartLeaderstatWatcher()
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
                            OnSummitReached()
                        else
                            lastVal = newVal
                        end
                    end)
                end)
                Log("Leaderstat watcher attached.")
                break
            end
            task.wait(1)
        end
    end)
end

-- position watcher fallback
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

-- ============================
-- Part 9: Rayfield UI (single window) - load & create
-- ============================
-- Load Rayfield safely (user provided URL)
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not Rayfield then
    warn("Rayfield gagal dimuat. Pastikan URL dapat diakses dan executor mendukung loadstring HttpGet.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🛡️ Detektor",
    LoadingTitle = "Admin & Summit Detector",
    LoadingSubtitle = "Siap jalan",
    ConfigurationSaving = {
        Enabled = Config.ConfigurationSaving,
        FolderName = "DetektorSummit",
        FileName = "Config"
    },
})

-- Tabs
local DetTab = Window:CreateTab("Detektor")
local HWIDTab = Window:CreateTab("HWID", 4483362458)
local SettingsTab = Window:CreateTab("Settings")
local LogsTab = Window:CreateTab("Logs")

-- UI helpers
local function CreateLabel(text) if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(text) end return { Set = function() end } end
local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end end
local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end end
local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end end
local function CreateParagraph(tab, opts) if tab and tab.CreateParagraph then return tab:CreateParagraph(opts) end end

local function Notify(title, content, dur)
    dur = dur or 6
    pcall(function()
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({ Title = title, Content = content, Duration = dur })
        else
            warn(title, content)
        end
    end)
end

-- DetTab labels
AdminLabel = CreateLabel("Admin Terdeteksi: -")
SummitLabel = CreateLabel("Summit: 0 | Last: 00m:00s")
StatusLabel = CreateLabel("Status: Idle")

-- Controls on DetTab
local toggleAutoHopUI = CreateToggle({ Name = "🌍 Auto Hop jika Admin", CurrentValue = Config.AutoHop, Callback = function(v) Config.AutoHop = v end })
local toggleAutoLeaveUI = CreateToggle({ Name = "🚪 Auto Leave (Kick) jika Admin", CurrentValue = Config.AutoLeave, Callback = function(v) Config.AutoLeave = v end })
local toggleSendWebhookUI = CreateToggle({ Name = "📲 Kirim Notif ke Discord (Webhook)", CurrentValue = Config.SendWebhook, Callback = function(v) Config.SendWebhook = v end })
local inputWebhookUI = CreateTextBox({ Name = "Webhook URL (permanen di script, bisa ubah)", PlaceholderText = Config.WebhookURL, Text = Config.WebhookURL or "", Callback = function(txt) Config.WebhookURL = txt or Config.WebhookURL end })
local inputScanIntervalUI = CreateTextBox({ Name = "Scan Interval (detik)", PlaceholderText = tostring(Config.ScanInterval), Text = tostring(Config.ScanInterval), Callback = function(txt) local n = tonumber(txt) if n and n >= 0.5 then Config.ScanInterval = n end end })
local comboSummitMethodLabel = CreateLabel("Summit detect method: " .. tostring(Config.SummitDetectMethod))

CreateButton({ Name = "📡 Test Webhook", Callback = function()
    local ok,err = SendWebhook("✅ Test webhook dari Detektor | Player: " .. (LocalPlayer and LocalPlayer.Name or "Unknown"))
    if ok then Notify("Webhook", "Test terkirim ✅") else Notify("Webhook Gagal", tostring(err) or "error") end
end })

CreateButton({ Name = "🔄 Reset ke default (reload executor)", Callback = function()
    Notify("Reset", "Silakan reload executor secara manual untuk reset script.")
end })

-- Settings tab content
CreateParagraph(SettingsTab, { Title = "Pengaturan Lanjutan", Content = "Gunakan toggle di bawah untuk menyesuaikan perilaku detektor." })
local toggleIgnoreFriendsUI = SettingsTab:CreateToggle({ Name = "👥 Ignore Friends", CurrentValue = Config.IgnoreFriends, Callback = function(v) Config.IgnoreFriends = v end })
local toggleUseEmbedUI = SettingsTab:CreateToggle({ Name = "🧾 Use Webhook Embed", CurrentValue = Config.WebhookUseEmbed, Callback = function(v) Config.WebhookUseEmbed = v end })
local toggleVerboseUI = SettingsTab:CreateToggle({ Name = "📈 Verbose Logging", CurrentValue = Config.VerboseLogging, Callback = function(v) Config.VerboseLogging = v end })

-- HWID tab
local hwid = pcall(function() return RbxAnalytics:GetClientId() end) and RbxAnalytics:GetClientId() or "Unknown-HWID"
-- attempt external HWID list (optional)
local AllowedHWIDs = {}
local okHW, resHW = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nomamonx/gunung/refs/heads/main/hwid1.lua"))()
end)
if okHW and type(resHW) == "table" then
    AllowedHWIDs = resHW
    Log("Loaded HWID DB")
end
local isVIP = (AllowedHWIDs[hwid] == true)
if isVIP then
    CreateParagraph(HWIDTab, { Title = "✅ HWID Terdaftar", Content = "HWID kamu sudah terdaftar.\n\n"..hwid })
    HWIDTab:CreateButton({ Name = "Salin HWID", Callback = function() CopyToClipboard(hwid) Notify("HWID", "HWID disalin ke clipboard") end })
else
    CreateParagraph(HWIDTab, { Title = "❌ HWID Tidak Terdaftar", Content = "HWID kamu tidak terdaftar.\n\n"..hwid })
    HWIDTab:CreateButton({ Name = "Salin HWID", Callback = function() CopyToClipboard(hwid) Notify("HWID", "HWID disalin ke clipboard") end })
end

-- Logs tab (buttons)
LogsTab:CreateButton({ Name = "📜 Salin 200 Log Terakhir", Callback = function()
    local out = ""
    for i = math.max(1, #LogHistory-199), #LogHistory do
        local e = LogHistory[i]
        if e then out = out .. "["..e.time.."] "..e.text.."\n" end
    end
    CopyToClipboard(out)
    Notify("Log", "200 log terakhir disalin ke clipboard.")
end })

LogsTab:CreateButton({ Name = "📂 Tampilkan 40 Log (Console)", Callback = function()
    for i = math.max(1,#LogHistory-39), #LogHistory do
        local e = LogHistory[i]
        if e then print("["..e.time.."] "..e.text) end
    end
    Notify("Log", "40 log terakhir dicetak di console.")
end })

-- Extra buttons on DetTab for manual actions
CreateButton({ Name = "🔎 Manual Scan Sekarang", Callback = function()
    task.spawn(function()
        local pls = Players:GetPlayers()
        for _,pl in ipairs(pls) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdmin(pl) end)
            end
        end
        Notify("Manual Scan", "Selesai memindai pemain.")
    end)
end })

CreateButton({ Name = "🗂️ Clear Banned Server Cache", Callback = function()
    bannedServersCache = {}
    Notify("Cache", "Banned server cache dibersihkan.")
    Log("Banned server cache cleared by user.")
end })

-- ============================
-- Part 10: Main Scanner Loop & Events
-- ============================
-- PlayerAdded hook for faster detection
Players.PlayerAdded:Connect(function(pl)
    task.spawn(function()
        task.wait(0.5)
        pcall(function() CheckPlayerForAdmin(pl) end)
    end)
end)

-- start watchers and main loop
if Config.SummitDetectMethod == "leaderstat" then
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
elseif Config.SummitDetectMethod == "position" then
    TryStartPositionWatcher()
else
    TryStartLeaderstatWatcher()
    TryStartPositionWatcher()
end

-- main periodic scan
task.spawn(function()
    while true do
        local players = Players:GetPlayers()
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                pcall(function() CheckPlayerForAdmin(pl) end)
            end
        end
        pcall(function() StatusLabel:Set("Status: Running | Players: " .. tostring(#players)) end)
        task.wait(Config.ScanInterval or 2.5)
    end
end)

-- initial UI update
pcall(function()
    AdminLabel:Set("Admin Terdeteksi: -")
    SummitLabel:Set("Summit: "..summitCount.." | Last: " .. FormatTimeSec(lastSummitTime))
    StatusLabel:Set("Status: Idle")
end)

-- final notify
Notify("🛡️ Detektor Aktif", "Admin & Summit Detector berjalan. Periksa tab HWID jika perlu. ✅")
Log("Detektor initialized. Version:", ScriptVersion)

-- =====================================================================
-- End of script
-- =====================================================================



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
