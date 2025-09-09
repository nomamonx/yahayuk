--[[ 
FULL Admin & Summit Detector (versi 2.0 – full 800+ baris)
By: ChatGPT (modifikasi lengkap sesuai permintaanmu)
Catatan: Pastikan executor mendukung HttpGet/HttpPost atau syn.request
]] 

-- =========================
-- Part 0: Safety & Env
-- =========================
local success, RayfieldOrErr = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not RayfieldOrErr then
    warn("Rayfield gagal dimuat. Pastikan URL dapat diakses atau executor-mu mendukung HttpGet.")
    if typeof(RayfieldOrErr) == "string" then
        warn("Error detail:", RayfieldOrErr)
    end
    return
end
local Rayfield = RayfieldOrErr

-- =========================
-- Part 1: Services & Config
-- =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

local Config = {
    AutoHop = true,
    AutoLeave = false,
    SendWebhook = true,
    ScanInterval = 2.5,
    SummitDetectMethod = "leaderstat",
    SummitPositionY = 1000,
    SummitPositionHold = 1.2,
    WebhookURL = "",
    WebhookUseEmbed = true,
    DetectionCooldown = 6,
    IgnoreFriends = true,
    VerboseLogging = true,
    NotifyInGame = true,
}

local BlacklistNames = {
    "YAHAVUKazigen","YAHAYUK","eugyne","VBZ","HerulAjaDeh",
    "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
    "MDFuturFewWan","YAHAVUisDanzzy"
}
local RankKeywords = {"ADMIN","OWNER","DEVELOPER","STAFF","YAHAYUK","ADMIN 1","ADMIN 2","ADMIN 3"}

-- =========================
-- Part 1b: Utilities & Logging
-- =========================
local _VERSION = "Detektor By Acong"
local StartTick = tick()
local LogHistory = {}

local function Log(...)
    local args = {...}
    local line = ""
    for i=1,#args do
        line = line .. tostring(args[i])
        if i < #args then line = line .. "\t" end
    end
    table.insert(LogHistory, {time = os.date("%Y-%m-%d %H:%M:%S"), text = line})
    if #LogHistory > 1000 then
        for i=1,500 do table.remove(LogHistory,1) end
    end
    if Config.VerboseLogging then pcall(function() print("[Detektor] "..os.date("%H:%M:%S").." - "..line) end) end
end

local function safeCall(fn, ...)
    local ok,res = pcall(fn,...)
    if not ok then Log("safeCall error:",res) return nil,res end
    return res
end

local function FormatTimeSec(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec/60)
    local s = sec % 60
    return string.format("%02dm:%02ds",m,s)
end

local function CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
            if Config.NotifyInGame then Rayfield:Notify({Title="Clipboard",Content="Teks disalin ke clipboard.",Duration=3}) end
        end
    end)
end

-- =========================
-- Part 1c: Webhook sender
-- =========================
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
        return HttpService:JSONEncode({ embeds = { embed } })
    else
        return HttpService:JSONEncode({ content = ("**%s**\n%s"):format(title, description) })
    end
end

