local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Private: MT Yahayyuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By ACONG",
})
-- Tab Informasi
-- ========================
local InfoTab = Window:CreateTab("Informasi", 6034509994)
InfoTab:CreateSection("Informasi")

InfoTab:CreateParagraph({
    Title = "Jammoko Baca",
    Content = "Ini adalah script teleport Yang kubuat asal asal akwokaowk.",
})
Rayfield:Notify({
   Title = "Script Dimuat",
   Content = "TELASO berhasil!!!",
   Duration = 6.5,
   Image = 4483362458,
})

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

-- ========================
-- Tab Pengaturan
-- ========================
local SettingsTab = Window:CreateTab("Pengaturan", 6034509993)

SettingsTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

SettingsTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 300},
   Increment = 10,
   Suffix = "Jump",
   CurrentValue = 50,
   Flag = "JumpSlider",
   Callback = function(Value)
       game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
   end,
})

SettingsTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
       local UserInputService = game:GetService("UserInputService")
       if Value then
           InfJumpConnection = UserInputService.JumpRequest:Connect(function()
               game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
           end)
       else
           if InfJumpConnection then
               InfJumpConnection:Disconnect()
               InfJumpConnection = nil
           end
       end
   end,
})

-- =======================================
-- 🔒 Admin / Owner / Dev Detector Script
-- Versi Lengkap + Summit Detector
-- =======================================

