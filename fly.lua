-- ============================================================
-- Bee Swarm — Flight to Free Hive
-- ============================================================
print("🐝 Flight to Hive - Starting...")

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

-- === 1. Поиск свободного улья ===
local function findFreeHive()
    local hives = workspace:FindFirstChild("HiveDeco") and workspace.HiveDeco:FindFirstChild("Hives")
    if not hives then
        warn("HiveDeco.Hives not found")
        return nil
    end
    
    for _, hive in ipairs(hives:GetChildren()) do
        local isClaimed = false
        -- Проверка по тексту (таблички Owned/Claimed)
        for _, child in ipairs(hive:GetDescendants()) do
            if child:IsA("TextLabel") and (child.Text:find("Claimed") or child.Text:find("Owned") or child.Text:find("Захвачен")) then
                isClaimed = true
                break
            end
        end
        
        -- Если не нашли текстом, проверяем по имени/атрибутам (часто бывает, что улей занят, если у него есть какое-то свойство)
        if not isClaimed and hive:GetAttribute("Claimed") == true then
            isClaimed = true
        end

        if not isClaimed then
            local origin = hive:FindFirstChild("OriginPart") or hive.PrimaryPart
            if origin then 
                print("✅ Found free hive:", hive.Name)
                return origin 
            end
        end
    end
    return nil
end

-- === 2. Поиск пушки ===
local function findCannon()
    -- Ищем пушки в Workspace (Cannon, Launcher, Pult)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:find("Cannon") or v.Name:find("Launcher") or v.Name:find("Pult")) then
            print("💥 Found cannon:", v.Name)
            return v
        end
    end
    return nil
end

-- === 3. Полёт к улью ===
local function flyToHive(targetPos)
    local hrp = getHRP()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local cannon = findCannon()
    if cannon then
        notify("Flight", "💥 Cannon found! Launching...")
        hrp.CFrame = cannon.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.5)
        
        -- Импульс от пушки
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 150 + Vector3.new(0, 50, 0) 
    else
        notify("Flight", "⚠️ No cannon. Using BodyVelocity...")
        -- Ручной полёт через BodyVelocity
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        bv.Parent = hrp
        
        -- Ждем, пока не прилетим (или пока не пройдет время)
        local startPos = hrp.Position
        local startTime = tick()
        while tick() - startTime < 3 do
            task.wait(0.1)
            -- Если мы пролетели мимо, корректируем курс
            if (hrp.Position - targetPos).Magnitude < 10 then break end
            bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        end
        
        bv:Destroy()
    end
end

-- === Main ===
task.wait(2) -- ждем загрузки

local freeHive = findFreeHive()
if freeHive then
    notify("Flight", "🏠 Free hive found! Flying...")
    flyToHive(freeHive.Position)
    task.wait(1)
    
    -- По прилету пытаемся заклеймить (на всякий случай)
    local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if events and events:FindFirstChild("ClaimHive") then
        events.ClaimHive:FireServer(tonumber(freeHive.Name:match("%d+")) or 1)
    end
else
    notify("Flight", "❌ No free hives found.")
    warn("No free hives found.")
end