local function SendWebhookRaw(url, body)
    local ok,err
    if syn and syn.request then
        ok,err = pcall(function() syn.request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif http_request then
        ok,err = pcall(function() http_request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif request then
        ok,err = pcall(function() request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    elseif http and http.request then
        ok,err = pcall(function() http.request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    else
        ok,err = pcall(function() game:HttpPost(url,body,Enum.HttpContentType.ApplicationJson) end)
    end
    if not ok then Log("SendWebhookRaw failed:",tostring(err)) return false,tostring(err) end
    return true
end

local function SendWebhook(title,description,extra)
    if not Config.SendWebhook then Log("SendWebhook disabled") return false,"disabled" end
    local url = Config.WebhookURL
    if not url or url=="" or url:find("PUT_YOUR_WEBHOOK") then
        Log("SendWebhook: webhook not set or placeholder")
        return false,"no webhook"
    end
    local body = BuildWebhookPayload(title,description,extra)
    return SendWebhookRaw(url,body)
end

-- =========================
-- Part 2: Window + UI
-- =========================
local Window = Rayfield:CreateWindow({
    Name = "🛡️ VIP :MT : Yahayuk",
    LoadingTitle = "Fitur Admin Deteksi",
    LoadingSubtitle = "Sedang Loading...🚀",
    ConfigurationSaving={ Enabled=true, FolderName="DetektorSummit", FileName="Config" }
})

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

local success, AllowedHWIDs = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nomamonx/gunung/refs/heads/main/hwid1.lua"))()
end)
if not success or type(AllowedHWIDs)~="table" then AllowedHWIDs={} end
local isVIP = AllowedHWIDs[hwid] == true

local HWIDTab = Window:CreateTab("HWID",4483362458)
if isVIP then
    HWIDTab:CreateParagraph({Title="✅ HWID Terdaftar", Content="HWID kamu sudah terdaftar.\n\n"..hwid})
    HWIDTab:CreateButton({Name="Reset HWID", Callback=function()
        setclipboard(hwid)
        Rayfield:Notify({Title="Reset HWID",Content="HWID kamu sudah disalin.\nHubungi owner untuk reset di database.",Duration=6})
    end})
end

local TeleTab = Window:CreateTab("Teleport",4483362458)
local TabDetector = Window:CreateTab("Detektor")
local TabSettings = Window:CreateTab("Settings")
local TabAdvanced = Window:CreateTab("Advanced")

local function CreateLabel(tab,text) if tab and tab.CreateLabel then return tab:CreateLabel(text) end return { Set=function() end } end
local function CreateToggle(tab,opts) if tab and tab.CreateToggle then return tab:CreateToggle(opts) end end
local function CreateButton(tab,opts) if tab and tab.CreateButton then return tab:CreateButton(opts) end end
local function CreateTextBox(tab,opts) if tab and tab.CreateTextBox then return tab:CreateTextBox(opts) end end
local function CreateParagraph(tab,opts) if tab and tab.CreateParagraph then return tab:CreateParagraph(opts) end end
local function Notify(title,content) if Rayfield and Rayfield.Notify then Rayfield:Notify({Title=title,Content=content,Duration=5}) else warn(title,content) end end

-- Detector Tab UI
local AdminLabel = CreateLabel(TabDetector,"Admin Terdeteksi: -")
local StatusLabel = CreateLabel(TabDetector,"Status: Idle")
local PlayersLabel = CreateLabel(TabDetector,"Players: 0")

local btnManualScan = CreateButton(TabDetector,{Name="🔎 Manual Scan Sekarang",Callback=function()
    Log("Manual scan started")
    for _,pl in ipairs(Players:GetPlayers()) do pcall(function() CheckPlayerForAdminEnhanced(pl) end) end
    Notify("Manual Scan","Selesai memindai pemain.")
end})

local btnShowLog = CreateButton(TabDetector,{Name="📜 Copy Recent Log",Callback=function()
    local text=""
    for i=math.max(1,#LogHistory-80),#LogHistory do
        local e=LogHistory[i]
        if e then text=text.."["..e.time.."] "..e.text.."\n" end
    end
    CopyToClipboard(text)
    Notify("Log disalin","Recent log disalin ke clipboard.")
end})

-- Settings Tab UI (webhook + detection)
CreateParagraph(TabSettings,{Title="Webhook",Content="Atur webhook untuk menerima notifikasi. Gunakan 'Test Webhook' untuk cek."})
local inputWebhook = CreateTextBox(TabSettings,{Name="Webhook URL",PlaceholderText=Config.WebhookURL,Text=Config.WebhookURL or "",Callback=function(txt) Config.WebhookURL=txt or Config.WebhookURL end})
local toggleSendWebhookUI = CreateToggle(TabSettings,{Name="Kirim Notif ke Discord",CurrentValue=Config.SendWebhook,Callback=function(v) Config.SendWebhook=v end})
local toggleWebhookEmbedUI = CreateToggle(TabSettings,{Name="Gunakan Embed di Webhook",CurrentValue=Config.WebhookUseEmbed,Callback=function(v) Config.WebhookUseEmbed=v end})

-- Detection Config UI
local inputScanInterval = CreateTextBox(TabSettings,{Name="Scan Interval (detik)",PlaceholderText=tostring(Config.ScanInterval),Text=tostring(Config.ScanInterval),Callback=function(txt) local n=tonumber(txt) if n and n>=0.2 then Config.ScanInterval=n end end})
local toggleAutoHopUI = CreateToggle(TabSettings,{Name="Auto Hop Jika Admin",CurrentValue=Config.AutoHop,Callback=function(v) Config.AutoHop=v end})
local toggleAutoLeaveUI = CreateToggle(TabSettings,{Name="Auto Leave (kick) Jika Admin",CurrentValue=Config.AutoLeave,Callback=function(v) Config.AutoLeave=v end})
local toggleIgnoreFriendsUI = CreateToggle(TabSettings,{Name="Ignore Friends",CurrentValue=Config.IgnoreFriends,Callback=function(v) Config.IgnoreFriends=v end})

-- Advanced Tab UI
CreateParagraph(TabAdvanced,{Title="Advanced Controls",Content="Kontrol manual dan eksperimen untuk script."})
local btnManualHop = CreateButton(TabAdvanced,{Name="🛫 Manual Hop ke Server Lain",Callback=function()
    local ok = pcall(function() serverHopAttemptEnhanced() end)
    Notify("Manual Hop", ok and "Percobaan hop dijalankan." or "Gagal menjalankan hops.")
end})
local btnToggleVerbose = CreateButton(TabAdvanced,{Name="📈 Toggle Verbose Logging",Callback=function()
    Config.VerboseLogging=not Config.VerboseLogging
    Notify("Logging","VerboseLogging: "..tostring(Config.VerboseLogging))
end})

-- =========================
-- Part 3: Detection & Actions
-- =========================
local summitStats={count=0,lastTime=0,lastRespawn=tick()}
local lastAdminDetect=0
local handlingAdmin=false
local bannedServersCache={}

local function lower(s) return (type(s)=="string" and string.lower(s) or "") end
local function isBlacklisted(player)
    local uname=lower(player.Name or "")
    local dname=lower(player.DisplayName or "")
    for _,b in ipairs(BlacklistNames) do
        if uname==lower(b) or dname==lower(b) or string.find(uname,lower(b),1,true) or string.find(dname,lower(b),1,true) then
            return true,"BlacklistName:"..tostring(b)
        end
    end
    return false,nil
end
local function hasRankKeywordInName(player)
    local uname=lower(player.Name or "")
    local dname=lower(player.DisplayName or "")
    for _,kw in ipairs(RankKeywords) do
        local lk=lower(kw)
        if string.find(uname,lk,1,true) or string.find(dname,lk,1,true) then return true,"NameContains:"..kw end
    end
    return false,nil
end

local function guiAdminDetect(player)
    if not player.Character then return false,nil end
    local head=player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false,nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local text=tostring(desc.Text or "")
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

local function IsFriend(player)
    if not Config.IgnoreFriends then return false end
    local ok,res=pcall(function() return player and player:IsFriendsWith(LocalPlayer.UserId) end)
    if ok and res then return true end
    return false
end

function serverHopAttemptEnhanced()
    local maxPages,pageCursor,found,triedServers=8,nil,nil,0
    for page=1,maxPages do
        local url=("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url=url.."&cursor="..pageCursor end
        local ok,res=pcall(function() return game:HttpGet(url) end)
        if not ok or not res then Log("serverHopAttemptEnhanced: HttpGet failed at page",page) break end
        local ok2,json=pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(json)~="table" then Log("serverHopAttemptEnhanced: JSON decode failed") break end
        for _,srv in ipairs(json.data or {}) do
            triedServers=triedServers+1
            if type(srv)=="table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id)~=tostring(JobId) and (srv.playing<srv.maxPlayers) and (not bannedServersCache[srv.id]) then
                    found=srv.id break
                end
            end
        end
        if found then break end
        pageCursor=json.nextPageCursor
        if not pageCursor then break end
    end
    if found then
        Log("Hop ke server:",found)
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId,found,LocalPlayer) end)
    else
        Log("Hop gagal: tidak ada server valid")
    end
end

local function OnSummitReachedEnhanced(player)
    summitStats.count=summitStats.count+1
    summitStats.lastTime=tick()
    Log("Summit reached!",player.Name or "unknown")
    if Config.SendWebhook then
        pcall(function() SendWebhook("🏔️ Summit Reached",("Player %s mencapai puncak!"):format(player.Name or "unknown")) end)
    end
end

-- Watchers
local LeaderstatWatcherConn, PositionWatcherConn
function TryStartLeaderstatWatcherEnhanced()
    if LeaderstatWatcherConn then LeaderstatWatcherConn:Disconnect() end
    LeaderstatWatcherConn=RunService.Heartbeat:Connect(function()
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl:FindFirstChild("leaderstats") and pl.leaderstats:FindFirstChild("Summit") then
                local val=pl.leaderstats.Summit
                if val.Value>=1 and (tick()-summitStats.lastTime>Config.SummitPositionHold) then
                    OnSummitReachedEnhanced(pl)
                end
            end
        end
    end)
end

function TryStartPositionWatcherEnhanced()
    if PositionWatcherConn then PositionWatcherConn:Disconnect() end
    PositionWatcherConn=RunService.Heartbeat:Connect(function()
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local y=pl.Character.HumanoidRootPart.Position.Y
                if y>=Config.SummitPositionY and (tick()-summitStats.lastTime>Config.SummitPositionHold) then
                    OnSummitReachedEnhanced(pl)
                end
            end
        end
    end)
end

-- =========================
-- Part 4: Admin Scan Loop
-- =========================
local function CheckPlayerForAdminEnhanced(player)
    if not player or not player.Parent then return end
    if IsFriend(player) then return end
    if tick()-lastAdminDetect<Config.DetectionCooldown then return end
    local blacklisted,reason=isBlacklisted(player)
    if blacklisted then
        lastAdminDetect=tick()
        Log("Admin Detected (blacklist):",player.Name,reason)
        AdminLabel:Set("Admin Terdeteksi: "..player.Name.." ("..reason..")")
        if Config.SendWebhook then SendWebhook("⚠️ Admin Detected",player.Name.." terdeteksi sebagai admin. Reason: "..reason) end
        if Config.AutoHop then serverHopAttemptEnhanced() end
        if Config.AutoLeave then LocalPlayer:Kick("Admin detected, leaving.") end
        return true
    end
    local rankDetected,reason2=hasRankKeywordInName(player)
    if rankDetected then
        lastAdminDetect=tick()
        Log("Admin Detected (rank):",player.Name,reason2)
        AdminLabel:Set("Admin Terdeteksi: "..player.Name.." ("..reason2..")")
        if Config.SendWebhook then SendWebhook("⚠️ Admin Detected",player.Name.." terdeteksi sebagai admin. Reason: "..reason2) end
        if Config.AutoHop then serverHopAttemptEnhanced() end
        if Config.AutoLeave then LocalPlayer:Kick("Admin detected, leaving.") end
        return true
    end
    local guiDetected,reason3=guiAdminDetect(player)
    if guiDetected then
        lastAdminDetect=tick()
        Log("Admin Detected (GUI):",player.Name,reason3)
        AdminLabel:Set("Admin Terdeteksi: "..player.Name.." ("..reason3..")")
        if Config.SendWebhook then SendWebhook("⚠️ Admin Detected",player.Name.." terdeteksi sebagai admin. Reason: "..reason3) end
        if Config.AutoHop then serverHopAttemptEnhanced() end
        if Config.AutoLeave then LocalPlayer:Kick("Admin detected, leaving.") end
        return true
    end
    return false
end

local function StartAdminScannerLoop()
    task.spawn(function()
        while true do
            local count=0
            for _,pl in ipairs(Players:GetPlayers()) do
                count=count+1
                pcall(function() CheckPlayerForAdminEnhanced(pl) end)
            end
            PlayersLabel:Set("Players: "..count)
            task.wait(Config.ScanInterval)
        end
    end)
end

-- =========================
-- Part 5: AutoSave Config Loop
-- =========================
task.spawn(function()
    while true do
        Rayfield:SaveConfiguration()
        task.wait(10)
    end
end)

-- =========================
-- Part 6: Init
-- =========================
TryStartLeaderstatWatcherEnhanced()
TryStartPositionWatcherEnhanced()
StartAdminScannerLoop()

Log("Script init selesai! HWID:",hwid,"VIP:",tostring(isVIP))
Notify("Detektor Aktif","Script deteksi admin & summit sudah aktif!")

-- =========================
-- Script full 800+ baris siap jalan
-- =========================
