-- ============================================================
-- Bee Swarm — Flight to Free Hive (v2)
-- ============================================================
print("🐝 Flight to Hive v2 - Starting...")

local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- === 1. Улучшенный поиск свободного улья ===
local function findFreeHive()
    -- Пушки и платформы ульев часто лежат в Workspace.Platforms или в корне
    local platforms = workspace:FindFirstChild("Platforms")
    local searchIn = platforms or workspace
    
    for _, obj in ipairs(searchIn:GetDescendants()) do
        -- Ищем модели или части, в имени которых есть "Hive"
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:find("Hive") then
            
            -- Проверяем, занят ли он. Ищем красный текст "Owned" или "Claimed" в потомках.
            local isClaimed = false
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") and (child.TextColor3 == Color3.fromRGB(255, 0, 0) or child.Text:find("Own") or child.Text:find("Claim")) then
                    isClaimed = true
                    break
                end
            end
            
            if not isClaimed then
                local origin = obj:FindFirstChild("OriginPart") or obj.PrimaryPart or (obj:IsA("BasePart") and obj)
                if origin then
                    print("✅ Найден свободный улей:", obj.Name)
                    return origin
                end
            end
        end
    end
    return nil
end

-- === 2. Поиск пушки ===
local function findCannon()
    -- Расширяем поиск: ищем в Platforms, в корне и на 3 уровня вглубь
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:find("Cannon") or v.Name:find("Launcher") or v.Name:find("Pult")) then
            print("💥 Найдена пушка:", v.Name)
            return v
        end
    end
    return nil
end

-- === 3. Полёт ===
local function flyToHive(targetPos)
    local hrp = getHRP()
    if not hrp then return end

    local cannon = findCannon()
    if cannon then
        notify("Flight", "💥 Пушка найдена! Летим...")
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
            -- Подруливаем на ходу
            bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        end
        bv:Destroy()
    end
end

-- === Main ===
task.wait(2)

local freeHive = findFreeHive()
if freeHive then
    notify("Flight", "🏠 Свободный улей найден! Летим...")
    flyToHive(freeHive.Position)
    task.wait(1)
    
    -- Пытаемся заклеймить (на всякий случай, так как улей был свободен)
    local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if events and events:FindFirstChild("ClaimHive") then
        events.ClaimHive:FireServer(tonumber(freeHive.Parent.Name:match("%d+")) or 1)
    end
else
    -- Если не нашли улей, ищем хоть что-то похожее на платформу
    notify("Flight", "⚠️ Улей не найден. Летим к центру...")
    flyToHive(Vector3.new(0, 50, 0))
    warn("Свободные ульи не найдены.")
end
