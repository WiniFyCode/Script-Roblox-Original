local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remoteHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
local remoteQuest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept")

-- === DANH SÁCH NHIỆM VỤ (Dựa trên QuestConfig) ===
local QuestList = {
    {Level = 5000, ID = "QuestNPC11", Target = "Hollow"},
    {Level = 4000, ID = "QuestNPC10", Target = "PandaMiniBoss"},
    {Level = 3000, ID = "QuestNPC9", Target = "Sorcerer"},
    {Level = 2000, ID = "QuestNPC8", Target = "SnowBoss"},
    {Level = 1500, ID = "QuestNPC7", Target = "FrostRogue"},
    {Level = 1000, ID = "QuestNPC6", Target = "DesertBoss"},
    {Level = 750, ID = "QuestNPC5", Target = "DesertBandit"},
    {Level = 500, ID = "QuestNPC4", Target = "MonkeyBoss"},
    {Level = 250, ID = "QuestNPC3", Target = "Monkey"},
    {Level = 100, ID = "QuestNPC2", Target = "ThiefBoss"},
    {Level = 0, ID = "QuestNPC1", Target = "Thief"}
}

-- === CẤU HÌNH ===
local Config = {
    AutoQuest = false,
    AutoAttack = false,
    AutoTeleport = false,
    FarmRange = 1000,
    AttackSpeed = 0.05,
    NoCooldown = true,
    DashNoCD = false,
    InfJump = false,
    CurrentQuestTarget = nil
}

-- === HÀM LẤY NHIỆM VỤ TỐT NHẤT ===
local function getBestQuest()
    local level = player.Data.Level.Value
    for _, q in ipairs(QuestList) do
        if level >= q.Level then
            return q
        end
    end
    return QuestList[#QuestList]
end

-- === CÁC PATCH (GIỮ NGUYÊN TỪ TRƯỚC) ===
local function applyPatches()
    -- Patch Cooldown, Dash, Jump, Combat như các turn trước
    pcall(function()
        local CombatConfig = require(ReplicatedStorage.CombatSystem.CombatConfig)
        CombatConfig.GetHitCooldown = function() return 0 end
        
        local DashModule = require(ReplicatedStorage.DashModule)
        DashModule.Config.DashCooldown = 0
        DashModule.Config.MaxDashesPerSecond = 999
        
        local MultiJump = require(ReplicatedStorage.MultiJumpModule)
        MultiJump.Config.MaxJumps = 9e9
        MultiJump.GetMaxJumps = function() return 9e9 end
    end)
end

-- === GIAO DIỆN UI ===
local Window = Luna:CreateWindow({
    Name = "Sailor Sea | Final Hub",
    Subtitle = "Auto Quest & Farm",
    LoadingEnabled = true
})

local MainTab = Window:CreateTab({
    Name = "Auto Farm",
    Icon = "layers",
    ImageSource = "Material",
    ShowTitle = true
})

MainTab:CreateSection("Leveling")

MainTab:CreateToggle({
    Name = "Auto Quest",
    Description = "Tự động nhận quest & farm quái nhiệm vụ",
    CurrentValue = false,
    Callback = function(Value)
        Config.AutoQuest = Value
        if Value then
            Config.AutoAttack = true
            Config.AutoTeleport = true
        end
    end
})

MainTab:CreateSection("Manual Farm")

MainTab:CreateToggle({
    Name = "Auto Attack Aura",
    CurrentValue = false,
    Callback = function(Value) Config.AutoAttack = Value end
})

MainTab:CreateToggle({
    Name = "Auto Teleport",
    CurrentValue = false,
    Callback = function(Value) Config.AutoTeleport = Value end
})

-- --- EXPLOITS ---
local ExploitTab = Window:CreateTab({ Name = "Exploits", Icon = "bolt", ImageSource = "Material" })
ExploitTab:CreateToggle({ Name = "Inf Jump", Callback = function(v) Config.InfJump = v end })
ExploitTab:CreateToggle({ Name = "Dash No CD", Callback = function(v) Config.DashNoCD = v end })

-- === VÒNG LẶP CHÍNH ===
task.spawn(function()
    while true do
        task.wait(Config.AttackSpeed)
        applyPatches() -- Đảm bảo các cheat luôn bật
        
        local targetNPC = nil
        local currentQuest = getBestQuest()
        
        -- 1. Xử lý Auto Quest
        if Config.AutoQuest then
            -- Thử nhận quest liên tục (Game sẽ tự chặn nếu đã có quest)
            remoteQuest:FireServer(currentQuest.ID)
            Config.CurrentQuestTarget = currentQuest.Target
        else
            Config.CurrentQuestTarget = nil
        end
        
        -- 2. Tìm mục tiêu
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs then
            local closestDist = Config.FarmRange
            for _, npc in ipairs(npcs:GetChildren()) do
                local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("PrimaryPart")
                local hum = npc:FindFirstChild("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    -- Nếu đang auto quest, chỉ tập trung vào quái của quest đó
                    if Config.AutoQuest and npc.Name:find(Config.CurrentQuestTarget) then
                        local d = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d < closestDist then
                            targetNPC = npc
                            closestDist = d
                        end
                    elseif not Config.AutoQuest then
                        -- Farm tự do
                        local d = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d < closestDist then
                            targetNPC = npc
                            closestDist = d
                        end
                    end
                end
            end
        end
        
        -- 3. Thực thi Teleport & Attack
        if targetNPC then
            local myHrp = player.Character.HumanoidRootPart
            local targetRoot = targetNPC:FindFirstChild("HumanoidRootPart") or targetNPC:FindFirstChild("PrimaryPart")
            
            if Config.AutoTeleport then
                myHrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
            end
            if Config.AutoAttack then
                remoteHit:FireServer()
            end
        end
    end
end)

Luna:Notification({ Title = "Success", Content = "Auto Quest System Ready!", Icon = "verified" })
