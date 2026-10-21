-- ============================================================
-- Bee Swarm — Find Free Hive & Claim (Fly + Trial)
-- ============================================================
print("🐝 Find Free Hive - Starting...")

local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- Хук на консоль, чтобы поймать ошибку сервера о занятом улье
local failedClaim = false
local oldPrint = print
local oldWarn = warn

local function checkMessage(...)
    local msg = tostring(...)
    if msg:lower():find("already") or msg:lower():find("claim") or msg:lower():find("занят") then
        failedClaim = true
    end
    oldPrint(...)
end

-- (Если инжектор поддерживает hookfunction / hookmetamethod, лучше захукать уведомления)
-- Но для простоты перехватываем print/warn, если скрипт выводит туда ошибки.
print = checkMessage
warn = checkMessage

-- === Поиск свободного улья ===
local function findFreeHive()
    local hiveDeco = workspace:FindFirstChild("HiveDeco")
    local canvases = hiveDeco and hiveDeco:FindFirstChild("StickerCanvases")
    if not canvases then return nil end

    for i, canvas in ipairs(canvases:GetChildren()) do
        local origin = canvas:FindFirstChild("OriginPart")
        if origin then
            -- Проверяем на всякий случай текстовые маркеры (вдруг в этой версии они есть)
            local isClaimed = false
            for _, child in ipairs(canvas:GetDescendants()) do
                if child:IsA("TextLabel") and (child.TextColor3 == Color3.fromRGB(255,0,0) or child.Text:lower():find("own")) then
                    isClaimed = true
                    break
                end
            end
            
            if not isClaimed then
                return origin, i
            end
        end
    end
    return nil
end

-- === Плавный полёт (через BodyVelocity) ===
local function flyToHive(targetPos)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    -- Ищем пушку, чтобы не тратить BodyVelocity
    local bazooka = nil
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("bazooka") or v.Name:lower():find("cannon") or v.Name:lower():find("pult")) then
            bazooka = v
            break
        end
    end

    if bazooka then
        notify("Flight", "💥 Летим через пушку...")
        hrp.CFrame = bazooka.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.5)
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 180 + Vector3.new(0, 60, 0)
    else
        notify("Flight", "🚀 Летим через BodyVelocity...")
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = (targetPos - hrp.Position).Unit * 180 + Vector3.new(0, 60, 0)
        bv.Parent = hrp

        -- Летим до тех пор, пока не долетим (или пока не пройдет 3 секунды)
        local startTime = tick()
        while tick() - startTime < 3 do
            task.wait(0.1)
            if (hrp.Position - targetPos).Magnitude < 10 then break end
            bv.Velocity = (targetPos - hrp.Position).Unit * 180 + Vector3.new(0, 60, 0)
        end
        bv:Destroy()
    end
end

-- === Main ===
task.spawn(function()
    waitForCharacter()
    
    local events = ReplicatedStorage:FindFirstChild("Events")
    local claimEvent = events and events:FindFirstChild("ClaimHive")
    
    if not claimEvent then
        notify("Error", "❌ ClaimHive не найден!")
        return
    end

    -- Ищем свободный улей
    local targetPos, hiveIndex = findFreeHive()
    
    if targetPos then
        notify("Scan", "🏠 Летим к свободному улью: " .. tostring(hiveIndex))
        flyToHive(targetPos)
        task.wait(1.5) -- Ждем приземления
        
        -- Отправляем клейм
        failedClaim = false
        claimEvent:FireServer(hiveIndex)
        notify("Claim", "🔨 Пытаемся заклеймить улей " .. tostring(hiveIndex))
        
        task.wait(2) -- Ждем ответа от сервера
        
        if failedClaim then
            notify("Claim", "❌ Улей занят, перезапусти скрипт для поиска другого.")
        else
            notify("Claim", "✅ Клейм отправлен (проверь в игре).")
        end
    else
        notify("Scan", "⚠️ Все ульи выглядят занятыми. Летим к 1-му для проверки.")
        -- Если не нашли текстом, пробуем 1-й (вдруг он свободен, а мы не поняли)
        local hiveDeco = workspace:FindFirstChild("HiveDeco")
        local canvases = hiveDeco and hiveDeco:FindFirstChild("StickerCanvases")
        if canvases and canvases:FindFirstChild("StickerCanvas1") then
            flyToHive(canvases.StickerCanvas1.OriginPart.Position)
            task.wait(1.5)
            claimEvent:FireServer(1)
        end
    end
end)

print("🐝 Loaded!")
