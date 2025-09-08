-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Config =====
local ConfigFile = "DetectorConfig.json"
local DefaultConfig = {
    AutoHop = true,
    AutoLeave = false,
    NotifyDiscord = true,
    ScanInterval = 2.5,
    WebhookURL = "https://discord.com/api/webhooks/xxxxx", -- ganti webhook
    BlacklistNames = { 
        "YAHAVUKazigen","Dim","eugyne","VBZ","HeruAjaDeh",
        "FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads",
        "MDFuturFewWan","YAHAVUisDanzzy"
    },
    RankKeywords = {"ADMIN","OWNER","DEV","DEVELOPER","MOD","STAFF","GM","PENGAWAS"}
}
local Config = {}

-- ===== Safe file helpers =====
local function safe_isfile(p) return isfile and pcall(isfile,p) end
local function safe_writefile(p,d) if writefile then pcall(writefile,p,d) end end
local function safe_readfile(p) if readfile then local ok,res=pcall(readfile,p) if ok then return res end end return nil end
local function safe_delfile(p) if delfile then pcall(delfile,p) end end

-- ===== Load/Save Config =====
local function SaveConfig() local ok,enc=pcall(function() return HttpService:JSONEncode(Config) end) if ok then safe_writefile(ConfigFile,enc) end end
local function LoadConfig()
    if safe_isfile(ConfigFile) then
        local raw=safe_readfile(ConfigFile)
        if raw then
            local ok,dec=pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(dec)=="table" then
                for k,v in pairs(DefaultConfig) do Config[k]=dec[k]==nil and v or dec[k] end
                if type(Config.BlacklistNames)~="table" then Config.BlacklistNames=DefaultConfig.BlacklistNames end
                return
            end
        end
    end
    for k,v in pairs(DefaultConfig) do Config[k]=v end
    SaveConfig()
end
LoadConfig()

-- ===== Rayfield Window =====
local Rayfield
local ok,rf = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
if ok and rf then Rayfield=rf else warn("Rayfield tidak tersedia!") return end
local Window = Rayfield:CreateWindow({ Name="🛡️ Detektor", LoadingTitle="Detektor Aktif", LoadingSubtitle="Monitoring Admin & Summit" })
local DetTab = Window:CreateTab("Detektor")

-- ===== UI Helpers =====
local function CreateLabel(txt) if DetTab and DetTab.CreateLabel then return DetTab:CreateLabel(txt) end return {Set=function() end} end
local function CreateToggle(opts) if DetTab and DetTab.CreateToggle then return DetTab:CreateToggle(opts) end return nil end
local function CreateTextBox(opts) if DetTab and DetTab.CreateTextBox then return DetTab:CreateTextBox(opts) end return nil end
local function CreateButton(opts) if DetTab and DetTab.CreateButton then return DetTab:CreateButton(opts) end return nil end
local function Notify(title,content) if Rayfield and Rayfield.Notify then Rayfield:Notify({Title=title,Content=content,Duration=5}) else warn(title.." - "..content) end end

