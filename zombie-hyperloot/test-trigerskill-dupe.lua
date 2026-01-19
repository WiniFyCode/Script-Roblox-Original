--[[
    Test Script - TrigerSkill Dupe
    Kiểm tra xem hookmetamethod có hoạt động không
]]

print("=== TrigerSkill Dupe Test Script ===")

-- Helper function để lấy executor functions
local function getExecutorFunction(name)
    -- Try from getfenv()
    local env = getfenv()
    if env and env[name] then
        print("✓ Found " .. name .. " from getfenv()")
        return env[name]
    end
    -- Try from rawget(getfenv())
    local func = rawget(env or {}, name)
    if func then 
        print("✓ Found " .. name .. " from rawget(getfenv())")
        return func 
    end
    -- Try from global (some executors expose directly)
    if _G and _G[name] then
        print("✓ Found " .. name .. " from _G")
        return _G[name]
    end
    print("✗ " .. name .. " not found")
    return nil
end

-- Check các function cần thiết
print("\n[1] Checking executor functions...")
local hookmetamethod = getExecutorFunction("hookmetamethod")
local getnamecallmethod = getExecutorFunction("getnamecallmethod")
local checkcaller = getExecutorFunction("checkcaller")

print("\n[2] Function availability:")
print("  hookmetamethod: " .. tostring(hookmetamethod ~= nil))
print("  getnamecallmethod: " .. tostring(getnamecallmethod ~= nil))
print("  checkcaller: " .. tostring(checkcaller ~= nil))

if not hookmetamethod or not getnamecallmethod or not checkcaller then
    warn("❌ Missing required functions! Cannot test TrigerSkill dupe.")
    return
end

print("\n[3] All functions available! Setting up hook...")

-- Setup hook
local oldNamecall = nil
local hookSuccess = false
local testCount = 0

local success, err = pcall(function()
    oldNamecall = hookmetamethod(game, "__namecall", function(remoteInstance, ...)
        local callMethod = getnamecallmethod()
        local remoteArguments = {...}
        
        -- Check if this is TrigerSkill FireServer call
        if callMethod == "FireServer"
            and not checkcaller()
            and typeof(remoteInstance) == "Instance"
            and remoteInstance.Name == "TrigerSkill" then
            
            local firstArg = remoteArguments[1]
            local secondArg = remoteArguments[2]
            
            -- Test với GunFire
            if firstArg == "GunFire" and secondArg == "Atk" then
                testCount = testCount + 1
                print("  [TEST] TrigerSkill GunFire detected! Count: " .. testCount)
                
                -- Dupe 3 lần để test
                for i = 1, 3 do
                    oldNamecall(remoteInstance, table.unpack(remoteArguments))
                end
                print("  [TEST] Duplicated 3 times!")
                return -- Không gọi original để tránh duplicate
            end
            
            -- Test với GunReload
            if firstArg == "GunReload" then
                print("  [TEST] TrigerSkill GunReload detected!")
                -- Modify argument 3 to 999
                remoteArguments[3] = 999
                return oldNamecall(remoteInstance, table.unpack(remoteArguments))
            end
        end
        
        -- Return original call for other cases
        return oldNamecall(remoteInstance, ...)
    end)
    
    hookSuccess = true
end)

if not success then
    warn("❌ Failed to setup hookmetamethod: " .. tostring(err))
    return
end

if not hookSuccess then
    warn("❌ Hook setup failed!")
    return
end

print("\n[4] ✓ Hook setup successful!")
print("\n[5] Test instructions:")
print("  - Try shooting (GunFire)")
print("  - Try reloading (GunReload)")
print("  - Check console for test messages")
print("\n[6] Monitoring... (Press End to stop)")

-- Cleanup function
local inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.End then
        print("\n[7] Cleaning up...")
        if oldNamecall then
            -- Restore original (cần unhook, nhưng hookmetamethod thường không có unhook)
            -- Chỉ cần disconnect connection
        end
        inputConnection:Disconnect()
        print("✓ Test script stopped")
    end
end)

print("\n=== Test script running. Try shooting/reloading to test! ===")
