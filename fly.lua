-- ============================================================
-- Bee Swarm (Retro) — Flight to Dandelion Hives
-- ============================================================
print("🐝 Flight to Dandelion Hives - Starting...")

local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- === Поиск пушки ===
local function findCannon()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:find("Cannon") or v.Name:find("Launcher") or v.Name:find("Pult")) then
            return v
        end
    end
    return nil
end

-- === Полёт ===
local function flyToPosition(targetPos)
    local hrp = getHRP()
    if not hrp then return end

    local cannon = findCannon()
    if cannon then
        notify("Flight", "💥 Летим через пушку...")
        hrp.CFrame = cannon.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.5)
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 150 + Vector3.new(0, 50, 0) 
    else
        notify("Flight", "🚀 Пушки нет. Используем BodyVelocity...")
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        bv.Parent = hrp
        
        local startTime = tick()
        while tick() - startTime < 3 do
            task.wait(0.1)
            if (hrp.Position - targetPos).Magnitude < 15 then break end
            bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        end
        bv:Destroy()
    end
end

-- === Main ===
task.wait(2)

-- 1. Ищем поле одуванчиков в Workspace
local dandelionField = nil
for _, obj in ipairs(workspace:GetDescendants()) do
    if (obj:IsA("Model") or obj:IsA("BasePart")) and (obj.Name:lower():find("dandelion") or obj.Name:lower():find("white field")) then
        dandelionField = obj
        print("🌼 Найдено поле одуванчиков:", obj.Name)
        break
    end
end

local targetPos = nil

if dandelionField then
    -- 2. Если нашли поле, ищем ближайший к нему улей
    local hiveDeco = workspace:FindFirstChild("HiveDeco")
    local canvases = hiveDeco and hiveDeco:FindFirstChild("StickerCanvases")
    
    if canvases then
        local closestDist = math.huge
        local bestCanvas = nil
        
        local fieldPos = dandelionField:IsA("BasePart") and dandelionField.Position or dandelionField:GetModelCFrame().Position
        
        for _, canvas in ipairs(canvases:GetChildren()) do
            local origin = canvas:FindFirstChild("OriginPart")
            if origin then
                local dist = (origin.Position - fieldPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    bestCanvas = origin
                end
            end
        end
        
        if bestCanvas then
            targetPos = bestCanvas.Position
            notify("Flight", "🏠 Улей возле одуванчиков найден!")
            print("Координаты улья:", targetPos)
        end
    end
end

-- 3. Фолбэк: если поле не найдено, используем хардкод координат ульев в Retro Swarm
if not targetPos then
    notify("Flight", "⚠️ Поле не найдено, летим к известным координатам Retro Swarm...")
    -- FILL: Если координаты не совпадут, поправь Vector3 тут
    targetPos = Vector3.new(40, 10, -140) -- примерно там, где ульи у одуванчиков
end

-- 4. Летим
flyToPosition(targetPos)
task.wait(1)

-- 5. Пытаемся заклеймить первый попавшийся
local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
if events and events:FindFirstChild("ClaimHive") then
    events.ClaimHive:FireServer(1) 
end