-- ===== Discord =====
local function SendDiscord(msg)
    if not Config.NotifyDiscord then return end
    local url = Config.WebhookURL
    if not url or url=="" then return end
    local body = HttpService:JSONEncode({content=msg})
    local req = (syn and syn.request) or http_request or request or (http and http.request)
    if req then pcall(function() req({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    else pcall(function() game:HttpPost(url,body,Enum.HttpContentType.ApplicationJson) end)
    end
end

-- ===== Detection =====
local function lower(s) return (type(s)=="string" and string.lower(s) or "") end

local function nameDetect(player)
    local uname = lower(player.Name or "")
    local dname = lower(player.DisplayName or "")
    for _,b in ipairs(Config.BlacklistNames) do
        if uname==lower(b) or dname==lower(b) then return true,"BlacklistName" end
    end
    for _,kw in ipairs(Config.RankKeywords) do
        if string.find(uname,kw:lower(),1,true) or string.find(dname,kw:lower(),1,true) then return true,"NameContains:"..kw end
    end
    return false,nil
end

local function guiDetect(player)
    if not player.Character then return false,nil end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false,nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    local txt = tostring(d.Text or "")
                    if txt:match("^[A-Z0-9%s]+$") then
                        for _,kw in ipairs(Config.RankKeywords) do
                            if txt:find(kw) then return true,"GuiText:"..txt end
                        end
                    end
                end
            end
        end
    end
    return false,nil
end

-- ===== Handling Admin =====
local handling = false
local lastDetect = 0
local detectCooldown = 6

local function ServerHop()
    local tried={},maxPages=6
    local pageCursor,foundId=nil,nil
    for page=1,maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url=url.."&cursor="..pageCursor end
        local success,res=pcall(function() return game:HttpGet(url) end)
        if not success or not res then break end
        local ok,json=pcall(function() return HttpService:JSONDecode(res) end)
        if not ok or not json or type(json.data)~="table" then break end
        for _,srv in ipairs(json.data) do
            if tostring(srv.id)~=tostring(JobId) and srv.playing<srv.maxPlayers and not tried[srv.id] then
                foundId = srv.id break
            end
        end
        if foundId then break end
        pageCursor=json.nextPageCursor
        if not pageCursor then break end
    end
    if foundId then
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId,foundId,LocalPlayer) end)
    else
        Notify("Hop Gagal","Tidak menemukan server kosong")
    end
end

local function HandleAdmin(player,reason)
    if handling then return end
    local now=tick()
    if now-lastDetect<detectCooldown then return end
    handling=true lastDetect=now

    local status = player:IsDescendantOf(game) and "Online" or "Offline"
    local msg = ("⚠️ Admin Detected: **%s** | Reason: %s | Status: %s | Server: %d"):format(player.Name, reason, status, PlaceId)
    
    Notify("⚠️ Admin Terdeteksi", player.Name.." ("..reason..")")
    SendDiscord(msg)

    if Config.AutoHop then task.spawn(ServerHop)
    elseif Config.AutoLeave then pcall(function() LocalPlayer:Kick("Admin: "..player.Name) end) end

    task.delay(8,function() handling=false end)
end

local function CheckAdmin(player)
    local ok,reason=nameDetect(player)
    if ok then HandleAdmin(player,reason) return true end
    local ok2,reason2=guiDetect(player)
    if ok2 then HandleAdmin(player,reason2) return true end
    return false
end

-- ===== Summit Tracker =====
local summitCount=0
local lastRespawnTime=tick()
local summitTimer=0
local SummitLabel = CreateLabel("Summit Count: 0 | Last Time: 0s")
LocalPlayer.CharacterAdded:Connect(function() lastRespawnTime=tick() end)
local function SummitReached()
    local now=tick()
    summitCount = summitCount + 1
    local timeTaken = math.floor(now-lastRespawnTime)
    summitTimer = timeTaken
    SummitLabel:Set("Summit Count: "..summitCount.." | Last Time: "..timeTaken.."s")
    SendDiscord("✅ Summit Reached! Count: "..summitCount.." | Time: "..timeTaken.."s | Server Time: "..os.date("%X"))
end

-- ===== UI =====
CreateToggle({ Name="Auto Hop jika Admin", CurrentValue=Config.AutoHop, Callback=function(v) Config.AutoHop=v SaveConfig() end })
CreateToggle({ Name="Auto Leave jika Admin", CurrentValue=Config.AutoLeave, Callback=function(v) Config.AutoLeave=v SaveConfig() end })
CreateToggle({ Name="Kirim Notif ke Discord", CurrentValue=Config.NotifyDiscord, Callback=function(v) Config.NotifyDiscord=v SaveConfig() end })
CreateTextBox({ Name="Webhook URL", Text=Config.WebhookURL, Placeholder="Isi Webhook", Callback=function(v) Config.WebhookURL=v SaveConfig() end })
CreateButton({ Name="Test Webhook", Callback=function() SendDiscord("✅ Test Webhook Active | Player: "..LocalPlayer.Name) Notify("Test Webhook","Pesan test terkirim") end })

-- ===== Main Loop =====
task.spawn(function()
    while true do
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=LocalPlayer then pcall(CheckAdmin,pl) end
        end
        task.wait(Config.ScanInterval)
    end
end)

Notify("Detektor Aktif","Admin & Summit Tracker berjalan")
