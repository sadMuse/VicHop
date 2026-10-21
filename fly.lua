local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- защита от двойного запуска
if _G.HiveFlyRunning then
    _G.HiveFlyStop = true
    task.wait(0.3)
end
_G.HiveFlyRunning = true
_G.HiveFlyStop = false

local function notify(t, x)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t, Text = x, Duration = 3})
    end)
end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

-- Центр текстуры (localpatharrow) улья
local function getHivePosition(hive)
    local arrow = hive:FindFirstChild("localpatharrow")
    if arrow then
        if arrow:IsA("Model") then
            local cf = arrow:GetBoundingBox()
            return cf.Position
        elseif arrow:IsA("BasePart") then
            return arrow.Position
        end
    end

    -- запасные варианты
    local spawnPos = hive:FindFirstChild("SpawnPos")
    if spawnPos and spawnPos:IsA("BasePart") then
        return spawnPos.Position
    end
    return hive:GetPivot().Position
end

-- Ближайший свободный улей
local function findNearestFreeHive()
    local hrp = getHRP()
    local honeycombs = workspace:WaitForChild("Honeycombs", 10)
    if not hrp or not honeycombs then return nil end

    local bestHive, bestNum, bestDist = nil, nil, math.huge

    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        local num = tonumber(hive.Name:match("%d+"))
        if owner and owner.Value == nil and num then
            local dist = (getHivePosition(hive) - hrp.Position).Magnitude
            if dist < bestDist then
                bestHive, bestNum, bestDist = hive, num, dist
            end
        end
    end

    return bestHive, bestNum
end

-- Прямой полёт к точке сквозь стены
local function flyTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local char = hrp.Parent

    local maxSpeed = 150   -- studs/сек
    local accel = 0.15
    local dest = targetPos + Vector3.new(0, 3, 0)

    local noclip = RunService.Stepped:Connect(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    local currentSpeed = 0
    local done = false

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if _G.HiveFlyStop or not hrp.Parent then
            done = true
            return
        end

        local diff = dest - hrp.Position
        local dist = diff.Magnitude

        if dist < 1 then
            done = true
            return
        end

        local wanted = math.min(maxSpeed, dist * 5)
        currentSpeed = currentSpeed + (wanted - currentSpeed) * accel

        local step = math.min(currentSpeed * dt, dist)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(hrp.Position + diff.Unit * step)
    end)

    while not done do
        task.wait()
    end

    -- точно ставим в центр
    if hrp.Parent then
        hrp.CFrame = CFrame.new(dest)
    end

    conn:Disconnect()
    noclip:Disconnect()
    hrp.AssemblyLinearVelocity = Vector3.zero
end

task.spawn(function()
    task.wait(2)

    local events = ReplicatedStorage:WaitForChild("Events", 10)
    local claim = events and events:FindFirstChild("ClaimHive")
    if not claim then
        notify("Ошибка", "ClaimHive не найден")
        _G.HiveFlyRunning = false
        return
    end

    local hive, num = findNearestFreeHive()
    if not hive then
        notify("Ошибка", "Свободных ульев нет")
        _G.HiveFlyRunning = false
        return
    end

    notify("Улей", "Лечу к " .. hive.Name)
    flyTo(getHivePosition(hive))

    claim:FireServer(num)

    task.wait(1)
    local owner = hive:FindFirstChild("Owner")
    if owner and owner.Value == player then
        notify("Успех", "Улей " .. hive.Name .. " занят")
    else
        notify("Упс", "Не получилось занять " .. hive.Name)
    end

    _G.HiveFlyRunning = false
end)
