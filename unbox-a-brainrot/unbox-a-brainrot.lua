--[[
    Unbox-a-Brainrot - dùng chung UI & modules của Universal Script
]]

----------------------------------------------------------
-- 🔹 Hàm load module từ GitHub
local function loadModule(moduleName)
    local githubPath = "https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/" .. moduleName .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(githubPath))()
    end)
    if success then
        return result
    else
        warn("Failed to load module: " .. moduleName .. " - " .. tostring(result))
        return nil
    end
end

----------------------------------------------------------
-- 🔹 Load Config + UI
local Config = loadModule("config")
local UI = loadModule("ui")

if not Config or not UI then
    return
end

UI.init(Config)
UI.loadLibraries()
UI.createWindow()

-- Tự tạo Tabs
UI.Tabs = {
    Main = UI.Window:AddTab("Main", "user"),
    Farm = UI.Window:AddTab("Farm", "sun"),
    Visuals = UI.Window:AddTab("Visuals", "eye"),
    Teleport = UI.Window:AddTab("Teleport", "map-pin"),
    Server = UI.Window:AddTab("Server", "server"),
    Misc = UI.Window:AddTab("Misc", "settings"),
    ["UI Settings"] = UI.Window:AddTab("UI Settings", "settings"),
}

UI.createUISettingsTab()

UI.Library:Notify({
    Title = "Unbox-a-Brainrot",
    Description = "Loaded with Universal UI (Farm tab, no Combat)",
    Time = 5,
})

----------------------------------------------------------
-- 🔹 Load các tab muốn dùng từ Universal
local Movement = loadModule("movement")
if Movement then
    Movement.init(Config, UI)
    Movement.createTab()
end

local Visuals = loadModule("visuals")
if Visuals then
    Visuals.init(Config, UI)
    Visuals.createTab()
end

local Teleport = loadModule("teleport")
if Teleport then
    Teleport.init(Config, UI)
    Teleport.createTab()
end

local Server = loadModule("server")
if Server then
    Server.init(Config, UI)
    Server.createTab()
end

local Misc = loadModule("misc")
if Misc then
    Misc.init(Config, UI)
    Misc.createTab()
end

----------------------------------------------------------
-- 🔹 Unbox Features
----------------------------------------------------------

local farmGroup = UI.Tabs.Farm:AddLeftGroupbox("Auto Farm", "sparkles")

farmGroup:AddToggle("UnboxAutoHit", {
    Text = "Auto Hit Crate",
    Default = true,
    Tooltip = "Tự động đánh tất cả crate trong plot của bạn",
})

farmGroup:AddSlider("UnboxHitInterval", {
    Text = "Hit Interval (s)",
    Default = 0.1,
    Min = 0.05,
    Max = 10,
    Rounding = 2,
})


farmGroup:AddDivider()

farmGroup:AddToggle("UnboxAutoCollect", {
    Text = "Auto Collect Cash",
    Default = true,
    Tooltip = "Tự động thu thập tiền từ các máy Collector",
})

farmGroup:AddSlider("UnboxCollectInterval", {
    Text = "Collect Interval (s)",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
})

----------------------------------------------------------
-- 🔹 Logic Helpers
----------------------------------------------------------

local function getPlayerPlotName()
    local plot = game:GetService("Players").LocalPlayer:FindFirstChild("Plot")
    if plot then
        return tostring(plot.Value)
    end
    return nil
end

local plotName = getPlayerPlotName()
UI.Library:Notify({
    Title = "Unbox-a-Brainrot",
    Description = "Bạn đang ở Slot: " .. (plotName or "Chưa có"),
    Time = 5,
})

----------------------------------------------------------
-- 🔹 Main Loops
----------------------------------------------------------

local autoHitRunning = true
task.spawn(function()
    while autoHitRunning do
        local interval = (UI.Options.UnboxHitInterval and UI.Options.UnboxHitInterval.Value) or 0.1
        task.wait(interval)

        if not UI.Toggles.UnboxAutoHit or not UI.Toggles.UnboxAutoHit.Value then
            continue
        end

        local plotName = getPlayerPlotName()
        if not plotName then continue end

        local bases = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bases")
        local base = bases and bases:FindFirstChild(plotName)
        
        if base and base:FindFirstChild("Crate") then
            for _, crate in ipairs(base.Crate:GetChildren()) do
                local damage = 999
                local insideCrate = crate:FindFirstChild("InsideCrate")

                local hitRemote = insideCrate and insideCrate:FindFirstChild("Hit")
                
                if hitRemote then
                    pcall(function()
                        hitRemote:FireServer(damage)
                    end)
                end
            end
        end
    end
end)

local autoCollectRunning = true
task.spawn(function()
    while autoCollectRunning do
        local interval = (UI.Options.UnboxCollectInterval and UI.Options.UnboxCollectInterval.Value) or 0.5
        task.wait(interval)

        if not UI.Toggles.UnboxAutoCollect or not UI.Toggles.UnboxAutoCollect.Value then
            continue
        end

        local plotName = getPlayerPlotName()
        if not plotName then continue end

        local bases = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bases")
        local base = bases and bases:FindFirstChild(plotName)
        local collectors = base and base:FindFirstChild("Collectors")

        if collectors then
            Config.getCharacter()
            local rootPart = Config.rootPart
            if not rootPart then continue end

            for _, collector in ipairs(collectors:GetChildren()) do
                local touchPart = collector:FindFirstChild("touch")
                if touchPart and (touchPart:FindFirstChildOfClass("TouchTransmitter") or touchPart:FindFirstChild("TouchInterest")) then
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(rootPart, touchPart, 0)
                            firetouchinterest(rootPart, touchPart, 1)
                        end
                    end)
                end
            end
        end
    end
end)

----------------------------------------------------------
-- 🔹 Cleanup
----------------------------------------------------------

if UI and UI.Library then
    UI.Library:OnUnload(function()
        autoHitRunning = false
        autoCollectRunning = false
        
        if Movement and Movement.cleanup then Movement.cleanup() end
        if Visuals and Visuals.cleanup then Visuals.cleanup() end
        if Teleport and Teleport.cleanup then Teleport.cleanup() end
        if Server and Server.cleanup then Server.cleanup() end
        if Misc and Misc.cleanup then Misc.cleanup() end
    end)
end

print("[Unbox-a-Brainrot] Loaded with Universal UI")
