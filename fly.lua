-- ============================================================
-- Bee Swarm — Smooth Walk to Hive 1 & Claim
-- ============================================================
print("🐝 Walk & Claim Hive 1 - Starting...")

local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function waitForCharacter()
    if not player.Character then player.CharacterAdded:Wait() end
    local char = player.Character
    char:WaitForChild("HumanoidRootPart", 15)
    char:WaitForChild("Humanoid", 15)
    task.wait(1)
end

-- === Идём к улью ===
local function walkToHive(hiveIndex)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return false end

    local hiveDeco = workspace:FindFirstChild("HiveDeco")
    local canvases = hiveDeco and hiveDeco:FindFirstChild("StickerCanvases")
    local canvas = canvases and canvases:FindFirstChild("StickerCanvas" .. hiveIndex)
    
    if not canvas then 
        notify("Walk", "❌ Улей " .. hiveIndex .. " не найден")
        return false 
    end
    
    local origin = canvas:FindFirstChild("OriginPart")
    if not origin then return false end
    
    local targetPos = origin.Position
    notify("Walk", "🚶 Идём к улью " .. hiveIndex .. "...")
    
    -- Плавная ходьба
    local startTime = tick()
    while tick() - startTime < 10 do -- Максимум 10 секунд идём
        task.wait(0.1)
        
        -- Если умерли, прерываем
        if not hum or hum.Health <= 0 then return false end
        
        -- Обновляем цель (на случай, если улей двигается)
        hum:MoveTo(targetPos)
        
        -- Проверяем, дошли ли (дистанция меньше 5 стадов)
        if (hrp.Position - targetPos).Magnitude < 5 then
            notify("Walk", "✅ Дошли до улья " .. hiveIndex)
            return true
        end
    end
    
    notify("Walk", "⚠️ Не смогли дойти за 10 секунд.")
    return false
end

-- === Main ===
task.spawn(function()
    waitForCharacter()
    
    local targetHive = 1 -- Какой улей берем (1-6)
    
    -- Идем к улью
    local success = walkToHive(targetHive)
    
    if success then
        -- Ждем немного, чтобы прогрузилось
        task.wait(1)
        
        -- Клеймим
        local events = ReplicatedStorage:FindFirstChild("Events")
        local claimEvent = events and events:FindFirstChild("ClaimHive")
        
        if claimEvent then
            notify("Claim", "🔨 Отправляем клейм для улья " .. targetHive)
            claimEvent:FireServer(targetHive)
        else
            notify("Error", "❌ ClaimHive не найден")
        end
    end
end)

print("🐝 Loaded!")