-- ===== Services =====
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ===== Config =====
local ConfigFile = "AdminDetectorConfig.json"
local DefaultConfig = {
    AutoHop = true,
    AutoLeave = false,
    NotifyDiscord = true,
    AutoNotifyInGame = true,
    CheckAdmin = true,
    CheckSummit = true,
    ScanInterval = 2.5,
    WebhookURL = "https://discord.com/api/webhooks/1314381124557865010/rjde-YwMH6pOi9Dk7LzQhlbCg1RGhYvouHgwrz_dYJi8amlIQLImuHnRXlLot-1mFfUU",
    BlacklistNames = {"YAHAVUKazigen","Dim","eugyne","VBZ","HeruAjaDeh","FENRIRDONGKAK","RAVINSKIE","NotHuman","MDFixDads","MDFuturFewWan","YAHAVUisDanzzy"}
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
        local raw = safe_readfile(ConfigFile)
        if raw then
            local ok, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(dec)=="table" then
                for k,v in pairs(DefaultConfig) do Config[k] = dec[k]==nil and v or dec[k] end
                if type(Config.BlacklistNames)~="table" then Config.BlacklistNames=DefaultConfig.BlacklistNames end
                return
            end
        end
    end
    for k,v in pairs(DefaultConfig) do Config[k]=v end
    SaveConfig()
end
LoadConfig()

-- ===== UI =====
local DetectionTab = rawget(_G,"DetectionTab") or rawget(_ENV,"DetectionTab")
local Rayfield
if not DetectionTab then
    local ok,rf=pcall(function() return loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)
    if ok and rf then
        Rayfield=rf
        local Window=Rayfield:CreateWindow({Name="🛡️ Admin Detector",LoadingTitle="Activate Detector",LoadingSubtitle="paste by kamu"})
        DetectionTab=Window:CreateTab("🛡️ Detection")
    else
        warn("Rayfield tidak tersedia; script tetap jalan tanpa UI.")
    end
else
    Rayfield = rawget(_G,"Rayfield") or rawget(_ENV,"Rayfield")
end

local function CreateLabel(txt) if DetectionTab and DetectionTab.CreateLabel then return DetectionTab:CreateLabel(txt) end return {Set=function() end} end
local function CreateToggle(opts) if DetectionTab and DetectionTab.CreateToggle then return DetectionTab:CreateToggle(opts) end return nil end
local function CreateButton(opts) if DetectionTab and DetectionTab.CreateButton then return DetectionTab:CreateButton(opts) end return nil end
local function CreateTextBox(opts) if DetectionTab and DetectionTab.CreateTextBox then return DetectionTab:CreateTextBox(opts) end return nil end
local function IngameNotify(title,content) if Rayfield and Rayfield.Notify then Rayfield:Notify({Title=title,Content=content,Duration=5}) else warn(title.." - "..content) end end

-- ===== Discord webhook =====
local function SendDiscordNotif(msg)
    if not Config.NotifyDiscord then return end
    local url = Config.WebhookURL or DefaultConfig.WebhookURL
    if not url or url=="" then return end
    local body=HttpService:JSONEncode({content=msg})
    local req=(syn and syn.request) or http_request or request or (http and http.request)
    if req then pcall(function() req({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) end)
    else pcall(function() game:HttpPost(url,body,Enum.HttpContentType.ApplicationJson) end)
    end
end

-- ===== Detection utilities =====
local rankKeywords={"admin","owner","developer","dev","mod","staff","gm","pengawas","admin1","admin 1","admin2","admin 2","admin3","admin 3"}
local function lower(s) return (type(s)=="string" and string.lower(s) or "") end
local function containsKeywordText(txt) if not txt then return false end txt=lower(txt) for _,kw in ipairs(rankKeywords) do if string.find(txt,kw,1,true) then return true end end return false end

local function nameBasedDetect(player)
    local uname=lower(player.Name or "")
    local dname=lower(player.DisplayName or "")
    for _,b in ipairs(Config.BlacklistNames) do if uname==lower(b) or dname==lower(b) then return true,"BlacklistName" end end
    for _,kw in ipairs(rankKeywords) do if string.find(uname,kw,1,true) or string.find(dname,kw,1,true) then return true,"NameContains:"..kw end end
    return false,nil
end

local function guiBasedDetect(player)
    if not player.Character then return false,nil end
    local head=player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return false,nil end
    for _,gui in ipairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("ScreenGui") then
            for _,desc in ipairs(gui:GetDescendants()) do
                local t=desc
                if t and (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) then
                    local txt=lower(t.Text or "")
                    if txt~="" and containsKeywordText(txt) then return true,"GuiText:"..(t.Text or "") end
                    if t.TextColor3 then local c=t.TextColor3 if (c.R>0.8 and c.G<0.4 and c.B<0.4) or (c.R>0.9 and c.G<0.6 and c.B<0.6) then return true,"GuiColorHint" end end
                end
            end
        end
    end
    return false,nil
end

local function summitDetect(player)
    local uname=lower(player.Name or "")
    local dname=lower(player.DisplayName or "")
    if string.find(uname,"summit",1,true) or string.find(dname,"summit",1,true) then return true end
    local ok,reason=guiBasedDetect(player)
    if ok and reason and string.find(lower(reason),"summit",1,true) then return true end
    return false
end

local function IsDangerous(player)
    local nameOk,reason=nameBasedDetect(player)
    if nameOk then return true,reason end
    if player.Character then for i=1,4 do local ok,r=guiBasedDetect(player) if ok then return true,r end task.wait(0.35) end end
    return false,nil
end

-- ===== Server Hop =====
local function ServerHop()
    local tried={} local maxPages=6 local pageCursor=nil local foundId=nil
    for page=1,maxPages do
        local url=("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc"):format(PlaceId)
        if pageCursor then url=url.."&cursor="..pageCursor end
        local success,res=pcall(function() return game:HttpGet(url) end)
        if not success or not res then break end
        local ok,json=pcall(function() return HttpService:JSONDecode(res) end)
        if not ok or not json or type(json.data)~="table" then break end
        for _,srv in ipairs(json.data) do
            if type(srv)=="table" and srv.id and srv.playing and srv.maxPlayers then
                if tostring(srv.id)~=tostring(JobId) and srv.playing<srv.maxPlayers then
                    if not tried[srv.id] then foundId=srv.id break end
                end
            end
        end
        if foundId then break end
        pageCursor=json.nextPageCursor
        if not pageCursor then break end
    end
    if foundId then pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId,foundId,LocalPlayer) end)
    else IngameNotify("Hop Gagal","Tidak menemukan server kosong.") return false
    end
