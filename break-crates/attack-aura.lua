local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình (Settings)
local SETTINGS = {
    Range = 999,
    Cooldown = 0.1,
    AutoEquip = true -- Tự động cầm kiếm mạnh nhất
}

-- Lấy Remote dựa trên data.txt
-- game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Weapons"):WaitForChild("RequestSwing"):FireServer()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Weapons = Remotes:WaitForChild("Weapons")
local RequestSwing = Weapons:WaitForChild("RequestSwing")

-- Lấy dữ liệu vũ khí từ game
local WeaponsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configuration"):WaitForChild("Weapons"))

-- Hàm tìm và trang bị vũ khí mạnh nhất
local function EquipBestWeapon()
    if not SETTINGS.AutoEquip then return end

    local bestDamage = -1
    local bestWeaponName = nil
    local weaponsFolder = LocalPlayer:FindFirstChild("Weapons")

    if weaponsFolder then
        -- Duyệt qua vũ khí người chơi sở hữu
        for _, weaponObj in ipairs(weaponsFolder:GetChildren()) do
            -- Game lưu tên thật trong Attribute "Name" (theo code decompiled) hoặc dùng tên Object
            local weaponName = weaponObj:GetAttribute("Name") or weaponObj.Name
            local stats = WeaponsConfig[weaponName]
            
            if stats and stats.Damage and stats.Damage > bestDamage then
                bestDamage = stats.Damage
                bestWeaponName = weaponName
            end
        end
    end

    if bestWeaponName then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            -- Kiểm tra xem đã cầm chưa
            local currentTool = character:FindFirstChild(bestWeaponName)
            if not currentTool then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local toolToEquip = backpack:FindFirstChild(bestWeaponName)
                    -- Lưu ý: Tên trong Backpack có thể khác tên Config, nhưng thường là giống
                    if toolToEquip then
                        character.Humanoid:EquipTool(toolToEquip)
                    end
                end
            end
        end
    end
end

-- Hàm lấy Plot của người chơi
-- game:GetService("Players").LocalPlayer.Plot -> lấy plot player , trong value
local function GetPlayerPlot()
    local plotValue = LocalPlayer:FindFirstChild("Plot")
    if plotValue and plotValue.Value then
        return plotValue.Value -- Trả về Model Plot trong Workspace
    end
    return nil
end

-- Hàm chạy Attack Aura
local function StartAttackAura()
    print("Attack Aura Started!")
    while true do
        pcall(function()
            EquipBestWeapon() -- Kiểm tra và cầm kiếm mạnh nhất mỗi vòng lặp
            
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            local plot = GetPlayerPlot()
            
            local currentRange = SETTINGS.Range

            if rootPart and plot then
                -- Tìm folder Crates trong Plot
                -- workspace.Plots["2"].Crates
                local cratesFolder = plot:FindFirstChild("Crates")

                if cratesFolder then
                    local shouldAttack = false
                    
                    for _, crate in ipairs(cratesFolder:GetChildren()) do
                        -- Xác định vị trí của Crate
                        local targetPart = nil
                        
                        if crate:IsA("Model") then
                            targetPart = crate.PrimaryPart or crate:FindFirstChildWhichIsA("BasePart")
                        elseif crate:IsA("BasePart") then
                            targetPart = crate
                        end

                        if targetPart then
                            local distance = (rootPart.Position - targetPart.Position).Magnitude
                            if distance <= currentRange then
                                shouldAttack = true
                                -- Có thể thêm code quay mặt về phía crate nếu cần:
                                -- rootPart.CFrame = CFrame.new(rootPart.Position, Vector3.new(targetPart.Position.X, rootPart.Position.Y, targetPart.Position.Z))
                                break -- Chỉ cần tìm thấy 1 cái gần là đánh
                            end
                        end
                    end

                    if shouldAttack then
                        RequestSwing:FireServer()
                    end
                end
            end
        end)
        task.wait(SETTINGS.Cooldown)
    end
end

-- Khởi chạy trong luồng riêng
task.spawn(StartAttackAura)