end

-- ===== Handling =====
local handling=false lastDetect=0 detectCooldown=6
local function HandleDanger(player,reason)
    if handling then return end
    local now=tick()
    if now-lastDetect<detectCooldown then return end
    handling=true lastDetect=now
    local msg=("Deteksi: %s | Reason: %s | Place: %d"):format(player.Name or "Unknown",tostring(reason),PlaceId)
    if Config.AutoNotifyInGame then IngameNotify("⚠️ Admin Terdeteksi",player.Name.." ("..tostring(reason)..")") end
    if Config.NotifyDiscord then pcall(function() SendDiscordNotif("⚠️ Admin terdeteksi: **"..player.Name.."** — "..tostring(reason)) end) end
    if Config.AutoHop then task.spawn(function() task.wait(0.6) local ok=pcall(ServerHop) if not ok and Config.AutoLeave then pcall(function() LocalPlayer:Kick("Admin terdeteksi: "..player.Name) end) end end)
    elseif Config.AutoLeave then task.spawn(function() task.wait(0.6) pcall(function() LocalPlayer:Kick("Admin terdeteksi: "..player.Name) end) end) end
    task.delay(8,function() handling=false end)
end

local function CheckOnePlayer(player)
    local ok,reason=pcall(function() return IsDangerous(player) end)
    if ok and reason then HandleDanger(player,reason) return true end
    if Config.CheckSummit then local ok2=pcall(function() return summitDetect(player) end) if ok2 then HandleDanger(player,"Summit/Foto") return true end end
    return false
end

local function ScanAllPlayers()
    if not Config.CheckAdmin then return end
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LocalPlayer then local success=pcall(function() return CheckOnePlayer(pl) end) if success and handling then break end end end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        for i=1,6 do if handling then break end if CheckOnePlayer(pl) then break end task.wait(0.6) end
    end)
end)
task.spawn(function() task.wait(0.8) ScanAllPlayers() end)
task.spawn(function() while true do if Config.CheckAdmin and not handling then ScanAllPlayers() end task.wait(tonumber(Config.ScanInterval) or 2.5) end end)

-- ===== UI Labels =====
local AdminLabel,SummitLabelObj
if DetectionTab then
    AdminLabel=DetectionTab:CreateLabel("Admin Terdeteksi: -")
    SummitLabelObj=DetectionTab:CreateLabel("Top Puncak: -")
end

-- ===== Tambahan: Track durasi & summit milikmu =====
local MyJoinTime = tick()

local function GetMySummitCount()
    if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Summit") then
        return LocalPlayer.leaderstats.Summit.Value
    end
    return 0
end

local function SendMySummitInfoToDiscord()
    if not Config.NotifyDiscord or not Config.WebhookURL or Config.WebhookURL=="" then return end
    local duration=math.floor(tick()-MyJoinTime)
    local summitCount=GetMySummitCount()
    local msg="**📊 Info Summit Saya**\n"
    msg=msg.."Waktu server: "..os.date("%Y-%m-%d %H:%M:%S").."\n"
    msg=msg.."Durasi saya di server: "..duration.." detik\n"
    msg=msg.."Jumlah summit saya: "..summitCount.."\n"
    SendDiscordNotif(msg)
end

-- Tombol manual
if DetectionTab then
    CreateButton({
        Name="📡 Kirim Info Summit Saya ke Discord",
        Callback=function()
            SendMySummitInfoToDiscord()
            IngameNotify("Summit Info","Notif dikirim ke Discord.")
        end
    })
end

-- Otomatis tiap 5 menit
task.spawn(function()
    while true do
        task.wait(300)
        SendMySummitInfoToDiscord()
    end
end)

-- ===== Final Note =====
IngameNotify("Admin Detector","Script aktif. Pastikan Webhook diisi bila ingin notif ke Discord.")
